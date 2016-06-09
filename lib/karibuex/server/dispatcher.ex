# The dispatcher is the module witch handles every request
# We should have as many dispatchers they are workers to avoid bottleneck (try without and then with and compare benchmarks)
# The dispatcher is responsible of parsing msg, error reporting, logging, calling workers with user defined fonctions, replying to sending sockets
# The dispatcher must be the most async possible


defmodule Karibuex.Server.Dispatcher do
  use GenServer
  use Towel
  require Logger

  # API

  def start_link(config) do
    Logger.info("Start worker")
    GenServer.start_link(__MODULE__, config)
  end


  def execute(pid, payload) do
    GenServer.call(pid, {:execute, payload}, :infinity)
  end

  # Execute user request
  def dispatch(pid, request) do
    # Please handle bad parsing for the next release

    case parse_request(request) do
      {:ok, res} -> process_rpc(pid, res)
      {:error, err} -> "unknow format for karibu"
    end

  end

  def call(pid, {socket, sid}, request) do
    encoded_response = dispatch(pid, request)
    :ezmq.send(socket, {sid, ["", encoded_response]})
  end


  # Callbacks

  # def init(config) do
  #   {:ok, config}
  # end

  def handle_call({:execute, payload}, _from, config) do
    res = exec(payload, config)
    # async log
    {:reply, res, config}
  end


  defp exec(payload, config) do
    check_result = check_user_modules(payload, config)
    case check_result do
      {:ok, mod, func} ->
        task = Task.async(fn ->
          try do
            :timer.tc(mod, func, payload[:params])
          catch
            :throw,reason -> # Catch programmer throw and raise a custom error with the right stack
              stack = System.stacktrace()
              {:error, Karibu.NocatchError, reason, stack}
            :error, reason -> reason
          end
        end)
        case Task.yield(task, config.timeout) do
          {:ok, result} -> {:ok, result}
            case result do
              {:error, error_mod, reason, stack} ->
                reraise(error_mod, [message: reason], stack)
                _ -> {:ok, result}
            end
          nil           -> # task has timed out
            Task.shutdown(task,:brutal_kill)
            handle_errors(:timeout, payload)
        end
      _ -> handle_errors(check_result, payload)
    end
  end

  defp check_user_modules(payload, config) do
    valid_payload = {:ok, {config, payload}} |> validate_resource |> validate_method |> validate_args
    case valid_payload do
      {:error, err} -> err
      _ -> valid_payload
    end
  end

  defp validate_resource(value) do
    bind(value, fn({c, p}) ->
      is_valid = with mod_name <- p[:resource],
                      true     <- mod_name =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/,
                      mod      <- Module.concat(Elixir, mod_name),
                      true     <- Code.ensure_loaded?(mod),
                      do: Enum.member?(c.modules, mod)

      if is_valid == true do
        {:ok, {Module.concat(Elixir, p[:resource]), p}}
      else
        {:error, :resource_not_found}
      end
    end)
  end

  defp validate_method(value) do
    bind(value, fn({mod, p}) ->
      is_valid = with mod <- mod,
                      funcs <- apply(mod, :__info__, [:functions]) |> Dict.keys |> Enum.map(&(to_string(&1))),
                      do: Enum.member?(funcs, p[:method])
      if is_valid == true do
        func = String.to_atom(p[:method])
        {:ok, {mod, func, p}}
      else
        {:error, :method_not_found}
      end
    end)
  end

  defp validate_args(value) do
    bind(value, fn({mod, func, p}) ->
      is_valid = with mod <- mod,
                      functions <- apply(mod, :__info__, [:functions]),
                      do: functions[func] == length(p[:params])

      if is_valid == true do
        {:ok, mod, func}
      else
        {:error, :argument_error}
      end
    end)
  end

  defp parse_request(request) do
    Karibuex.Msg.Request.decode(request)
  end

  def log_error(time, error, payload) do
    params = List.first(payload[:params])
    {err, err_msg} = error
    message = "resource=#{payload[:resource]} method=#{payload[:method]} params=#{inspect params} status=9700 duration=#{time} #{err_msg}"
    Logger.error(message)
  end

  def log(time, payload) do
    params = List.first(payload[:params])
    message = "resource=#{payload[:resource]} method=#{payload[:method]} params=#{inspect params} status=9800 duration=#{time}"
    # IO.puts message
    # IO.puts "resource=#{payload[:resource]} method=#{payload[:method]} params=#{payload[:params]}"
    Logger.info(message)
  end

  defp handle_errors(error, payload) do
    case error do
      :resource_not_found -> {error, "Cannot find resource #{payload[:resource]}"}
      :method_not_found   -> {error, "Cannot find method #{payload[:method]} in resource #{payload[:resource]}"}
      :argument_error     -> {error, "Wrong number of arguments(#{payload[:params] |> length}) for method #{payload[:method]}"}
      :timeout            -> {:timeout_error, "Request took too long to execute"}
      :bad_format         -> {:packet_error, "Cannot process request. Bad packet"}
      _                   -> {:server_error, "Server error occured"}
    end
  end

  defp prepare_response(result, payload) do
    case result do
      {:ok, result} ->
        Karibuex.Msg.Response.encode(payload[:id], nil, result)
      {error, msg}  ->
        klass = error |> to_string |> Mix.Utils.camelize
        Karibuex.Msg.Response.encode(payload[:id], %{klass: klass, msg: msg}, nil)
        # response
    end
  end

  defp process_rpc(pid, payload) do
    try do
      res = execute(pid, payload)
      case res do
        {:ok, {time, result}} ->
          log(time/1000, payload)
          prepare_response({:ok,result}, payload)
        _ ->
          log_error(0, res, payload)
          prepare_response(res, payload)
      end
    rescue
       exception ->
         stack = System.stacktrace
        #  Rollbax.report(exception, stack, payload)
         res = {:server_error, "An error has occured please try again"}
         log_error(0, res, payload)
         prepare_response(res, payload)
    end
  end

end

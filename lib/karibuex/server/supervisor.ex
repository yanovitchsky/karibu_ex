defmodule Karibuex.Server.Supervisor do
  use Supervisor

  def start_link do
    # get configure port
    port = Application.get_env(:karibuex, :port)
    modules = Application.get_env(:karibuex, :modules)
    mod_str = module_str(modules)
    timeout = Application.get_env(:karibuex, :timeout)
    workers = Application.get_env(:karibuex, :workers)
    configuration = %Karibuex.Config{modules: modules, modules_str: mod_str, timeout: timeout, port: port, workers: workers}
    Supervisor.start_link(__MODULE__, configuration)
    # Logger.
  end

  def init(config) do
    worker_pool_options = [
      name: {:local, :worker_pool},
      worker_module: Karibuex.Server.Dispatcher,
      size: config.workers,
      max_overflow: round(config.workers/2)
    ]

    IO.inspect worker_pool_options
    children = [
      :poolboy.child_spec(:worker_pool, worker_pool_options, config),
      worker(Karibuex.Server.Listener, [config])
    ]

    supervise(children, strategy: :one_for_one)
  end

  defp module_str(modules) do
    modules |> Enum.map(fn(mod) ->
      to_string(mod) |> String.replace("Elixir.", "")
    end)
  end
end

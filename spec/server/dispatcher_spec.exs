defmodule Karibuex.Server.DispatcherSpec do
  use ESpec
  import ExUnit.Case
  import Logger

  def module_str(modules) do
    modules |> Enum.map(fn(mod) ->
      to_string(mod) |> String.replace("Elixir.", "")
    end)
  end

  describe "dispatch" do
    before do
      modules = Application.get_env(:karibuex, :modules)
      mod_str = module_str(modules)
      timeout = Application.get_env(:karibuex, :timeout)
      error_log = Application.get_env(:karibuex, :error_log)
      config = %Karibuex.Config{modules: modules, modules_str: mod_str, timeout: timeout}
      {:ok, pid} = Karibuex.Server.Dispatcher.start_link(config)
      {:shared, dispatcher: pid}
    end

    context "When there is an error" do
      context "with module is not exposed" do
        it "returns error resource_not_found" do
          request = %{type: 0, id: "1", resource: "Plop", method: "stats", params: [23]}
          expect Karibuex.Server.Dispatcher.execute(shared.dispatcher, request)
          |> to(eq {:resource_not_found, "Cannot find resource Plop"})
        end
      end

      context "When method does not exists" do
        it "returns error method_not_found" do
          request = %{type: 0, id: "1", resource: "UserModuleTest", method: "stats", params: [23]}
          expect Karibuex.Server.Dispatcher.execute(shared.dispatcher, request)
          |> to(eq {:method_not_found, "Cannot find method stats in resource UserModuleTest"})
        end

      end

      context "When bad arguments" do
        it "returns argument_error" do
          request = %{type: 0, id: "1", resource: "UserModuleTest", method: "echo", params: []}
          expect Karibuex.Server.Dispatcher.execute(shared.dispatcher, request)
          |> to(eq {:argument_error, "Wrong number of arguments(0) for method echo"})
        end
      end

      context "When timeout expires" do
        it "returns timeout_error" do
          request = %{type: 0, id: "1", resource: "UserModuleTest", method: "slow", params: []}
          expect Karibuex.Server.Dispatcher.execute(shared.dispatcher, request)
          |> to(eq {:timeout_error, "Request took too long to execute"})
        end
      end

      xcontext "when user code crashes" do
        it "creates an error packet" do
          {:ok, request} = Msgpax.pack([0, "1", "UserModuleTest", "slow", []])
          res = Karibuex.Server.Dispatcher.dispatch(shared.dispatcher, request)
          {:ok, msg} = Msgpax.unpack(res)
          expect msg |> to(eq [1, "1", %{"klass" => "TimeoutError", "msg" => "Request took too long to execute"}, nil])
        end
      end

      it "logs errors" do
        System.cmd "rm", ["log/test.error.log"]
        {:ok, request} = Msgpax.pack([0, "1", "UserModuleTest", "slow", []])
        res = Karibuex.Server.Dispatcher.dispatch(shared.dispatcher, request)
        path = "#{System.cwd}/log/#{Mix.env}.error.log"
        expect File.exists?(path) |> to(be_true)
        file = File.read!(path) |> String.strip
        expect file |> to(match ~r/^\[error] \[(\w{4}-\w{2}-\w{2} [\w:.]+)] resource=UserModuleTest method=slow params= status=9700 duration=[0-9.]+ Request took too long to execute/)
      end

      context "When user throw" do
        it "raises an error" do
          request = %{type: 0, id: "1", resource: "UserModuleTest", method: "throws", params: []}
          expect fn -> Karibuex.Server.Dispatcher.execute(shared.dispatcher, request) end
          |> to(raise_exception Karibu.NocatchError)
        end
      end

      context "when exception is raised" do
        it "sends error to rollbar" do
          allow Rollbax |> to(accept :report, fn(ex, st, par) -> IO.puts "rollbar called" end)
          {:ok, request} = Msgpax.pack([0, "1", "UserModuleTest", "raises", []])
          Karibuex.Server.Dispatcher.dispatch(shared.dispatcher, request)
          expect Rollbax |> to(accept :report)
        end

        it "logs to error" do
          System.cmd "rm", ["log/test.error.log"]
          {:ok, request} = Msgpax.pack([0, "1", "UserModuleTest", "raises", []])
          # res = Karibuex.Server.Dispatcher.dispatch(shared.dispatcher, request)
          # IO.inspect res
          # expect(fn -> Karibu.Server.Dispatcher.dispatch(shared.dispatcher, request) end)
          # |> to(raise_exception Elixir.RuntimeError)
          # path = "#{System.cwd}/log/#{Mix.env}.error.log"
          # file = File.read!(path) |> String.strip
          # expect length(file) |> to_not(eq 0)
        end
      end
    end

    context "Where there are no errors" do
      it "executes user module" do
        {:ok, request} = Msgpax.pack([0, "1", "UserModuleTest", "echo", ["plop"]])
        res = Msgpax.unpack! Karibuex.Server.Dispatcher.dispatch(shared.dispatcher, request)

        expect Enum.at(res, 3) |> to(eq "plop")
      end

      it "logs" do
        System.cmd "rm", ["log/test.log"]
        {:ok, request} = Msgpax.pack([0, "1", "UserModuleTest", "echo", ["plop"]])
        res = Karibuex.Server.Dispatcher.dispatch(shared.dispatcher, request)
        path = "#{System.cwd}/log/#{Mix.env}.log"
        IO.inspect File.exists?(path)
        expect File.exists?(path) |> to(be_true)
        file = File.read!(path) |> String.strip
        expect file |> to(match ~r/^\[info] \[(\w{4}-\w{2}-\w{2} [\w:.]+)] resource=UserModuleTest method=echo params=plop status=9800 duration=1[0-9.]+/)
      end
    end
  end
end

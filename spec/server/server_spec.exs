# Test if server launches with correct options
defmodule Karibuex.ServerSpec do
  use ESpec


  describe "listen" do
    before do
      {:ok, pid} = Task.Supervisor.start_link()
      Task.Supervisor.async(pid, fn ->
        Karibuex.Server.Supervisor.start_link
      end)
      {:shared, server_pid: pid}
    end

    it "receive incoming connection" do
      {:ok, client_socket} = :ezmq.start([{:type, :req}, {:active, :false}])
      :ezmq.connect(client_socket, :tcp, {127, 0, 0, 1}, 5000, [{:timeout, 1000}])
      res = :ezmq.send(client_socket, ["Plop"])
      :ezmq.close(client_socket)
      expect res |> to_not(eq {:error, :no_connection})
      end


    xit "restarts when crashed" do

    end
  end

end

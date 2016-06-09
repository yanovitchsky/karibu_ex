defmodule Karibuex.Server.Listener do
  require Logger

  def start_link(config) do
    Task.start_link(fn ->  start(config) end)
  end


  defp loop(socket, config) do
    {:ok, {id, [_idn, request]}} = :ezmq.recv(socket)
    :poolboy.transaction(:worker_pool, fn(worker) ->
      {:ok, worker} = Karibuex.Server.Dispatcher.start_link(config)
        Karibuex.Server.Dispatcher.call(worker, {socket, id}, request)
    end)
    loop(socket, config)
  end

  defp start(config) do
    {:ok, socket} = :ezmq.start([{:type, :router}])
    :ezmq.bind(socket, :tcp, config.port, [])
    Logger.info("Karibu server listening on port #{config.port}")
    loop(socket, config)
  end
end

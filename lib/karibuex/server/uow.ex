defmodule Karibuex.Server.Uow do

  def start_link(port) do
    {:ok, socket} = :ezmq.start([{:type, :router}])
    :ezmq.bind(socket, :tcp, port, [])
    loop(socket)
  end

  defp loop(socket) do
    {:ok, {id, [_idn, _message]}} = :ezmq.recv(socket)
    # :ezmq.send(socket, {id, ["","Hello world"]})
    loop(socket)
  end
end

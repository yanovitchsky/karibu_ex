defmodule Karibuex.Server.Supervisor do
  use Supervisor

  def start_link do
    # get configure port
    port = Application.get_env(:karibuex, :port)
    Supervisor.start_link(__MODULE__, port)
  end

  def init(port) do
    children = [
      worker(Karibuex.Server.Uow, [port])
    ]

    supervise(children, strategy: :one_for_one)
  end
end

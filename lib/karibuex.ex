defmodule Karibuex do
  use Application

  def start(_type, _args) do
    Karibuex.Server.Supervisor.start_link()
  end
end

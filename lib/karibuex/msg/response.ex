defmodule Karibuex.Msg.Response do
  def encode(id, error, result) do
    Msgpax.pack!([1, id, error, result])
  end
end

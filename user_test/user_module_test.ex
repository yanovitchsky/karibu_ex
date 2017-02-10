defmodule UserModuleTest do
  def echo(str) do
    # :timer.sleep(100)
    # str
    "I have received #{str}"
  end

  def sort(list) do
    Enum.sort(list, &(&1 > &2))
  end

  def slow do
    :timer.sleep(10000)
    :ok
  end

  def lol do
    :ok
  end

  def throws do
    throw "bad error"
  end

  def raises do
    raise "plop"
  end

  defp private do
    :ok
  end
end

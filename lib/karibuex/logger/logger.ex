defmodule Karibuex.Logger.Formatter do
  def format_error(params, error) do
    new_params = params
    {err, err_msg} = error
    new_error =   err_msg
    [new_params, new_error]
  end

  def format(params) do
    params
  end
end

defmodule Karibuex.Msg.Request do

  # MessagePack request from client
  # Composed of:
  #   Id => Arbitraty 10 hexa number representing the id of the request
  #   Resource => Resource to fetch from the server (Module or Class)
  #   Method_to_call => Method or Function to be called on the Module or Class
  #   Params => Parameters to pass to the function or method
  #   Meta => User defined metadatas (can be ignored by the server)


  def decode(packet) do
    case res = Msgpax.unpack(packet) do
      {:ok, request} ->
        check_packet(request)
      _ -> res
    end
  end

  defp check_packet(request) do
    case request do
      [type, id, resource, method, params] ->
         array = [
          check_type(type, :integer) && type == 0,
          check_type(id, :string),
          check_type(resource, :string),
          check_type(method, :string),
          check_type(params, :list)#,
          # check_type(metas, :list)
        ]
        # IO.puts array
        the_check = array |> Enum.member?(false)
        if the_check == true do
          {:error, :bad_format}
        else
          result = %{
            :type     => type,
            :id       => id,
            :resource => resource,
            :method   => method,
            :params   => params#,
            # :metas    => metas
          }
          {:ok, result}
        end

      _ -> {:error, :bad_format}
    end
  end

  defp check_type(data, type) do
    case type do
      :string -> is_binary(data)
      :list  -> is_list(data)
      :integer -> is_integer(data)
    end
  end
end

# defimpl Msgpax.Packer, for: DateTime do
#   def transform(datetime) do
#     time = datetime |> DateTime.to_unix |> Integer.to_string
#     Msgpax.Ext.new(0xF, time)
#     |> Msgpax.Packer.transform()
#   end
# end

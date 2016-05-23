defmodule Karibuex.Msg.ResponseSpec do
  use ESpec

  describe "encode" do
    it "encodes with correct id" do
      res = 22
      packed = Karibuex.Msg.Response.encode(3, nil, res)
      {:ok, unpacked} = Msgpax.unpack(packed)
      expect unpacked |> List.first |> to(eq 1)
    end
  end
end

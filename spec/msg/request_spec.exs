defmodule Karibuex.Msg.RequestSpec do
  use ESpec

  describe "decode" do
    context "correct packet" do
      let :request do
        {:ok, packet} = Msgpax.pack([0, "1", "Call", "stats", [23]])
        {:ok, res} = Karibuex.Msg.Request.decode(packet)
        res
      end

      it "has type" do
        expect request[:type] |> to(eq 0)
      end

      it "has id" do
        expect request[:id] |> to(eq "1")
      end

      it "has resource" do
        expect request[:resource] |> to(eq "Call")
      end

      it "has method" do
        expect request[:method] |> to(eq "stats")
      end

      it "has parameters" do
        expect request[:params] |> to(eq [23])
      end
    end

    context "malformed packet" do

      it "return error with bad type" do
        {:ok, packet} = Msgpax.pack([1, "1", "Call", "stats", []])
        expect Karibuex.Msg.Request.decode(packet) |> to(eq {:error, :bad_format})
      end

      it "return error with bad id" do
        {:ok, packet} = Msgpax.pack([0, [3], "Call", "stats", []])
        expect Karibuex.Msg.Request.decode(packet) |> to(eq {:error, :bad_format})
      end

      it "return error with bad resource" do
        {:ok, packet} = Msgpax.pack([0, "1", 12, "stats", []])
        expect Karibuex.Msg.Request.decode(packet) |> to(eq {:error, :bad_format})
      end

      it "return error with bad method" do
        {:ok, packet} = Msgpax.pack([0, "1", "Call", 2, []])
        expect Karibuex.Msg.Request.decode(packet) |> to(eq {:error, :bad_format})
      end

      it "return error with bad argument" do
        {:ok, packet} = Msgpax.pack([0, "1", "Call", "stats", 12])
        expect Karibuex.Msg.Request.decode(packet) |> to(eq {:error, :bad_format})
      end
    end

    context "packet with file" do
      it "accepts files" do
        file = File.read!("#{System.cwd}/spec/support/random.stuff")
        {:ok, packet} = Msgpax.pack([0, "1", "Uploader", "write", [file]])
        {:ok, data} = Karibuex.Msg.Request.decode packet
        expect data[:params] |> List.first |> to(eq file)
      end
    end
  end
end

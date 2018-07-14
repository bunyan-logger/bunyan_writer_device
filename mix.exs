Code.load_file("shared_build_stuff/mix.exs")
alias Bunyan.Shared.Build

defmodule BunyanWriterDevice.MixProject do
  use Mix.Project

  def project() do
    Build.project(
      :bunyan_writer_device,
      "0.1.0",
      &deps/1,
      "The component that lets the  Bunyan distributed and pluggable logging system write to the console and to files"
    )
  end

  def application(), do: []

  def deps(a) do
    IO.inspect a
    [
      bunyan:  [
        bunyan_shared:    ">= 0.0.0",
        bunyan_formatter: ">= 0.0.0",
      ],
      others:  [],
    ]
  end

end

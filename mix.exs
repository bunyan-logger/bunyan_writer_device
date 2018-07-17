unless function_exported?(Bunyan.Shared.Build, :__info__, 1),
do: Code.require_file("shared_build_stuff/mix.exs")

alias Bunyan.Shared.Build

defmodule BunyanWriterDevice.MixProject do
  use Mix.Project

  def project() do
    Build.project(
      :bunyan_writer_device,
      &deps/1,
      "The component that lets the  Bunyan distributed and pluggable logging system write to the console and to files"
    )
  end

  def application(), do: []

  def deps(_) do
    [
      bunyan:  [
        bunyan_shared:    ">= 0.0.0",
        bunyan_formatter: ">= 0.0.0",
      ],
      others:  [],
    ]
  end

end

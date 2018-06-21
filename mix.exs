defmodule Bunyan.Writer.Device.MixProject do
  use Mix.Project

  def project do
    [
      app: :bunyan_writer_device,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: { Bunyan.Writer.Device.Application, [] }
    ]
  end

  defp deps do
    [
      { :bunyan_shared, path: "../bunyan-shared" }
    ]
  end
end

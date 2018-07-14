defmodule Bunyan.Writer.Device.Application do

  use Application

  def start(_type, _args) do
    children = [
      { Bunyan.Writer.Device, [] },
    ]

    opts = [strategy: :one_for_one, name: Bunyan.Writer.Device.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

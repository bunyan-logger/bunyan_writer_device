defmodule Bunyan.Writer.Device.Server do

  use GenServer

  alias Bunyan.Writer.Device.{ Impl, State }

   @doc false
   #TODO: add name to all configs
   def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: options.name)
  end

  @doc false
  def init(options) do
    { :ok, options }
  end

  @doc false
  def handle_cast({ :log_message, msg }, options) do
    Impl.write_to_device(options, msg)
    { :noreply, options }
  end

  def handle_cast(x, options) do
    raise inspect handle_cast: { x, options }
  end

  @doc false
  def handle_call({ :set_log_device, device }, _, options) do
    flush_pending()
    options = Impl.set_log_device(options, device)
    { :reply, :ok, options }
  end

  @doc false
  def handle_call({ :update_configuration, new_config }, _, config) do
    flush_pending()
    new_config = State.from(new_config, config)
    { :reply, :ok,  new_config }
  end

  @doc false
  def handle_call({ :bounce_log_file }, _, config ) do
    { :reply, :ok, Impl.bounce_log_file(config) }
  end

  def terminate(_, options) do
    IO.inspect "TERMINATE #{inspect options}"
    Impl.close_log_device(options)
    :ignored_return_value
  end


  defp flush_pending() do
    # IO.inspect queue_length: Process.info(self(), :message_queue_len)
  end

end

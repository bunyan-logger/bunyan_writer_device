defmodule Bunyan.Writer.Device do

  @moduledoc """
  Write log messages to an IO device. We operate as a separate process
  to allow the rest to continue asynchronously.

  By default, we log to `:user`, but this can be changed both in the
  static configuration (by setting `device:` to an atom that names an IO device,
  or to a string that will be the name of a file), or by updating the
  configuration at runtime (using `update_configuraation/2) or
  `set_log_device/2`.

  ### Formatting Log Messages

  Log messages are formatted under the contol of two format strings. Each string
  specifies the static test of the output along with fild values to be
  substituted in.

  These formats are defined in the static configuration (using
  `main_format_string:` and `additional_format_string:`), and can we updated at
  runtime using `update_configuration/2).

  The fields that can be substituted into the messages are:

  * `$date`     - date the log message was sent (yy-mm-dd)
  * `$time`     - time the log message was sent (hh:mm:ss.mmm)
  * `$datetime` - "$date $time"
  * `$message`  - whole log message
  * `$msg_first_line` - just the first line of the message
  * `$msg_rest` - lines 2... of the message
  * `$level`    - the log level
  * `$node`     - the node that prints the message
  * `$pid`      - the pid that generated the messae
  * `$extra`    - any term. maps and keyword lists are formatted nicely

  The formatter attempts to lay things out nicely. Part of this process is to
  treat the scond and subsequenct lines of any log message differently. When
  writing the first line, Bunyan tries to precompute how many character
  positions are taken up by the information bfore the log message itself
  (typically a timestamp, log level, and so on). It then indents subsequent
  lines so they line up with the message.

  The default formats are:

  ~~~ elixir
  main_format_string:       "$time [$level] $message_first_line",
  additional_format_string: "$message_rest\n$extra",
  ~~~

  So, given

  ~~~ elixir
  Bunyan.info "now is the time\nto write some code", %{ name: "charles weller", country: "USA" }
  ~~~

  will be formatted as

  ~~~
  19:15:30.033 [I] now is the time
                   to write some code
                   :country => "USA"
                   :name    => "charles weller"
  ~~~

  ### Colors

  The formatter can add ANSI color codes to various fields: the three message
  types, $extra, and $level. Seperate colors can be assigned depending on the
  message level to the level and message fields.

  The colors can set set both statically and at runtime.

  Colors are by default enabled when writing to :user, :standard_error, and
  :standard_output. They are disabled when writing to a file. You can override
  this with the `use_ansi_color?` option.


  ### Logging to a File

  When logging to a file, if writer receives the operating signal SIGURS1, it
  will close and then reopen the log file. This allows utilities such as
  logrotate to name the logfile, then signal us, so that the older messages will
  be in the renamed file, and we'll write to the originally named file. To
  facilite this, the writer will write its operating system pid to a file
  specified by the `pid_file:` option.


  """


  @type name :: atom()   | pid()
  @type t    :: binary() | name()

  @server __MODULE__.Server

  def child_spec(config) do
    Supervisor.child_spec({ @server, config }, [])
  end

  @doc """
  Update the configuration parameters associated with this device. Some
  configuration changes (such as compile-time log level) will have no effect.

  The first parameter is the name associated with this device.
  """

  @spec update_configuration(name :: atom(), new_config :: keyword()) :: any()

  def update_configuration(name \\ @server, new_config) do
    GenServer.call(name, { :update_configuration, new_config })
  end

  @doc """
  Change the device associated with this instance of the device writer. You can
  pass either the name of an IO handler process (typically `:user`,
  `:standard_output`, or `standard_error`), the PID of an IO device (often the
  value returned by `File.open`), or a string containing a file name.


  If the new device is given as a string, it is opened (in append mode).
  Otherwise it is assumed to be an atom naming an IO handler (such as
  `:standard_input` or `:user`.)

  Assuming the new device can be opened, we close the old one (but only is we'd
  previously opened it) and then replace it with the new one.

  You probably want to pass any file names using absolute paths.

  ~~~ elixir
  Bunyan.Writer.Device.set_log_device(:my_logger, :standard_error)
  Bunyan.Writer.Device.set_log_device(:app_errors, "/myapp/log/error_log")
  ~~~

  ### Notes

  * If the output is to a named file, then this process will look for
    SIGHUP signals. When recieved, the log file will be closed and
    reopened. This is meant to facilitate interoperation with tools such
    as logrotate.

  * If you have just one Device writer and don't give it a name, it will be
    called Bunyan.Writer.Device. With more than one Device writer, you must give
    each unique names in the config using the `name:` option.

  """

  @spec set_log_device(name :: name, device :: t) :: any()

  def set_log_device(name \\ @server, device) do
    GenServer.call(name, { :set_log_device, device })
  end

  @doc """
  Close and then reopen the log file. This allows utilities such as logrotate to
  rename old files without us appending to them.

  This is passed the name or pid of the device to bounce.
  """
  @spec bounce_log_file(name :: name) :: :ok

  def bounce_log_file(name \\ @server) when is_atom(name) or is_pid(name) do
    GenServer.call(name, { :bounce_log_file })
  end

end

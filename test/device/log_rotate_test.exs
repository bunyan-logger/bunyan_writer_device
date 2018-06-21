defmodule Test.Bunyan.Writers.Device.LogRotate do

  # Despite the name, all this really tests is that the log file is
  # reopened when we send a hup to the device writer

  use ExUnit.Case

  alias Bunyan.Writer.Device

  @logfile     "./test_log_file"
  @old_logfile "./test_log_file_old"
  @pidfile    "./test_pid"

  @name  :wombat_the_device_writer

  @config  [
          name:               @name,
          device:             @logfile,
          pid_file_name:      @pidfile,

          runtime_log_level:  :debug,

          main_format_string:       "$time [$level] $message_first_line",
          additional_format_string: "$message_rest\n$extra",

          use_ansi_color?:   false
        ]


  defp write_log_message(text) do
    import TestHelpers
    :ok = GenServer.cast(@name, { :log_message, msg(text) })
  end

  test "writes a pid file when the output device is a file" do
    File.rm(@pidfile)

    Bunyan.Writer.Device.Server.start_link(@config)

    assert { :ok, pid } = File.read(@pidfile)
    assert String.to_integer(pid) == :os.getpid |> List.to_integer()

    GenServer.stop(@name)
  end

  test "can write messages to a file" do
    File.rm(@logfile)

    Bunyan.Writer.Device.Server.start_link(@config)
    write_log_message "one two"
    write_log_message "three four"
    GenServer.stop(@name)

    content = File.read!(@logfile)

    assert content =~ ~r/one two\n.*three four/
  end


  test "reopens log file when hup sent" do
    File.rm(@logfile)
    File.rm(@old_logfile)
    File.rm(@pidfile)

    Bunyan.Writer.Device.Server.start_link(@config)

    write_log_message "one"

    File.rename(@logfile, @old_logfile)

    # we're still logging to the original file, but under its new name
    write_log_message "two"

    give_casts_a_chance_to_flush()

    # Now reopen
    System.cmd  "kill", [ "-usr1", File.read!(@pidfile) ]

    # give the kill time to get back to us...
    :timer.sleep(100)

    write_log_message "three"

    # switch the log files back to close the disk log
    give_casts_a_chance_to_flush()

    Device.set_log_device(@name, :user)

    f1 = File.read!(@old_logfile)
    f2 = File.read!(@logfile)

    GenServer.stop(@name)

    assert f1 =~ ~r/one.*\n.*two/
    assert !(f1 =~ ~r/three/)
    assert f2 =~ ~r/three/

  end

  defp give_casts_a_chance_to_flush() do
    :timer.sleep(10)
  end
end

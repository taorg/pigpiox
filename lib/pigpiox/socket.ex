defmodule Pigpiox.Socket do
  require Logger
  use GenServer

  @moduledoc """
  Pigpiox.Socket provides an interface to send commands to a running pigpio daemon started by `Pigpiox.Port`
  """
  @block_map_command %{
    i2c_read_block_data: 65,
    i2c_block_process_call: 70,
    i2c_read_i2c_block_data: 67,
    i2c_read_device: 56
  }

  @block_command @block_map_command |> Map.to_list() |> Keyword.values()
  @typep state :: :gen_tcp.socket()

  @typedoc """
  The response of a command sent to pigpiod. The interpretation of `result` will vary based on the command run.
  """
  @type command_result :: {:ok, result :: non_neg_integer} | {:error, reason :: atom}

  @doc """
  Opens a TCP socket to a running pigpiod.
  """
  @spec start_link(list()) :: {:ok, pid} | {:error, term}
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, [], options)
  end

  @spec init(term) :: {:ok, :gen_tcp.socket()} | {:stop, atom}
  def init(_) do
    case attempt_connection(3) do
      {:ok, socket} -> {:ok, socket}
      {:error, reason} -> {:stop, reason}
    end
  end

  @doc """
  Runs a command via pigpiod.
  """
  @spec command(
          type :: atom,
          param_one :: integer,
          param_two :: integer,
          extents :: list(integer)
        ) :: command_result
  def command(cmd, p1 \\ 0, p2 \\ 0, extents \\ [])

  def command(cmd, p1, p2, extents) do
    cmd_code = Pigpiox.Command.code(cmd)
    GenServer.call(__MODULE__, {:do_command, cmd_code, p1, p2, extents})
  end

  @spec handle_call(
          {:do_command, integer, integer, integer, list(integer)},
          sender :: term,
          state
        ) :: {:reply, command_result, state}
  def handle_call({:do_command, command, p1, p2, extents}, _, socket) do
    base_msg =
      <<command::native-unsigned-integer-size(32), p1::native-unsigned-integer-size(32),
        p2::native-unsigned-integer-size(32),
        length(extents) * 4::native-unsigned-integer-size(32)>>

    msg =
      Enum.reduce(extents, base_msg, fn extent, accum ->
        accum <> <<extent::native-unsigned-integer-size(32)>>
      end)

    :ok = :gen_tcp.send(socket, msg)

    result = handle_command(command, socket)

    response = handle_result(result)

    {:reply, response, socket}
  end

  defp handle_command(command, socket) when command in @block_command do
    data_socket =
      with {:ok, data_socket} <- :gen_tcp.recv(socket, 0),
           do: data_socket

    Logger.debug("Command:#{inspect(command)}--bitSize:#{inspect(bit_size(data_socket))}")

    result =
      if !is_atom(data_socket) && bit_size(data_socket) > 128 do
        <<_original_command::size(96), length::size(32), result::binary>> = data_socket

        ulength =
          length
          |> :binary.encode_unsigned()
          |> :binary.bin_to_list()
          |> Enum.reverse()
          |> :binary.list_to_bin()
          |> :binary.decode_unsigned()

        Logger.debug("length:#{inspect(ulength)}<-->result:#{inspect(result)}")
        result
      end

    result
  end

  defp handle_command(command, socket) do
    Logger.debug("Command:#{inspect(command)}")

    {
      :ok,
      <<_original_command::size(96), result::native-signed-integer-size(32)>>
    } = :gen_tcp.recv(socket, 0)

    result
  end

  @spec handle_result(result :: integer) :: command_result
  defp handle_result(result) when result >= 0 do
    {:ok, result}
  end

  defp handle_result(result) do
    {:error, Pigpiox.Command.error_reason(result)}
  end

  @spec attempt_connection(retries :: non_neg_integer) ::
          {:ok, :gen_tcp.socket()} | {:error, :could_not_connect}
  defp attempt_connection(num_retries) when num_retries > 0 do
    _ = Logger.debug("Pigpiox.Socket: connecting to pigpiod")
    opts = [:binary, active: false]

    case :gen_tcp.connect('localhost', 8888, opts, 1000) do
      {:ok, socket} ->
        {:ok, socket}

      {:error, _} ->
        Process.sleep(2000)
        attempt_connection(num_retries - 1)
    end
  end

  defp attempt_connection(_retries) do
    {:error, :could_not_connect}
  end
end

defmodule Pigpiox.I2C do
  @moduledoc """
    I2C elixir wrapper to pigpio API
  Implement I2C pigpiod interface.
  """
  @type i2c_bus :: 0 | 1
  @type i2c_address :: 0..127

  @doc """
  Returns a handle (>=0) for the device at the I2C bus address.
    i2c_bus:= >=0.
    i2c_address:= 0-0x7F.
    i2c_flags:= 0, no flags are currently defined.
  Normally you would only use the [*i2c_**] functions if
  you are or will be connecting to the Pi over a network.  If
  you will always run on the local Pi use the standard SMBus
  module instead.
  Physically buses 0 and 1 are available on the Pi.  Higher
  numbered buses will be available if a kernel supported bus
  multiplexor is being used.
  For the SMBus commands the low level transactions are shown
  at the end of the function description.  The following
  abbreviations are used:
  S     (1 bit) : Start bit
  P     (1 bit) : Stop bit
  Rd/Wr (1 bit) : Read/Write bit. Rd equals 1, Wr equals 0.
  A, NA (1 bit) : Accept and not accept bit.
  Addr  (7 bits): I2C 7 bit address.
  reg   (8 bits): Command byte, which often selects a register.
  Data  (8 bits): A data byte.
  Count (8 bits): A byte defining the length of a block operation.
  []: Data sent by the device.
  h = open(1, 0x53) # open device at address 0x53 on bus 1

  i2c_flags: 0
  No I2C flags are currently defined.
  ## extension ##
  [I, i2c_flags]
  >>> import struct
  >>> struct.pack("I",0)
  '\x00\x00\x00\x00'
  """
  @spec open(i2c_bus, i2c_address) :: {:ok, non_neg_integer} | {:error, atom}
  def open(bus, address) when bus in [0, 1] do
    with {:ok, handle} <- Pigpiox.Socket.command(:i2c_open, bus, address, [0]),
         do: {:ok, handle}
  end

  @doc """
  Closes the I2C device associated with handle.
  handle:= >=0 (as returned by a prior call to [*i2c_open*]).
  i2c_close(h)
  """
  @spec close(non_neg_integer) :: {:error, atom()} | :ok
  def close(handle) do
    with {:ok, _} <- Pigpiox.Socket.command(:i2c_close, handle),
         do: :ok
  end

  @doc """
      Sends a single bit to the device associated with handle.
      handle:= >=0 (as returned by a prior call to [*i2c_open*]).
      bit:= 0 or 1, the value to write.

      SMBus 2.0 5.5.1 - Quick command.

      S Addr bit [A] P
      write_quick(0, 1) # send 1 to device 0
      write_quick(3, 0) # send 0 to device 3
  """
  def write_quick(handle, bit) when is_integer(handle) and bit in 0..1 do
    with {:ok, _} <- Pigpiox.Socket.command(:i2c_write_quick, handle, bit),
         do: :ok
  end

  @doc """
      Sends a single byte to the device associated with handle.
      handle:= >=0 (as returned by a prior call to [*i2c_open*]).
      byte_val:= 0-255, the value to write.

      SMBus 2.0 5.5.2 - Send byte.

      S Addr Wr [A] byte_val [A] P
      write_byte(1, 17)   # send byte   17 to device 1
      write_byte(2, 0x23) # send byte 0x23 to device 2
  """
  @spec write_byte(non_neg_integer, byte()) :: :ok | {:error, atom}
  def write_byte(handle, byte) when is_integer(handle) do
    with {:ok, _} <- Pigpiox.Socket.command(:i2c_write_byte, handle, byte),
         do: :ok
  end

  @doc """
  Reads a single byte from the device associated with handle.
  handle:= >=0 (as returned by a prior call to [*i2c_open*]).
  SMBus 2.0 5.5.3 - Receive byte.
  S Addr Rd [A] [Data] NA P
  b = i2c_read_byte(2) # read a byte from device 2
  """
  @spec read_byte(non_neg_integer) :: {:ok, byte()} | {:error, atom}
  def read_byte(handle) when is_integer(handle) do
    with {:ok, byte} <- Pigpiox.Socket.command(:i2c_read_byte, handle),
         do: {:ok, byte}
  end

  @doc """
  Writes a single byte to the specified register of the device
  associated with handle.

  handle:= >=0 (as returned by a prior call to [*i2c_open*]).
  reg:= >=0, the device register.
  byte_val:= 0-255, the value to write.

  SMBus 2.0 5.5.4 - Write byte.
  S Addr Wr [A] reg [A] byte_val [A] P
  # send byte 0xC5 to reg 2 of device 1
  write_byte_data(1, 2, 0xC5)
  # send byte 9 to reg 4 of device 2
  write_byte_data(2, 4, 9)
  """
  @spec write_byte_data(non_neg_integer, non_neg_integer, byte()) :: :ok | {:error, atom}
  def write_byte_data(handle, reg, byte_val) when is_integer(handle) and byte_val in 0..255 do
    with {:ok, _} <- Pigpiox.Socket.command(:i2c_write_byte_data, handle, reg, [byte_val]),
         do: :ok
  end

  @doc """
  Writes a single 16 bit word to the specified register of the
  device associated with handle.
    handle:= >=0 (as returned by a prior call to [*i2c_open*]).
       reg:= >=0, the device register.
  word_val:= 0-65535, the value to write.

  SMBus 2.0 5.5.4 - Write word.
  S Addr Wr [A] reg [A] word_val_Low [A] word_val_High [A] P
  # send word 0xA0C5 to reg 5 of device 4
  write_word_data(4, 5, 0xA0C5)
  # send word 2 to reg 2 of device 5
  write_word_data(5, 2, 23)
  """
  @spec write_word_data(non_neg_integer, non_neg_integer, non_neg_integer) :: :ok | {:error, atom}
  def write_word_data(handle, reg, word_val) when is_integer(handle) and word_val in 0..65535 do
    with {:ok, _} <- Pigpiox.Socket.command(:i2c_write_word_data, handle, reg, [word_val]),
         do: :ok
  end

  @doc """
  Reads a single byte from the specified register of the device
  associated with handle.
  handle:= >=0 (as returned by a prior call to [*i2c_open*]).
     reg:= >=0, the device register.
  SMBus 2.0 5.5.5 - Read byte.
  S Addr Wr [A] reg [A] S Addr Rd [A] [Data] NA P
  # read byte from reg 17 of device 2
  b = read_byte_data(2, 17)
  # read byte from reg  1 of device 0
  b = read_byte_data(0, 1)
  """
  @spec read_byte_data(non_neg_integer, non_neg_integer) :: {:ok, byte()} | {:error, atom}
  def read_byte_data(handle, reg) when is_integer(handle) do
    with {:ok, byte} <- Pigpiox.Socket.command(:i2c_read_byte_data, handle, reg),
         do: {:ok, byte}
  end

  @doc """
  Reads a single 16 bit word from the specified register of the
  device associated with handle.
  handle:= >=0 (as returned by a prior call to [*i2c_open*]).
     reg:= >=0, the device register.
  SMBus 2.0 5.5.5 - Read word.
  S Addr Wr [A] reg [A] S Addr Rd [A] [DataLow] A [DataHigh] NA P
  # read word from reg 2 of device 3
  w = read_word_data(3, 2)
  # read word from reg 7 of device 2
  w = read_word_data(2, 7)
  """
  @spec read_word_data(non_neg_integer, non_neg_integer) ::
          {:ok, non_neg_integer} | {:error, atom}
  def read_word_data(handle, reg) when is_integer(handle) do
    with {:ok, word} <- Pigpiox.Socket.command(:i2c_read_word_data, handle, reg),
         do: {:ok, word}
  end

  @doc """
  Writes 16 bits of data to the specified register of the device
  associated with handle and reads 16 bits of data in return.
    handle:= >=0 (as returned by a prior call to [*i2c_open*]).
       reg:= >=0, the device register.
  word_val:= 0-65535, the value to write.
  SMBus 2.0 5.5.6 - Process call.
  S Addr Wr [A] reg [A] word_val_Low [A] word_val_High [A]
     S Addr Rd [A] [DataLow] A [DataHigh] NA P
  r = process_call(h, 4, 0x1231)
  r = process_call(h, 6, 0)
  """
  @spec process_call(non_neg_integer, non_neg_integer, non_neg_integer) ::
          {:ok, non_neg_integer} | {:error, atom}
  def process_call(handle, reg, word_val) when is_integer(handle) and word_val in 0..65535 do
    with {:ok, word} <- Pigpiox.Socket.command(:i2c_process_call, handle, reg),
         do: {:ok, word}
  end

  @doc """
   Writes up to 32 bytes to the specified register of the device
      associated with handle.
      handle:= >=0 (as returned by a prior call to [*i2c_open*]).
         reg:= >=0, the device register.
        data:= the bytes to write.

      SMBus 2.0 5.5.7 - Block write.
      S Addr Wr [A] reg [A] len(data) [A] data0 [A] data1 [A] ... [A]
         datan [A] P

      write_block_data(4, 5, b'hello')
      write_block_data(4, 5, "data bytes")
      write_block_data(5, 0, b'\\x00\\x01\\x22')
      write_block_data(6, 2, [0, 1, 0x22])
  """
  @spec write_block_data(non_neg_integer, non_neg_integer, list(non_neg_integer)) ::
          :ok | {:error, atom}
  def write_block_data(handle, reg, data) when is_integer(handle) and is_list(data) do
    with {:ok, _} <- Pigpiox.Socket.command(:i2c_write_block_data, handle, reg, data),
         do: :ok
  end

  @doc """
  Reads a block of up to 32 bytes from the specified register of
  the device associated with handle.
  handle:= >=0 (as returned by a prior call to [*i2c_open*]).
     reg:= >=0, the device register.
  SMBus 2.0 5.5.7 - Block read.
  S Addr Wr [A] reg [A]
     S Addr Rd [A] [Count] A [Data] A [Data] A ... A [Data] NA P
  The amount of returned data is set by the device.
  The returned value is a tuple of the number of bytes read and a
  bytearray containing the bytes.  If there was an error the
  number of bytes read will be less than zero (and will contain
  the error code).
  (b, d) = read_block_data(h, 10)
  if b >= 0:
     # process data
  else:
     # process read failure

  def _u2i(uint32):
   Converts a 32 bit unsigned number to signed.  If the number
   is negative it indicates an error.  On error a pigpio
   exception will be raised if exceptions is True.
   v = u2i(uint32)
   if v < 0:
      if exceptions:
         raise error(error_text(v))
   return v
  #------------------------------------------------------------
  def _rxbuf(self, count):
  Returns count bytes from the command socket.
    ext = bytearray(self.sl.s.recv(count))
      while len(ext) < count:
         ext.extend(self.sl.s.recv(count - len(ext)))
      return ext
  """
  @spec read_block_data(non_neg_integer, non_neg_integer) ::
          {:ok, non_neg_integer} | {:error, atom}
  def read_block_data(handle, reg) when is_integer(handle) do
    with {:ok, block} <- Pigpiox.Socket.command(:i2c_read_block_data, handle, reg),
         do: {:ok, block}
  end

  @doc """
  Writes data bytes to the specified register of the device
  associated with handle and reads a device specified number
  of bytes of data in return.
  handle:= >=0 (as returned by a prior call to [*i2c_open*]).
     reg:= >=0, the device register.
    data:= the bytes to write.
  The SMBus 2.0 documentation states that a minimum of 1 byte may
  be sent and a minimum of 1 byte may be received.  The total
  number of bytes sent/received must be 32 or less.
  SMBus 2.0 5.5.8 - Block write-block read.
  S Addr Wr [A] reg [A] len(data) [A] data0 [A] ... datan [A]
     S Addr Rd [A] [Count] A [Data] ... A P
  The returned value is a tuple of the number of bytes read and a
  bytearray containing the bytes.  If there was an error the
  number of bytes read will be less than zero (and will contain
  the error code).
  (b, d) = block_process_call(h, 10, b'\\x02\\x05\\x00')
  (b, d) = block_process_call(h, 10, b'abcdr')
  (b, d) = block_process_call(h, 10, "abracad")
  (b, d) = block_process_call(h, 10, [2, 5, 16])
  """
  @spec block_process_call(non_neg_integer, non_neg_integer, list(non_neg_integer)) ::
          {:ok, binary} | {:error, atom}
  def block_process_call(handle, reg, data) when is_integer(handle) and is_list(data) do
    with {:ok, block} <- Pigpiox.Socket.command(:i2c_block_process_call, handle, reg, data),
         do: {:ok, block}
  end

  @doc """
  Reads count bytes from the specified register of the device
  associated with handle .  The count may be 1-32.
  handle:= >=0 (as returned by a prior call to [*i2c_open*]).
     reg:= >=0, the device register.
   count:= >0, the number of bytes to read.

  S Addr Wr [A] reg [A]
     S Addr Rd [A] [Data] A [Data] A ... A [Data] NA P
  The returned value is a tuple of the number of bytes read and a
  bytearray containing the bytes.  If there was an error the
  number of bytes read will be less than zero (and will contain
  the error code).
  (b, d) = read_i2c_block_data(h, 4, 32)
  if b >= 0:
     # process data
  else:
     # process read failure
  """
  @spec read_i2c_block_data(non_neg_integer, non_neg_integer, non_neg_integer) ::
          {:ok, bitstring} | {:error, atom}
  def read_i2c_block_data(handle, reg, count) when is_integer(handle) and count in 1..32 do
    with {:ok, data} <- Pigpiox.Socket.command(:i2c_read_i2c_block_data, handle, reg, [count]),
         do: {:ok, data}
  end

  @doc """
  Writes data bytes to the specified register of the device
  associated with handle .  1-32 bytes may be written.
  handle:= >=0 (as returned by a prior call to [*i2c_open*]).
     reg:= >=0, the device register.
    data:= the bytes to write.
  S Addr Wr [A] reg [A] data0 [A] data1 [A] ... [A] datan [NA] P
  write_i2c_block_data(4, 5, 'hello')
  write_i2c_block_data(4, 5, b'hello')
  write_i2c_block_data(5, 0, b'\\x00\\x01\\x22')
  write_i2c_block_data(6, 2, [0, 1, 0x22])
  """
  @spec write_i2c_block_data(non_neg_integer, non_neg_integer, list(non_neg_integer)) ::
          :ok | {:error, atom}
  def write_i2c_block_data(handle, reg, data) when is_integer(handle) and is_list(data) do
    with {:ok, _} <- Pigpiox.Socket.command(:i2c_write_i2c_block_data, handle, reg, data),
         do: :ok
  end

  @doc """
  Returns count bytes read from the raw device associated
  with handle.
  handle:= >=0 (as returned by a prior call to [*i2c_open*]).
   count:= >0, the number of bytes to read.
  S Addr Rd [A] [Data] A [Data] A ... A [Data] NA P
  The returned value is a tuple of the number of bytes read and a
  bytearray containing the bytes.  If there was an error the
  number of bytes read will be less than zero (and will contain
  the error code).
  (count, data) = read_device(h, 12)
  """
  @spec read_device(non_neg_integer, non_neg_integer) :: {:ok, bitstring} | {:error, atom}
  def read_device(handle, count) when is_integer(handle) and count in 1..32 do
    with {:ok, data} <- Pigpiox.Socket.command(:i2c_read_device, handle, count),
         do: {:ok, data}
  end

  @doc """
      Writes the data bytes to the raw device associated with handle.

      handle:= >=0 (as returned by a prior call to [*i2c_open*]).
        data:= the bytes to write.

      S Addr Wr [A] data0 [A] data1 [A] ... [A] datan [A] P
      write_device(h, b"\\x12\\x34\\xA8")
      write_device(h, b"help")
      write_device(h, 'help')
      write_device(h, [23, 56, 231])
  """

  @spec write_device(non_neg_integer, list(non_neg_integer)) :: :ok | {:error, atom}
  def write_device(handle, data) when is_integer(handle) and is_list(data) do
    with {:ok, _} <- Pigpiox.Socket.command(:i2c_write_device, handle, 0, data),
         do: :ok
  end

  @doc """
  This function executes a sequence of I2C operations.  The
  operations to be performed are specified by the contents of data
  which contains the concatenated command codes and associated data.
  handle:= >=0 (as returned by a prior call to [*i2c_open*]).
    data:= the concatenated I2C commands, see below
  The returned value is a tuple of the number of bytes read and a
  bytearray containing the bytes.  If there was an error the
  number of bytes read will be less than zero (and will contain
  the error code).
  (count, data) = zip(h, [4, 0x53, 7, 1, 0x32, 6, 6, 0])

  The following command codes are supported:
  Name    @ Cmd & Data @ Meaning
  End     @ 0          @ No more commands
  Escape  @ 1          @ Next P is two bytes
  On      @ 2          @ Switch combined flag on
  Off     @ 3          @ Switch combined flag off
  Address @ 4 P        @ Set I2C address to P
  Flags   @ 5 lsb msb  @ Set I2C flags to lsb + (msb << 8)
  Read    @ 6 P        @ Read P bytes of data
  Write   @ 7 P ...    @ Write P bytes of data
  The address, read, and write commands take a parameter P.
  Normally P is one byte (0-255).  If the command is preceded by
  the Escape command then P is two bytes (0-65535, least significant
  byte first).
  The address defaults to that associated with the handle.
  The flags default to 0.  The address and flags maintain their
  previous value until updated.

  Any read I2C data is concatenated in the returned bytearray.

  Set address 0x53, write 0x32, read 6 bytes
  Set address 0x1E, write 0x03, read 6 bytes
  Set address 0x68, write 0x1B, read 8 bytes
  End
  0x04 0x53   0x07 0x01 0x32   0x06 0x06
  0x04 0x1E   0x07 0x01 0x03   0x06 0x06
  0x04 0x68   0x07 0x01 0x1B   0x06 0x08
  0x00
  """
  @spec zip(non_neg_integer, list(non_neg_integer)) :: :ok | {:error, atom}
  def zip(handle, data) when is_integer(handle) and is_list(data) do
    with {:ok, _} <- Pigpiox.Socket.command(:i2c_zip, handle, 0, data),
         do: :ok
  end

  @spec zip_address(1..255) :: [1..255, ...]
  def zip_address(byte) when byte in 1..255 do
    [0x04, byte]
  end

  def zip_write(bytes) when is_list(bytes) do
    l = length(bytes)
    w_list = [l | bytes]
    [0x07 | w_list]
  end

  def zip_read(count) when is_integer(count) do
    [0x06 | count]
  end

  @spec zip_end() :: 0
  def zip_end() do
    [0x00]
  end

  @doc """
    This fucntion is expected to add zip command to generate zip block
    zip_add(zip_address(0x12),zip_write(0x66))
    |>zip_add(zip_read(4))
    |>zip_add(zip_write([0x23,0x45]))
    |>zip_add(zip_end)
  """
  @spec zip_add([any()], [any()]) :: [any()]
  def zip_add(head, tail) when is_list(head) and is_list(tail) do
    List.flatten(head, tail)
  end
end

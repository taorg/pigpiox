defmodule Pigpiox.I2C do
  @moduledoc """
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
    with {:ok, handle} <- Pigpiox.Socket.command(:i2c_open, bus, address, [0, 0]),
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
  def wrire_quick(handle, bit) when is_integer(handle) and bit in [0, 1] do
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
end

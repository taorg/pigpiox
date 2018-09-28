defmodule Pigpiox.I2C do
  @moduledoc """
  Implement I2C pigpiod interface.
  """
  @type bus :: 0 | 1
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

      . .
      S     (1 bit) : Start bit
      P     (1 bit) : Stop bit
      Rd/Wr (1 bit) : Read/Write bit. Rd equals 1, Wr equals 0.
      A, NA (1 bit) : Accept and not accept bit.
      Addr  (7 bits): I2C 7 bit address.
      reg   (8 bits): Command byte, which often selects a register.
      Data  (8 bits): A data byte.
      Count (8 bits): A byte defining the length of a block operation.

      [..]: Data sent by the device.
      . .

      ...
      h = i2c_open(1, 0x53) # open device at address 0x53 on bus 1
      ...
  """
  @spec open(bus, i2c_address) :: {:ok, non_neg_integer} | {:error, atom}
  def open(bus, address) when bus in [0, 1] do
    with {:ok, handle} <- Pigpiox.Socket.command(:i2c_open, bus, address, ["I", 0]),
         do: {:ok, handle}
  end

  @doc """
  Closes the I2C device associated with handle.

  handle:= >=0 (as returned by a prior call to [*i2c_open*]).

  ...
  i2c_close(h)
  ...
  """
  @spec close(any()) :: {:error, atom()} | {:ok, non_neg_integer()}
  def close(handle) do
    with {:ok, result} <- Pigpiox.Socket.command(:i2c_close, handle),
         do: {:ok, result}
  end
end

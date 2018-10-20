defmodule Pigpiox.SPI do
  @moduledoc """
    SPI elixir wrapper to pigpio API
  Implement SPI pigpiod interface.
  """
  require Logger

  @doc """
  Returns a handle for the SPI device on channel.  Data will be
  transferred at baud bits per second.  The flags may be used to
  modify the default behaviour of 4-wire operation, mode 0,
  active low chip select.
  An auxiliary SPI device is available on all models but the
  A and B and may be selected by setting the A bit in the
  flags. The auxiliary device has 3 chip selects and a
  selectable word size in bits.
  spi_channel:= 0-1 (0-2 for the auxiliary SPI device).
         baud:= 32K-125M (values above 30M are unlikely to work).
    spi_flags:= see below.
  Normally you would only use the [*spi_**] functions if
  you are or will be connecting to the Pi over a network.  If
  you will always run on the local Pi use the standard SPI
  module instead.
  spi_flags consists of the least significant 22 bits.
  . .
  21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
   b  b  b  b  b  b  R  T  n  n  n  n  W  A u2 u1 u0 p2 p1 p0  m  m
  . .
  mm defines the SPI mode.
  WARNING: modes 1 and 3 do not appear to work on
  the auxiliary device.
  . .
  Mode POL PHA
   0    0   0
   1    0   1
   2    1   0
   3    1   1
  . .
  px is 0 if CEx is active low (default) and 1 for active high.
  ux is 0 if the CEx GPIO is reserved for SPI (default)
  and 1 otherwise.
  A is 0 for the standard SPI device, 1 for the auxiliary SPI.
  W is 0 if the device is not 3-wire, 1 if the device is 3-wire.
  Standard SPI device only.
  nnnn defines the number of bytes (0-15) to write before
  switching the MOSI line to MISO to read data.  This field
  is ignored if W is not set.  Standard SPI device only.
  T is 1 if the least significant bit is transmitted on MOSI
  first, the default (0) shifts the most significant bit out
  first.  Auxiliary SPI device only.
  R is 1 if the least significant bit is received on MISO
  first, the default (0) receives the most significant bit
  first.  Auxiliary SPI device only.
  bbbbbb defines the word size in bits (0-32).  The default (0)
  sets 8 bits per word.  Auxiliary SPI device only.
  The [*spi_read*], [*spi_write*], and [*spi_xfer*] functions
  transfer data packed into 1, 2, or 4 bytes according to
  the word size in bits.
  For bits 1-8 there will be one byte per character.
  For bits 9-16 there will be two bytes per character.
  For bits 17-32 there will be four bytes per character.
  Multi-byte transfers are made in least significant byte
  first order.
  E.g. to transfer 32 11-bit words data should
  contain 64 bytes.
  E.g. to transfer the 14 bit value 0x1ABC send the
  bytes 0xBC followed by 0x1A.
  The other bits in flags should be set to zero.

  # open SPI device on channel 1 in mode 3 at 50000 bits per second
  h = open(1, 50000, 3)

  """
  def open(spi_channel, baud, spi_flags \\ [0]) when spi_channel in 0..2 do
    with {:ok, handle} <- Pigpiox.Socket.command(:spi_open, spi_channel, baud, spi_flags),
         do: {:ok, handle}
  end

  @doc """
  Closes the SPI device associated with handle.
  handle:= >=0 (as returned by a prior call to [*spi_open*]).
  close(h)
  """
  def close(handle) when handle in 0..9 do
    with {:ok, handle} <- Pigpiox.Socket.command(:spi_close, handle),
         do: {:ok, handle}
  end

end

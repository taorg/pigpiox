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
  def close(handle) when is_integer(handle) do
    with {:ok, _} <- Pigpiox.Socket.command(:spi_close, handle),
         do: :ok
  end

  @doc """
  Reads count bytes from the SPI device associated with handle.
  handle:= >=0 (as returned by a prior call to [*spi_open*]).
  count:= >0, the number of bytes to read.

  The returned value is a tuple of the number of bytes read and a
  bytearray containing the bytes.  If there was an error the
  number of bytes read will be less than zero (and will contain
  the error code).

  (b, d) = read(h, 60) # read 60 bytes from device h
  if b == 60:
     # process read data
  else:
     # error path
  """
  def read(handle, count) when is_integer(handle) do
    with {:ok, data} <- Pigpiox.Socket.command(:spi_read, handle, count),
         do: {:ok, data}
  end

  @doc """
  Writes the data bytes to the SPI device associated with handle,
  returning the data bytes read from the device.
  handle:= >=0 (as returned by a prior call to [*spi_open*]).
    data:= the bytes to write.
  The returned value is a tuple of the number of bytes read and a
  bytearray containing the bytes.  If there was an error the
  number of bytes read will be less than zero (and will contain
  the error code).

  (count, rx_data) = xfer(h, b'\\x01\\x80\\x00')
  (count, rx_data) = xfer(h, [1, 128, 0])
  (count, rx_data) = xfer(h, b"hello")
  (count, rx_data) = xfer(h, "hello")
  """
  def xfer(handle, data) when is_integer(handle) do
    with {:ok, data_rx} <- Pigpiox.Socket.command(:spi_xfer, handle, data),
         do: {:ok, data_rx}
  end

  @doc """
  This function selects a set of GPIO for bit banging SPI at a
  specified baud rate.
      CS := 0-31
      MISO := 0-31
      MOSI := 0-31
      SCLK := 0-31
      baud := 50-250000
  spiFlags := see below
  spiFlags consists of the least significant 22 bits.

  21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
   0  0  0  0  0  0  R  T  0  0  0  0  0  0  0  0  0  0  0  p  m  m

  mm defines the SPI mode, defaults to 0
  Mode CPOL CPHA
   0     0    0
   1     0    1
   2     1    0
   3     1    1

  The following constants may be used to set the mode:
  pigpio.SPI_MODE_0
  pigpio.SPI_MODE_1
  pigpio.SPI_MODE_2
  pigpio.SPI_MODE_3

  Alternatively pigpio.SPI_CPOL and/or pigpio.SPI_CPHA
  may be used.
  p is 0 if CS is active low (default) and 1 for active high.
  pigpio.SPI_CS_HIGH_ACTIVE may be used to set this flag.

  T is 1 if the least significant bit is transmitted on MOSI first,
  the default (0) shifts the most significant bit out first.
  pigpio.SPI_TX_LSBFIRST may be used to set this flag.

  R is 1 if the least significant bit is received on MISO first,
  the default (0) receives the most significant bit first.
  pigpio.SPI_RX_LSBFIRST may be used to set this flag.

  The other bits in spiFlags should be set to zero.

  Returns 0 if OK, otherwise PI_BAD_USER_GPIO, PI_BAD_SPI_BAUD, or
  PI_GPIO_IN_USE.

  If more than one device is connected to the SPI bus (defined by
  SCLK, MOSI, and MISO) each must have its own CS.

  bb_spi_open(10, MISO, MOSI, SCLK, 10000, 0); // device 1
  bb_spi_open(11, MISO, MOSI, SCLK, 20000, 3); // device 2
   I p1 CS
   I p2 0
   I p3 20
   extension
   I MISO
   I MOSI
   I SCLK
   I baud
   I spi_flags
  """
  def bb_spi_open(CS, MISO, MOSI, SCLK, baud \\ 100_000, spi_flags \\ 0) do
    extends = ["IIIII", MISO, MOSI, SCLK, baud, spi_flags]

    with {:ok, cs} <- Pigpiox.Socket.command(:bb_spi_open, CS, 0, 20, extends),
         do: {:ok, cs}
  end

  @doc """
  This function stops bit banging SPI on a set of GPIO
  opened with [*bb_spi_open*].
    CS:= 0-31, the CS GPIO used in a prior call to [*bb_spi_open*]

  Returns 0 if OK, otherwise PI_BAD_USER_GPIO, or PI_NOT_SPI_GPIO.
  bb_spi_close(CS)
  """
  def bb_spi_close(CS) do
    with {:ok, cs} <- Pigpiox.Socket.command(:bb_spi_close, CS, 0, 0),
         do: {:ok, cs}
  end

  @doc """
  This function executes a bit banged SPI transfer.
    CS:= 0-31 (as used in a prior call to [*bb_spi_open*])
  data:= data to be sent
  The returned value is a tuple of the number of bytes read and a
  bytearray containing the bytes.  If there was an error the
  number of bytes read will be less than zero (and will contain
  the error code).
  #!/usr/bin/env python
  import pigpio
  CE0=5
  CE1=6
  MISO=13
  MOSI=19
  SCLK=12
  pi = pigpio.pi()
  if not pi.connected:
   exit()
  pi.bb_spi_open(CE0, MISO, MOSI, SCLK, 10000, 0) # MCP4251 DAC
  pi.bb_spi_open(CE1, MISO, MOSI, SCLK, 20000, 3) # MCP3008 ADC
  for i in range(256):
   count, data = pi.bb_spi_xfer(CE0, [0, i]) # Set DAC value
   if count == 2:
      count, data = pi.bb_spi_xfer(CE0, [12, 0]) # Read back DAC
      if count == 2:
         set_val = data[1]
         count, data = pi.bb_spi_xfer(CE1, [1, 128, 0]) # Read ADC
         if count == 3:
            read_val = ((data[1]&3)<<8) | data[2]
            print("{} {}".format(set_val, read_val))
  pi.bb_spi_close(CE0)
  pi.bb_spi_close(CE1)
  pi.stop()

  I p1 CS
  I p2 0
  I p3 len
  extension
  s len data bytes
  """
  def bb_spi_xfer(cs, data) when cs in 0..31 do
    with {:ok, data_rx} <- Pigpiox.Socket.command(:bb_spi_xfer, cs, data),
         do: {:ok, data_rx}
  end
end

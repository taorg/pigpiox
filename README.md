# Pigpiox

Pigpiox provides really good interfacing to GPIOs, I2C buses and SPI (work in progress) peripheral, it is an Elixir wrapper around **pigpiod** C deamon for any suitable Linux sysyem. For all of pigpio's features, check out its [documentation](http://abyz.co.uk/rpi/pigpio/index.html).

# Requirements

To use Pigpiox, pigpiod must be included in your firmware. Currently, this is included by default on any nerves sysyem at nerves_defconfig file as BR2_PACKAGE_PIGPIO=y :
* [`nerves_system_rpi`](https://github.com/nerves-project/nerves_system_rpi/blob/master/nerves_defconfig)
* [`nerves_system_rpi0`](https://github.com/nerves-project/nerves_system_rpi0/blob/master/nerves_defconfig)
* [`nerves_system_rpi2`](https://github.com/nerves-project/nerves_system_rpi2/blob/master/nerves_defconfig)
* [`nerves_system_rpi3`](https://github.com/nerves-project/nerves_system_rpi3/blob/master/nerves_defconfig)
* [`nerves_system_x86_64`](https://github.com/nerves-project/nerves_system_x86_64/blob/master/nerves_defconfig)
* [`nerves_system_x86_64`](https://github.com/nerves-project/nerves_system_x86_64/blob/master/nerves_defconfig)

Currently only  the base Nerves System configuration for the BeagleBone Black, BeagleBone Green, BeagleBone Green Wireless, and PocketBeagle doesn't have **pigpiod** enabled, because there is none of this architecture
* [`nerves_system_bbb`](https://github.com/nerves-project/nerves_system_bbb/blob/master/nerves_defconfig)

If you'd like to use Pigpiox on one of those systems, customize the nerves system you're interested in, and add `BR2_PACKAGE_PIGPIO=y` to its `nerves_defconfig`.

# Installation

In your firmware's `mix.exs`, add `pigpiox` to your deps for your system target:

```elixir
def deps(target) do
  [ system(target),
    {:pigpiox, "~> 0.3"}
  ]
```

# Usage

Adding pigpiox as a dependency to your system will automatically launch the pigpio daemon and open a socket to communicate with it. To interact with pigpiod, Pigpiox provides various modules exposing different areas of functionality:

## GPIO

### Basic functionality

The `Pigpiox.GPIO` provides basic GPIO functionality. Here's an example of reading and writing a GPIO:

```elixir
gpio = 17

Pigpiox.GPIO.set_mode(gpio, :input)
{:ok, level} = Pigpiox.GPIO.read(gpio)

Pigpiox.GPIO.set_mode(gpio, :output)
Pigpiox.GPIO.write(gpio, 1)
```

### Watching a GPIO

When reading a GPIO, often it's useful to know immediately when its level changes, instead of having to constantly poll it. Here's an example:

```elixir
{:ok, pid} = Pigpiox.GPIO.watch(gpio)
```

After setting up a watch on a GPIO pin, the calling process will receive messages of the format `{:gpio_leveL_change, gpio, level}` as its level change.

## Waveforms

The `Pigpiox.Waveform` module provides functions that allow you to create and send waveforms on the Raspberry Pi. Here's an example of pulsing a GPIO on and off every 500ms:

```elixir
pulses = [
  %Pigpiox.Waveform.Pulse{gpio_on: gpio, delay: 500000},
  %Pigpiox.Waveform.Pulse{gpio_off: gpio, delay: 500000}
]

Pigpiox.Waveform.add_generic(pulses)

{:ok, wave_id} = Pigpiox.Waveform.create()

Pigpiox.GPIO.set_mode(gpio, :output)

Pigpiox.Waveform.repeat(wave_id)
```
## I2C
The Pigpiox.I2C module provides complete SMBus implementation following [python](http://abyz.co.uk/rpi/pigpio/python.html) pigpiod client library
```elixir
{:ok, handle} = I2C.open(1, @pca9685_address)

I2C.write_byte_data(handle, @mode2, @outdrv)
I2C.write_byte_data(handle, @mode1, @allcall)

{:ok, mode1} = I2C.read_byte_data(handle, @mode1)

mode1 = mode1 &&& ~~~@sleep

I2C.write_byte_data(handle, @mode1, mode1)

Process.sleep(10)
```

All documentation available on [hexdocs](https://hexdocs.pm/pigpiox/).

# Contributions

This library is still in a very early stage, and I'd appreciate any and all contributions. In particular, a short-term goal is getting feature parity with the [python](http://abyz.co.uk/rpi/pigpio/python.html) pigpiod client library.

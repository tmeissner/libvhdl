[![](https://img.shields.io/github/actions/workflow/status/tmeissner/libvhdl/Test.yml?style=flat-square&logo=Github%20Actions&logoColor=fff&label=Test)](https://github.com/tmeissner/libvhdl/actions/workflows/Test.yml)

The original repository is now located on my own git-server at [https://git.goodcleanfun.de/tmeissner/libvhdl](https://git.goodcleanfun.de/tmeissner/libvhdl)
It is mirrored to github with every push, so both should be in sync.

# libvhdl
A permissive licensed library of reusable components for VHDL designs and testbenches.

The intention of this library is not to realize the most optimized and highest performing code.
Instead it serves more as an example how to implement various things in VHDL and test them efficiently.

## sim
(Non-)synthesizable components for testbenches

##### AssertP (Deprecated, better use Alerts from OSVVM instead)
Package with various assertion procedures.

* `assert_true(x[, str, level])` checks if boolean x = false
* `assert_false(x[, str, level])` checks if boolean x = false
* `assert_equal(x, y[, str, level])` checks if x = y
* `assert_unequal(x, y[, str, level])` checks if x /= y

All of the assert_* procedures have following optional parameters:

* `str` print string str to console instead implemented one
* `level` severity level (note, warning, error, failure)

##### SimP
Package with various components general useful for simulation

* `wait_cycles(x, n)` waits for n rising edges on std_logic signal x
* `spi_master()` configurable master for SPI protocol, supports all cpol/cpha modes
* `spi_slave()` configurable slave for SPI protocol, supports all cpol/cpha modes

##### QueueP
Generic package with various implementations of queue types:

* `t_simple_queue` simple array based FIFO queue
* `t_list_queue` linked list FIFO queue using access types

##### DictP
Generic package with implementation of dictionary (aka associative array) type:

* `t_dict` linked list dictionary using access types

## syn
Synthesizable components for implementing in FPGA

##### SpiMasterE
Configurable SPI master with support modes 0-3 and simple VAI local backend.

##### SpiSlaveE
Configurable SPI slave with support modes 0-3 and simple VAI local backend.

##### UartTx
Configurable UART transmitter

##### UartRx
Configurable UART receiver

##### WishBoneMasterE
Simple WishBone bus master with support of classic single write & read

##### WishBoneSlaveE
Simple WishBone bus slave with support of classic single write & read and register backend


## test
Unit tests for each component

##### QueueT
Unit tests for components of QueueP package

##### SimT
Unit tests for components of SimP package

##### SpiT
Unit tests for SpiMasterE and SpiSlaveE components

##### UartT
Unit test for UartTx and UartRx components

##### WishBoneT
Unit tests for WishBoneMasterE and WishBoneSlaveE components


## formal
Formal verification for selected components


## common
Common utilities

##### UtilsP
Common functions useful for simulation/synthesis

* `and_reduce(x)` returns and of all items in x, collapsed to one std_logic/boolean
* `or_reduce(x)` returns or of all items in x, collapsed to one std_logic/boolean
* `xor_reduce(x)` returns xor of items in x, collapsed to one std_logic
* `even_parity(x)` returns even parity of x
* `odd_parity(x)` returns odd parity of x
* `count_ones(x)` returns number of '1' in x
* `one_hot(x)` returns true if x is one-hot coded, false otherwise
* `is_unknown(x)` returns true if x contains 'U' bit, false otherwise
* `uint_to_slv(x, l)` returns std_logic_vector (unsigned) with length l converted from x (natural)
* `slv_to_uint(x)` returns natural converted from x (std_logic_vector) (unsigned)
* `uint_bitsize(x)` returns number of bits needed for given x (natural)


## Dependencies
To run the tests, you have to install GHDL. You can get it from
[https://github.com/tgingold/ghdl/](https://github.com/tgingold/ghdl/). Your GHDL version should not be too old, because libvhdl needs VHDL-2008 support. So, it's best to get the latest stable release or build from latest sources.

libvhdl uses the OSVVM library to generate random data for the unit tests. It is shipped with libvhdl as git submodule. You have to use the `--recursive` option when clone
the libvhdl Repository to get it: `git clone --recursive https://git.goodcleanfun.de/tmeissner/libvhdl`

Another useful tool is GTKWave, install it if you want to use the waveform files generated by some of the tests.


## Building
Type `make` to do all tests. You should see the successfully running tests like this:

```
$ make
ghdl -a --std=02 ../sim/QueueP.vhd QueueT.vhd
ghdl -e --std=02 QueueT
ghdl -r --std=02 QueueT
QueueT.vhd:52:5:@0ms:(report note): INFO: t_simple_queue test finished successfully
QueueT.vhd:87:5:@0ms:(report note): INFO: t_list_queue test finished successfully
```

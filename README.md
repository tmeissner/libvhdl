# libvhdl
A LGPLv3 licensed library of reusable components for VHDL designs and testbenches


##sim
(Non) synthesible components for testbenches

##### AssertP
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

##### StringP
Package with various functions to convert to string

* `to_char(x)` returns string with binary value of std_logic x
* `to_string(x)` returns string with binary value of std_logic_vector x

##### QueueP
Package with various implementations of queue types:

* `t_simple_queue` simple array based FIFO queue
* `t_list_queue` linked list FIFO queue using access types


## syn
Synthesizable components for implementing in FPGA

##### SpiSlaveE
Configurable SPI slave with support modes 0-3 and simple VAI local backend.
Implementation results:

* 49 logic elements utilization, 397 MHz clock frequency on Microsemi SmartFusion2, speed grade STD
* 24 slices utilization, 649 MHz clock frequency on Xilinx Kintex7, speed grade -3


##test
Unit tests for each component

##### QueueT
Unit tests for components of QueueP package

##### SimT
Unit tests for components of SimP package

##### SpiT
Unit tests for SpiSlave component

##### StringT
Unit tests for components of SimP package


## Dependencies
To run the tests, you have to install GHDL. You can get it from [http://sourceforge.net/projects/ghdl-updates/](http://sourceforge.net/projects/ghdl-updates/).


## Building
Type `make` and you should see the successfully running tests

```
$ make
ghdl -a --std=02 ../sim/QueueP.vhd QueueT.vhd
ghdl -e --std=02 QueueT
ghdl -r --std=02 QueueT
QueueT.vhd:52:5:@0ms:(report note): INFO: t_simple_queue test finished successfully
QueueT.vhd:87:5:@0ms:(report note): INFO: t_list_queue test finished successfully
```
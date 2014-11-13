# libvhdl
A LGPLv3 licensed library of reusable components for VHDL designs and testbenches

##sim
(Non) synthesible components for testbenches

##### QueueP
Package with various implementations of queue types:

* `t_simple_queue` simple array based FIFO queue
* `t_list_queue` linked list FIFO queue using access types


##test
Unit tests for each component

##### QueueT
Units tests for components of QueueP package

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
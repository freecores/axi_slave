#!/bin/bash

../../../robust ../src/base/axi_slave.v -od out -I ../src/gen -list list.txt -listpath -header -gui ${@}

#!/bin/bash

echo Starting RobustVerilog axi slave run
rm -rf out
mkdir out

../../../robust ../src/base/axi_slave.v -od out -I ../src/gen -list filelist.txt -listpath -header

echo Completed RobustVerilog axi slave run - results in run/out/

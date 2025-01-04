#!/bin/csh

set TOP_SIM_DIR = `pwd`
setenv DIR_RTL "${TOP_SIM_DIR}/../rtl"

#param read
set READ_RTL_LIST = "${TOP_SIM_DIR}/../tb/list/list_rtl.txt"

#create a work directory
if (! -d work ) then
  mkdir work/
endif
if (! -d work/rtl_compile) then
  mkdir work/rtl_compile
endif

cd work/rtl_compile/
\rm -rf

xrun \
  -compile \
  -sv \
  -64bit \
  -work worklib \
  -f $READ_RTL_LIST \
  -log_xmvlog rtl_compile.log

cd ../..

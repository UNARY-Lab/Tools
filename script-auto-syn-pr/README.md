# Synthesis and place-and-route

## Requirement
1. Synopsis Design Compiler and Synopsis ICC2
2. Design files in verilog

## How to use
To automate synthesis/place-and-route, simply put your design files as ```./src_v/design/module_top/module_top.v```, and run ```bash ./auto_syn.sh``` and/or ``` bash ./auto_pr.sh```. Note that place-and-route commands have to be go after synthesis commands.

## Where to use
### UW-Madison CAE machines
Rename ```./synopsys_dc.setup_32nm_rvt.uw_madison_cae``` to ```./synopsys_dc.setup_32nm_rvt```, and follow instructions in ***How to use***.


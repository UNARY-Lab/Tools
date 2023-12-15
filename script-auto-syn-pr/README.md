# Synthesis and place-and-route

## Requirement
1. Synopsis Design Compiler and Synopsis ICC2
2. Design files in verilog

## How to use
To automate synthesis/place-and-route, simply put your design files as ```./src_v/design/module_top/module_top.v```, and run ```bash ./auto_syn.sh``` and/or ``` bash ./auto_pr.sh```. Note that place-and-route commands have to be go after synthesis commands.

### Synthesis script for ECE/CS 552 use
Note that you do not need to worry about place and route for 552.

1. Remove the provided example RTL.
   
   ```rm -rf src_v/example```
   
3. Create Level-1 directory.

    ```mkdir src_v/cpu```
  
3. Put your CPU rtl under directory ```src_v/cpu```. You may have extra levels of directories if need be.
4. Run automated synthesis script.

    ```./auto_syn.sh```
  
5. When processing is finished, look for reports under ```32nm_rvt/cpu``` directory.
   
    1. Area results are located in ```<module_name>_area.syn.txt```.
    2. Power results are located in ```<module_name>_power.syn.txt```. Dynamic power is "Switching Power"; Static power is "Leakage Power"+"Internal Power".
    3. Critical path is shown in ```<module_name>_max_delay.syn.txt```.


## Where to use
### UW-Madison CAE machines
Rename ```./synopsys_dc.setup_32nm_rvt.uw_madison_cae``` to ```./synopsys_dc.setup_32nm_rvt```, and follow instructions in ***How to use***.


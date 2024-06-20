# Synthesis and place-and-route

## Requirement
1. Synopsis Design Compiler and Synopsis ICC2
2. Design files in verilog

## Where to use
### UCF CECS machines
Rename ```./synopsys_dc.setup_32nm_rvt.ucf_cecs``` to ```./synopsys_dc.setup```, and follow instructions in ***How to use***.

## How to use
To automate synthesis/place-and-route, simply put your design files as ```./src_v/<design>/<module_top>/<module_top>.v```, and run ```bash ./auto_syn.sh``` and/or ``` bash ./auto_pr.sh```. Note that place-and-route commands have to be go after synthesis commands.

The <module_top>.v requires, if any, a clock signal named ```iClk``` and a reset signal named ```iRstN```.

Be sure to delete any generated directory if you need to re-synthesize modules.

### Synthesis script

1. Be sure your code has the hierarchy
   
   ```./src_v/<design>/<module_top>/<module_top>.v```
   
2. Run automated synthesis script.

    ```bash ./auto_syn.sh```
  
3. When processing is finished, look for reports under ```32nm_rvt/<module_top>``` directory.
   
    1. Area results are located in ```<module_top>_area.syn.txt```.
    2. Power results are located in ```<module_top>_power.syn.txt```. Dynamic power is "Switching Power"; Static power is "Leakage Power"+"Internal Power".
    3. Critical path is shown in ```<module_top>_max_delay.syn.txt```.

## Issues
1. If you are getting library not found error, it's likely the department has updated the edk files. To align with the update, update the ```search_path``` in ```./synopsys_dc.setup_32nm_rvt.ucf_cecs```.

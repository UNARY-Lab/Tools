# Tools
## for ECE/CS 552
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

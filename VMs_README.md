


TODO
=====================

Plans for VMs.py

-> Write core functionality as a Python module/class

-> Reconsider cli-argument passing
   - esxi/user/pass on command-line as an option
     (as well as by envt variable, or stdin)
   - allow to read commands from a file
   - format "-e ESXi -u USER -p PASS" + <CMDS>
     CMDS = "<CMD> [; <CMDS> ]"
     CMD = " OPER <OPER_ARGS> - <VM_LIST>"

-> Add functions
   snapshots: list, create, delete, revert to last, revert to named


TO make into a README
=====================


 python ./myvsphere.py esx 10.3.82.12 list
 python ./myvsphere.py esx 10.3.82.12 resume
 python ./myvsphere.py esx 10.3.82.12 resume HPSA91
 python ./myvsphere.py esx 10.3.82.12 list HPSA91
 python ./myvsphere.py esx 10.3.82.12 list
 python ./myvsphere.py esx 10.3.82.12 list HPSA
 python ./myvsphere.py esx 10.3.82.12 filter state suspend list HPSA
 python ./myvsphere.py esx 10.3.82.12 filter state paused list HPSA
 python ./myvsphere.py esx 10.3.82.12 filter status paused list HPSA
 python ./myvsphere.py esx 10.3.82.12 match status paused list HPSA
 python ./myvsphere.py esx 10.3.82.12 list HPSA
 python ./myvsphere.py esx 10.3.82.12 match status paused list HPSA
 du -s .virtualenvs/*
 python ./myvsphere.py esx 10.3.82.12 match status paused list HPSA
 python ./myvsphere.py esx 10.3.82.12 match status paused list
 python ./myvsphere.py esx 10.3.82.12 match status suspended list
 python ./myvsphere.py esx 10.3.82.12 match status "powered on" list
 #python ./myvsphere.py esx 10.3.82.12 match status "powered on" suspend
 python ./myvsphere.py esx 10.3.82.12 match \!name vcenter list
 python ./myvsphere.py esx 10.3.82.12 match :name vcenter list
 python ./myvsphere.py esx 10.3.82.12 match :name vcenter match :status SUSPENDED list
 python ./myvsphere.py esx 10.3.82.12 match :name vcenter match status SUSPENDED list
 python ./myvsphere.py esx 10.3.82.12 match :name vcenter match status SUSPENDED on
 python ./myvsphere.py esx 10.3.82.12 match :name vcenter match status "powered on" shutdown
 python ./myvsphere.py esx 10.3.82.12 match :name vcenter match status "powered on" off
 python ./myvsphere.py esx 10.3.82.12 match status "powered on" off

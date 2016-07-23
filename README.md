# ioarmada
distributed load test using diskspd on an armada of nano servers

inspired by the VMFleet: https://github.com/Microsoft/diskspd/tree/master/Frameworks/VMFleet

> Note: This is still a very early version and it might change drastically in the future.

# Prerequisites
* provide a control VM with Windows Server 2012R2 and VMware PowerCLI
* Create a new virtual port group that will be used by the worker nodes. Any existing port group, with **no DHCP service** on it, can be re-used.
* Connect control VM to the new port group and set an IP address of `169.254.1.1/16`

# Setup
* Setup the control VM as described above
* Setup one worker node and configure the same password for the local Administrator account as on the control VM
* Create a new folder and share it with the name "ioarmada" - this enables the worker nodes to connect to \\169.254.1.1\ioarmada
* Download this repository and put the diskspd-workernode.ps1 and diskspd-run.ps1 files into the "ioarmada" share 
* Download DiskSpd (http://aka.ms/diskspd) and put the appropriate .exe file for your worker node into the "ioarmada" share
* Open the diskspd-setup.ps1 with PowerShell ISE 
*  copy the diskspd-workernode.ps1 to the root of the C: drive of the worker node
*  create the scheduled task on the worker node
*  reboot the worker node

# Run
At this point, the worker node should start-up, connect to the \\169.254.1.1\ioarmada share and copy the diskspd.exe along with the diskspd-run.ps1 file to it's local disk.
It will then invoke the run script and write the output back to the share. Once finished, the worker node will shut down.

After verifying functionality, use PowerCLI to clone the worker node as many times as you need. Upon startup, each worker will again connect to the share, look for updated versions of the scripts and invoke the latest run script.

# Documentation
Check out the docs over at GitBook: http://ioarmada.tomt.it/

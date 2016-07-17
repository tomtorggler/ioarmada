# ioarmada
distributed load test using diskspd on an armada of nano servers

inspired by the VMFleet: https://github.com/Microsoft/diskspd/tree/master/Frameworks/VMFleet

> Note: This is still a very early version and it might change drastically in the future.

# Prerequisites
* provide a control VM with Windows Server 2012R2 and VMware PowerCLI
* Create a new virtual port group that will be used by the workers. Any existing port group, with **no DHCP service** on it, can be re-used.
* Connect control VM to the new port group and set an IP address of `169.254.1.1/16`

# Setup

# Run

# Documentation
Check out the docs over at GitBook: https://tomtorggler.gitbooks.io/ioarmada-docs/content/
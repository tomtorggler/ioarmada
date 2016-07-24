## Modify Parameters 

$NanoIP = "169.254.60.172"
$NanoPass = "myPassw0rd"

## Run the following commands to setup the Worker Node

# Copy files (requires WMF 5)
$s = New-PSSession -ComputerName $NanoIP
Copy-Item -Path .\diskspd-workernode.ps1 -ToSession $s -Destination c: -Force

# Create Scheduled Task on the Nano Server
$params = @{
    Xml = (Import-Clixml .\diskspd-task.xml);
    CimSession = (New-CimSession -ComputerName $NanoIP);
    TaskName = "diskspd-startup";
    User = "Administrator";
    Password = $NanoPass;
}
Register-ScheduledTask @params

# reboot the Nano Server - note that upon startup, the task will execute the run file!
Invoke-Command -Session $s -ScriptBlock {Restart-Computer -Force}
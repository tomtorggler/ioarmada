$NanoIP = "169.254.60.172"
$NanoPass = "myPassw0rd"

# Copy files (requires WMF 5)
$s = New-PSSession -ComputerName $NanoIP
Copy-Item -Path .\diskspd-workernode.ps1 -ToSession $s -Destination c: -Force

# Create Scheduled Task on the Nano Server
$cs = New-CimSession -ComputerName $s.ComputerName
$x = Import-Clixml .\diskspd-task.xml
Register-ScheduledTask -Xml $x -CimSession $cs -TaskName diskspd-startup -User Administrator -Password $NanoPass

# reboot the Nano Server - note that upon startup, the task will execute the run file!
Invoke-Command -Session $s -ScriptBlock {Restart-Computer}
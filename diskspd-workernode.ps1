$version = "0.5.4"

function Write-DiskSpdLog {
    param(
        [string]$message,
        [switch]$local,
        [switch]$isResult
    )

    if($local) {
        $parentPath = "C:"
    } else {
        $parentPath = "Y:"
    }
    if($isResult) {
        $filename = "result"
    } else {
        $filename = "log"
    }

    $logPath = Join-Path -Path $parentPath -ChildPath "diskspd-$filename-$((Get-NetAdapter)[0].PermanentAddress).txt"
    
    if ($isResult) {
        Add-Content -Path $logPath -Value $message -Force
    } else {
        Add-Content -Path $logPath -Value "$(get-date): $message" -Force
    }
}

function Test-FileVersion {
<#
.Synopsis
   Test file version based on datetime properties and update if necessary.
.DESCRIPTION
   Compare two file's [datetime] properties. Returns $true for less-than or equal age
   and $false if remotePath is newer. The -update switch can be used to update the localPath
   in that case. Does not check file name by default.
#>
    param(
        $LocalPath,
        $RemotePath,
        [ValidateSet('LastWriteTime','LastWriteTimeUtc','CreationTime','CreationTimeUtc')]
        $Property = "LastWriteTimeUtc",
        [switch]$update,
        [switch]$matchFileName
    )

    # check for filename on switch param?
    # return $true/$False disabled for now because update workernode

    try {
        $localProps = Get-Item -Path $localPath -ErrorAction Stop
        $remoteProps = Get-Item -Path $remotePath -ErrorAction Stop
    } catch {
        Write-DiskSpdLog -message "$($_.Exception) --- stop condition! bye!"
        Stop-Computer
    }

    switch ($localProps.$Property)
    {
        {$remoteProps.$Property -le $_} {
            Write-DiskSpdLog "testing: $($LocalPath) is same as $($RemotePath)"
            #$true
        }
        {$remoteProps.$Property -gt $_} {
            if($update) {
                Write-DiskSpdLog "updating: $($LocalPath) with $($RemotePath)"
                Copy-Item -Path $RemotePath -Destination $LocalPath -Force -PassThru
            } else { 
                #$false 
            }
        }
    }

}

function Update-File {
    param($LocalPath,$RemotePath)
    
    if(-not(Test-Path $LocalPath)) {
        Write-DiskSpdLog -message "$($LocalPath) NOT present, copy from  $($RemotePath)"
        Copy-Item -Path $RemotePath -Destination $LocalPath -Force
    } else {
        Write-DiskSpdLog -message "$($LocalPath) present, checking for update at $($RemotePath)"
        Test-FileVersion -localPath $LocalPath -remotePath $RemotePath -update
    }
}

function Invoke-NetUse {
    param(
        [validatepattern("^\w:$")]
        [string]$DriveLetter,
        [string]$RemotePath,
        [switch]$DeleteExisting=$true
    )
    if($DeleteExisting) {
        $null = net use $DriveLetter /d
        Start-Sleep -Seconds 3
    }
    
    $null = net use $DriveLetter $RemotePath
}

# init log local
Write-DiskSpdLog -message "workernode started -version $version" -local

# mount network drive 
Invoke-NetUse -DriveLetter y: -RemotePath "\\169.254.1.1\ioarmada"

# init log central
Write-DiskSpdLog -message "workernode started -version $version"

# update diskspd.exe
Update-File -LocalPath C:\diskspd.exe -RemotePath y:\diskspd.exe

# update run file
Update-File -LocalPath C:\diskspd-run.ps1 -RemotePath Y:\diskspd-run.ps1

# update workernode
if((Update-File -LocalPath C:\diskspd-workernode.ps1 -RemotePath y:\diskspd-workernode.ps1) -ne $null){
    Write-DiskSpdLog -message "updating myself, gonna reboot!"
    Restart-Computer -Force
} 

$run = "C:\diskspd-run.ps1"

while($true) {
    Write-DiskSpdLog -message "starting: $run"
    $j = Start-Job -ArgumentList $run { param($run) & $run }

    while (($jf = Wait-Job $j -Timeout 1) -eq $null) {
        # wait
    }

    # job finished?
    if ($jf -ne $null) {
        $result = $jf | Receive-Job
        $jf | Remove-Job

        Write-DiskSpdLog -message "finished: $run writing results"
        Write-DiskSpdLog -message $result -isResult
    }
    [system.gc]::Collect()
    Start-Sleep -Seconds 1
    # first version just stops after executing run script
    Stop-Computer -Force 
}
    
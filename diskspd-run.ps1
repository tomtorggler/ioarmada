
# buffer size/alighment, threads/target, outstanding/thread, write%
$b = 4; $t = 4; $o = 8; $w = 50

# io pattern, (r)andom or (s)equential (si as needed for multithread)
$p = 'r'

# output
$Res = 'xml'

# durations of test, cooldown, warmup
$d = 30*60; $cool = 30; $warm = 60

$testfile = "D:\testfile.dat"
$testfilesize = 2GB

### do not modify below ###

if(-not(Test-Path $testfile)) {

    # file does not exist, create
    $null = fsutil file createnew $testfile $testfilesize

} elseif ((Get-Item $testfile).Length -ne $testfilesize) {

    # actual file size not like configured size, delte and recreate testfile
    Remove-Item $testfile -Force -ErrorAction SilentlyContinue
    $null = fsutil file createnew $testfile $testfilesize
}

# run diskspd 

C:\diskspd.exe -Z20M -z -Sh `-t$t `-o$o `-b$($b)k `-$($p)$($b)k `-w$w `-W$warm `-C$cool `-d$($d) -D -L `-R$Res $testfile

# force garbage collection
[system.gc]::Collect()
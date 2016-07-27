#Requires -Modules ImportExcel

<#
charting results in excel. 
use like this, where ResultPath points to the ioarmada share as worker nodes save results there. 

    .\diskspd-results.ps1 -ResultPath C:\ioarmada

#>

param(
    $ResultPath,
    $ResultFilter = "diskspd-result-*.txt",
    $OutFileName = "ioarmada-results.xlsx"
)

$files = Get-ChildItem -Path $ResultPath -Filter $ResultFilter

function get-latency( $x ) {

    $x.Results.TimeSpan.Latency.Bucket |% {
        $_.Percentile,$_.ReadMilliseconds,$_.WriteMilliseconds -join "`t"
    }
}

$l = @(); foreach ($i in 25,50,75,90,95,99,99.9,100) { $l += ,[string]$i }

$files | foreach {

    $x = [xml](Get-Content $_.FullName)

    $lf = $_.fullname -replace '.xml','.lat.tsv'

    if (-not [io.file]::Exists($lf)) {
        get-latency $x > $lf
    }

    $system = $x.Results.System.ComputerName
    $t = $x.Results.TimeSpan.TestTimeSeconds

    # extract the subset of latency percentiles as specified above in $l
    $h = @{}; 
    $x.Results.TimeSpan.Latency.Bucket | % { $h[$_.Percentile] = $_ }

    $ls = $l |% {
        $b = $h[$_];
        if ($b.ReadMilliseconds) { $b.ReadMilliseconds } else { "" }
        if ($b.WriteMilliseconds) { $b.WriteMilliseconds } else { "" }
    }

    # sum read and write iops across all threads and targets
    $ri = ($x.Results.TimeSpan.Thread.Target | measure -sum -Property ReadCount).Sum
    $wi = ($x.Results.TimeSpan.Thread.Target | measure -sum -Property WriteCount).Sum
    $rb = ($x.Results.TimeSpan.Thread.Target | measure -sum -Property ReadBytes).Sum
    $wb = ($x.Results.TimeSpan.Thread.Target | measure -sum -Property WriteBytes).Sum

    # output tab-separated fields. note that with runs specified on the command
    # line, only a single write ratio, outstanding request count and blocksize
    # can be specified, so sampling the one used for the first thread is
    # sufficient.
    (($system,$x.Results.System.RunTime,
        ($x.Results.Profile.TimeSpans.TimeSpan.Targets.Target.WriteRatio | select -first 1),
        $x.Results.TimeSpan.ThreadCount,
        ($x.Results.Profile.TimeSpans.TimeSpan.Targets.Target.RequestCount | select -first 1),
        ($x.Results.Profile.TimeSpans.TimeSpan.Targets.Target.BlockSize | select -first 1), 
        # calculate iops
        ($ri / $t),(($rb / $t)/1mb),($wi / $t),(($wb / $t)/1mb)) -join ","),($ls -join ",") -join ","

} | 
ConvertFrom-Csv -Delimiter ',' -Header 'ComputerName','RunTime','WriteRatio','Threads','Outstanding','BlockSize','ReadIOPs','ReadMbps','WriteIOPs','WriteMbps','25th','50th','75th','90th','99th','999th','Max' |
Export-Excel -Path (join-path -Path $ResultPath -ChildPath $OutFileName) -WorkSheetname Overall -IncludePivotTable -PivotRows "ComputerName" -PivotData @('ReadIOPs','ReadMbps','WriteIOPs','WriteMbps') 

foreach($file in $files){
    $name = $file.BaseName -replace("diskspd-result-\d{18}-",$null)

    $chartLat = New-ExcelChart -Title Latency `
    -ChartType LineStacked -Header "Latency" `
    -YRange @("Latency_$name[TotalMilliseconds]","Latency_$name[ReadMilliseconds]","Latency_$name[WriteMilliseconds]" )`
    -XRange "Latency_$name[Percentile]"`
    -SeriesHeader @("TotalMs","ReadMs","WriteMs" )`
    -Width 900 -Height 600

    $chartIO = New-ExcelChart -Title IOPS `
    -ChartType XYScatter -Header "IOPS" `
    -YRange @("IOPS_$name[Write]","IOPS_$name[Read]","IOPS_$name[Total]" )`
    -XRange "IOPS_$name[SampleMillisecond]"`
    -SeriesHeader @("Write","Read","Total" )`
    -Width 900 -Height 600

    
    $xml = [xml](Get-Content $file.fullname)
    $latency = $xml.Results.timespan.Latency.Bucket | select Percentile,ReadMilliseconds,WriteMilliseconds,TotalMilliseconds 
    $iops = $xml.Results.timespan.Iops.Bucket | select SampleMillisecond,Read,Write,Total

    $latency | Export-Excel -Path (join-path -Path $ResultPath -ChildPath $OutFileName) -AutoSize -WorkSheetname "lat_$Name" -ExcelChartDefinition $chartLat -TableName "Latency_$name"
    $iops | Export-Excel -Path (join-path -Path $ResultPath -ChildPath $OutFileName) -AutoSize -WorkSheetname "iops_$name" -ExcelChartDefinition $chartIO -TableName "IOPS_$name"
}


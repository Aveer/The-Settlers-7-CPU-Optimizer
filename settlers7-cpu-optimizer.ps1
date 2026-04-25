<#
The Settlers 7 CPU Optimizer

This script sets The Settlers 7 to High process priority and applies a CPU
affinity mask that avoids Hyper-Threading sibling threads on supported CPUs.
#>

$ErrorActionPreference = "Stop"

$GameUri = "uplay://launch/11788/0"
$ProcessName = "Settlers7R"

$AffinityMasks = @{
    2  = [IntPtr]2
    4  = [IntPtr]10
    6  = [IntPtr]42
    8  = [IntPtr]170
    12 = [IntPtr]2730
    16 = [IntPtr]43690
    20 = [IntPtr]699050
    24 = [IntPtr]11184810
    32 = [IntPtr]2863311530
    48 = [IntPtr]187649984473770
}

function Get-CpuInfo {
    $processors = Get-CimInstance -ClassName Win32_Processor
    $physicalCores = ($processors | Measure-Object -Property NumberOfCores -Sum).Sum
    $logicalThreads = ($processors | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum

    [PSCustomObject]@{
        PhysicalCores  = [int]$physicalCores
        LogicalThreads = [int]$logicalThreads
    }
}

function Get-TargetAffinityMask {
    param(
        [Parameter(Mandatory = $true)]
        [int]$LogicalThreads
    )

    if (-not $AffinityMasks.ContainsKey($LogicalThreads)) {
        throw "Unsupported CPU thread count: $LogicalThreads. Supported counts: $($AffinityMasks.Keys -join ', ')."
    }

    return $AffinityMasks[$LogicalThreads]
}

function Wait-ForGameProcess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    while ($true) {
        $process = Get-Process -Name $Name -ErrorAction SilentlyContinue | Select-Object -First 1

        if ($process) {
            return $process
        }

        Write-Host "The Settlers 7 process was not found. Launch it manually if Ubisoft Connect did not start it."
        Start-Sleep -Seconds 1
    }
}

$cpu = Get-CpuInfo
Write-Host "Physical cores:  $($cpu.PhysicalCores)"
Write-Host "Logical threads: $($cpu.LogicalThreads)"

if ($cpu.PhysicalCores -le 0 -or $cpu.LogicalThreads -le 0) {
    throw "Unable to detect CPU topology."
}

if ($cpu.LogicalThreads / $cpu.PhysicalCores -ne 2) {
    throw "Hyper-Threading or equivalent logical threading does not appear to be enabled. Nothing to optimize."
}

$targetAffinity = Get-TargetAffinityMask -LogicalThreads $cpu.LogicalThreads

Write-Host "Trying to start The Settlers 7 through Ubisoft Connect..."
Start-Process $GameUri
Start-Sleep -Seconds 3

$gameProcess = Wait-ForGameProcess -Name $ProcessName

Write-Host "Found $($gameProcess.ProcessName).exe with PID $($gameProcess.Id)."
Write-Host "Current affinity: $($gameProcess.ProcessorAffinity)"

$gameProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
$gameProcess.ProcessorAffinity = $targetAffinity
$gameProcess.Refresh()

Write-Host "New affinity:     $($gameProcess.ProcessorAffinity)"
Write-Host "Priority:         $($gameProcess.PriorityClass)"
Write-Host "The Settlers 7 was optimized successfully."

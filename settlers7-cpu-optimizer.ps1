<#
The Settlers 7 CPU Optimizer

This script sets The Settlers 7 to High process priority and applies a CPU
affinity mask that avoids one logical sibling thread per physical core on
supported, uniform two-threads-per-core CPU topologies.
#>

$ErrorActionPreference = "Stop"

$GameUri = "uplay://launch/11788/0"
$ProcessName = "Settlers7R"

# These masks preserve the behavior of the original v1.x utility: one logical
# processor from each adjacent pair is selected. They are intentionally limited
# to CPU layouts that the project has historically supported.
$AffinityMasks = @{
    2  = [Int64]2
    4  = [Int64]10
    6  = [Int64]42
    8  = [Int64]170
    12 = [Int64]2730
    16 = [Int64]43690
    20 = [Int64]699050
    24 = [Int64]11184810
    32 = [Int64]2863311530
    48 = [Int64]187649984473770
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
        throw "Unsupported CPU thread count: $LogicalThreads. Supported counts: $($AffinityMasks.Keys | Sort-Object | ForEach-Object { $_ }) -join ', '."
    }

    $mask = $AffinityMasks[$LogicalThreads]

    if ([IntPtr]::Size -eq 4 -and $mask -gt [Int32]::MaxValue) {
        throw "This CPU requires 64-bit PowerShell to apply its affinity mask."
    }

    return [IntPtr]$mask
}

function Get-RunningGameProcess {
    return Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Wait-ForGameProcess {
    while ($true) {
        $process = Get-RunningGameProcess

        if ($process) {
            return $process
        }

        Write-Host "The Settlers 7 process was not found. Launch it manually if Ubisoft Connect did not start it."
        Start-Sleep -Seconds 1
    }
}

function Start-OrFindGameProcess {
    $process = Get-RunningGameProcess

    if ($process) {
        Write-Host "The Settlers 7 is already running; skipping the Ubisoft Connect launch step."
        return $process
    }

    Write-Host "Trying to start The Settlers 7 through Ubisoft Connect..."

    try {
        Start-Process -FilePath $GameUri -ErrorAction Stop | Out-Null
        Start-Sleep -Seconds 3
    }
    catch {
        Write-Warning "Ubisoft Connect could not be started through '$GameUri'. The script will continue waiting for the game; launch it manually."
    }

    return Wait-ForGameProcess
}

$cpu = Get-CpuInfo
Write-Host "Physical cores:  $($cpu.PhysicalCores)"
Write-Host "Logical threads: $($cpu.LogicalThreads)"

if ($cpu.PhysicalCores -le 0 -or $cpu.LogicalThreads -le 0) {
    throw "Unable to detect CPU topology."
}

if ($cpu.LogicalThreads -ne ($cpu.PhysicalCores * 2)) {
    throw "Unsupported CPU topology. This optimizer expects exactly two logical threads per physical core. SMT-disabled, partial-SMT, and hybrid P/E-core layouts are not supported."
}

$targetAffinity = Get-TargetAffinityMask -LogicalThreads $cpu.LogicalThreads
$gameProcess = Start-OrFindGameProcess

Write-Host "Found $($gameProcess.ProcessName).exe with PID $($gameProcess.Id)."

try {
    Write-Host "Current affinity: $($gameProcess.ProcessorAffinity)"
    $gameProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
    $gameProcess.ProcessorAffinity = $targetAffinity
    $gameProcess.Refresh()
}
catch {
    throw "Unable to update the game process priority or affinity. The game may have exited, or PowerShell may not have permission to modify it. Details: $($_.Exception.Message)"
}

Write-Host "New affinity:     $($gameProcess.ProcessorAffinity)"
Write-Host "Priority:         $($gameProcess.PriorityClass)"
Write-Host "The Settlers 7 was optimized successfully."

param(
    [switch]$NoRun
)

<#
The Settlers 7 CPU Optimizer

This script sets The Settlers 7 to High process priority and limits the game
to one logical processor per physical CPU core. Windows processor-topology
information is used so the optimizer does not rely on hard-coded thread masks.
#>

$ErrorActionPreference = "Stop"

$GameUri = "uplay://launch/11788/0"
$ProcessName = "Settlers7R"

function Initialize-ProcessorTopologyApi {
    if ("Settlers7CpuOptimizer.ProcessorTopology" -as [type]) {
        return
    }

    $source = @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace Settlers7CpuOptimizer
{
    public sealed class ProcessorCore
    {
        public ushort Group { get; set; }
        public ulong Mask { get; set; }
        public byte EfficiencyClass { get; set; }
        public bool HasSmt { get; set; }
    }

    public static class ProcessorTopology
    {
        private enum LogicalProcessorRelationship
        {
            RelationProcessorCore = 0
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GetLogicalProcessorInformationEx(
            LogicalProcessorRelationship relationshipType,
            IntPtr buffer,
            ref uint returnedLength);

        public static ProcessorCore[] GetCores()
        {
            uint returnedLength = 0;
            GetLogicalProcessorInformationEx(
                LogicalProcessorRelationship.RelationProcessorCore,
                IntPtr.Zero,
                ref returnedLength);

            if (returnedLength == 0)
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }

            IntPtr buffer = Marshal.AllocHGlobal(checked((int)returnedLength));

            try
            {
                if (!GetLogicalProcessorInformationEx(
                    LogicalProcessorRelationship.RelationProcessorCore,
                    buffer,
                    ref returnedLength))
                {
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                }

                var cores = new List<ProcessorCore>();
                uint offset = 0;

                while (offset < returnedLength)
                {
                    IntPtr item = IntPtr.Add(buffer, checked((int)offset));
                    int relationship = Marshal.ReadInt32(item, 0);
                    int size = Marshal.ReadInt32(item, 4);

                    if (size <= 0)
                    {
                        throw new InvalidOperationException(
                            "Windows returned an invalid processor-topology record.");
                    }

                    if (relationship == (int)LogicalProcessorRelationship.RelationProcessorCore)
                    {
                        byte flags = Marshal.ReadByte(item, 8);
                        byte efficiencyClass = Marshal.ReadByte(item, 9);
                        ushort groupCount = unchecked((ushort)Marshal.ReadInt16(item, 30));

                        if (groupCount != 1)
                        {
                            throw new NotSupportedException(
                                "A physical core spanning multiple processor groups is not supported.");
                        }

                        IntPtr groupAffinity = IntPtr.Add(item, 32);
                        ulong mask = IntPtr.Size == 8
                            ? unchecked((ulong)Marshal.ReadInt64(groupAffinity, 0))
                            : unchecked((uint)Marshal.ReadInt32(groupAffinity, 0));

                        ushort group = unchecked(
                            (ushort)Marshal.ReadInt16(groupAffinity, IntPtr.Size));

                        cores.Add(new ProcessorCore
                        {
                            Group = group,
                            Mask = mask,
                            EfficiencyClass = efficiencyClass,
                            HasSmt = (flags & 0x1) != 0
                        });
                    }

                    offset += checked((uint)size);
                }

                return cores.ToArray();
            }
            finally
            {
                Marshal.FreeHGlobal(buffer);
            }
        }
    }
}
'@

    Add-Type -TypeDefinition $source -Language CSharp
}

function Get-SystemCoreTopology {
    Initialize-ProcessorTopologyApi
    return [Settlers7CpuOptimizer.ProcessorTopology]::GetCores()
}

function Get-SetBitCount {
    param(
        [Parameter(Mandatory = $true)]
        [UInt64]$Mask
    )

    $count = 0
    $value = $Mask

    while ($value -ne 0) {
        $count += [int]($value -band [UInt64]1)
        $value = $value -shr 1
    }

    return $count
}

function Get-LowestSetBit {
    param(
        [Parameter(Mandatory = $true)]
        [UInt64]$Mask
    )

    if ($Mask -eq 0) {
        throw "Processor-core affinity mask cannot be zero."
    }

    for ($index = 0; $index -lt 64; $index++) {
        $bit = [UInt64]1 -shl $index

        if (($Mask -band $bit) -ne 0) {
            return $bit
        }
    }

    throw "Unable to select a logical processor from affinity mask $Mask."
}

function Get-AffinityPlan {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$CoreTopology
    )

    $cores = @($CoreTopology)

    if ($cores.Count -eq 0) {
        throw "Windows did not report any physical CPU cores."
    }

    $groups = @(
        $cores |
            ForEach-Object { [int]$_.Group } |
            Sort-Object -Unique
    )

    if ($groups.Count -ne 1) {
        throw "Multiple Windows processor groups were detected. This optimizer intentionally does not apply a partial process-affinity mask on multi-group systems."
    }

    $affinityMask = [UInt64]0
    $logicalProcessorCount = 0
    $smtCoreCount = 0

    foreach ($core in $cores) {
        $coreMask = [UInt64]$core.Mask

        if ($coreMask -eq 0) {
            throw "Windows reported a physical core with an empty affinity mask."
        }

        $logicalProcessorsOnCore = Get-SetBitCount -Mask $coreMask
        $logicalProcessorCount += $logicalProcessorsOnCore

        if ($logicalProcessorsOnCore -gt 1) {
            $smtCoreCount++
        }

        $selectedProcessor = Get-LowestSetBit -Mask $coreMask
        $affinityMask = $affinityMask -bor $selectedProcessor
    }

    [PSCustomObject]@{
        Group                 = $groups[0]
        AffinityMask          = $affinityMask
        PhysicalCoreCount     = $cores.Count
        LogicalProcessorCount = $logicalProcessorCount
        SmtCoreCount          = $smtCoreCount
    }
}

function ConvertTo-IntPtrAffinityMask {
    param(
        [Parameter(Mandatory = $true)]
        [UInt64]$AffinityMask
    )

    if ($AffinityMask -eq 0) {
        throw "Affinity mask cannot be zero."
    }

    if ([IntPtr]::Size -eq 4) {
        if ($AffinityMask -gt [UInt32]::MaxValue) {
            throw "This affinity mask requires 64-bit PowerShell."
        }

        $bytes = [BitConverter]::GetBytes([UInt32]$AffinityMask)
        $signedMask = [BitConverter]::ToInt32($bytes, 0)
        return [IntPtr]$signedMask
    }

    $bytes = [BitConverter]::GetBytes($AffinityMask)
    $signedMask = [BitConverter]::ToInt64($bytes, 0)
    return [IntPtr]$signedMask
}

function Get-RunningGameProcess {
    return Get-Process -Name $ProcessName -ErrorAction SilentlyContinue |
        Select-Object -First 1
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

function Invoke-Settlers7CpuOptimizer {
    $topology = Get-SystemCoreTopology
    $plan = Get-AffinityPlan -CoreTopology $topology

    Write-Host "Physical cores:     $($plan.PhysicalCoreCount)"
    Write-Host "Logical processors: $($plan.LogicalProcessorCount)"
    Write-Host "SMT-enabled cores:  $($plan.SmtCoreCount)"
    Write-Host "Processor group:    $($plan.Group)"

    if ($plan.SmtCoreCount -eq 0) {
        Write-Host "No SMT sibling threads were detected. Nothing to optimize."
        return
    }

    $targetAffinity = ConvertTo-IntPtrAffinityMask -AffinityMask $plan.AffinityMask
    $gameProcess = Start-OrFindGameProcess

    Write-Host "Found $($gameProcess.ProcessName).exe with PID $($gameProcess.Id)."

    try {
        $gameProcess.Refresh()
        Write-Host "Current affinity: $($gameProcess.ProcessorAffinity)"

        $gameProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
        $gameProcess.ProcessorAffinity = $targetAffinity
        $gameProcess.Refresh()
    }
    catch {
        throw "Unable to update the game process priority or affinity. The game may have exited, PowerShell may not have permission to modify it, or Windows may have restricted the process to a different processor group. Details: $($_.Exception.Message)"
    }

    Write-Host "New affinity:     $($gameProcess.ProcessorAffinity)"
    Write-Host "Priority:         $($gameProcess.PriorityClass)"
    Write-Host "The Settlers 7 was optimized successfully."
}

if (-not $NoRun) {
    Invoke-Settlers7CpuOptimizer
}

BeforeAll {
    . "$PSScriptRoot/../settlers7-cpu-optimizer.ps1" -NoRun
}

Describe "Get-AffinityPlan" {
    It "selects one logical processor from each adjacent SMT pair" {
        $topology = @(
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]3 }
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]12 }
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]48 }
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]192 }
        )

        $plan = Get-AffinityPlan -CoreTopology $topology

        $plan.AffinityMask | Should -Be ([UInt64]85)
        $plan.PhysicalCoreCount | Should -Be 4
        $plan.LogicalProcessorCount | Should -Be 8
        $plan.SmtCoreCount | Should -Be 4
    }

    It "uses actual core masks instead of assuming adjacent SMT numbering" {
        $topology = @(
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]17 }
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]34 }
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]68 }
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]136 }
        )

        $plan = Get-AffinityPlan -CoreTopology $topology

        $plan.AffinityMask | Should -Be ([UInt64]15)
        $plan.LogicalProcessorCount | Should -Be 8
        $plan.SmtCoreCount | Should -Be 4
    }

    It "keeps single-threaded cores while reducing SMT-enabled cores to one logical processor" {
        $topology = @(
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]3 }
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]12 }
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]16 }
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]32 }
        )

        $plan = Get-AffinityPlan -CoreTopology $topology

        $plan.AffinityMask | Should -Be ([UInt64]53)
        $plan.PhysicalCoreCount | Should -Be 4
        $plan.LogicalProcessorCount | Should -Be 6
        $plan.SmtCoreCount | Should -Be 2
    }

    It "reports zero SMT cores when every physical core exposes one logical processor" {
        $topology = @(
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]1 }
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]2 }
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]4 }
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]8 }
        )

        $plan = Get-AffinityPlan -CoreTopology $topology

        $plan.AffinityMask | Should -Be ([UInt64]15)
        $plan.SmtCoreCount | Should -Be 0
    }

    It "rejects a topology that spans multiple processor groups" {
        $topology = @(
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]1 }
            [PSCustomObject]@{ Group = 1; Mask = [UInt64]1 }
        )

        { Get-AffinityPlan -CoreTopology $topology } |
            Should -Throw "*processor groups*"
    }

    It "rejects an empty physical-core mask" {
        $topology = @(
            [PSCustomObject]@{ Group = 0; Mask = [UInt64]0 }
        )

        { Get-AffinityPlan -CoreTopology $topology } |
            Should -Throw "*empty affinity mask*"
    }
}

Describe "ConvertTo-IntPtrAffinityMask" {
    It "preserves ordinary affinity masks" {
        $pointer = ConvertTo-IntPtrAffinityMask -AffinityMask ([UInt64]85)

        [UInt64]$pointer.ToInt64() | Should -Be ([UInt64]85)
    }

    It "preserves bit 63 on 64-bit PowerShell" -Skip:([IntPtr]::Size -ne 8) {
        $mask = [UInt64]9223372036854775808
        $pointer = ConvertTo-IntPtrAffinityMask -AffinityMask $mask
        $roundTrip = [BitConverter]::ToUInt64(
            [BitConverter]::GetBytes($pointer.ToInt64()),
            0
        )

        $roundTrip | Should -Be $mask
    }
}

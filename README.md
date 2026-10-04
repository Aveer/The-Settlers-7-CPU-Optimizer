# The Settlers 7 CPU Optimizer

[![CI](https://github.com/Aveer/The-Settlers-7-CPU-Optimizer/actions/workflows/ci.yml/badge.svg)](https://github.com/Aveer/The-Settlers-7-CPU-Optimizer/actions/workflows/ci.yml)

A small Windows utility that improves CPU scheduling for **The Settlers 7** by changing the game's process affinity and priority after launch.

The Settlers 7 can perform poorly on some CPUs with simultaneous multithreading (SMT / Hyper-Threading). This tool works around that behavior by keeping one logical processor per physical CPU core and setting the game process priority to **High**. Depending on your hardware and the in-game situation, this can improve performance without changing graphics settings.

## Recommended version

The recommended and maintained version is the PowerShell script in this repository:

```powershell
.\settlers7-cpu-optimizer.ps1
```

This version is readable and does not require Python, a virtual environment, PyInstaller, or a packaged executable.

## First run after downloading

Windows may mark a PowerShell script downloaded from the internet as coming from an external source. If PowerShell blocks the script, review it first and then remove that mark:

```powershell
Unblock-File .\settlers7-cpu-optimizer.ps1
```

Then run it normally:

```powershell
.\settlers7-cpu-optimizer.ps1
```

Changing the machine-wide PowerShell execution policy is not required for this project.

## Legacy executable

The old v1.x prebuilt `.exe` versions in GitHub Releases are **legacy builds from 2021**. They are preserved for historical/reference purposes and are no longer the maintained version of the optimizer.

Some antivirus tools may flag the old `.exe` as suspicious. This is likely a false positive caused by the way the old Python application was packaged into a standalone executable, but you should still make your own decision before running any executable downloaded from the internet.

For normal use, use the PowerShell script instead of the legacy `.exe`.

## What it does

When started, the optimizer:

1. Reads the physical-core topology reported by Windows.
2. Identifies which logical processors belong to each physical core.
3. Builds an affinity mask that keeps one logical processor from every physical core.
4. Reuses an already-running `Settlers7R.exe` process, or tries to launch the game through Ubisoft Connect.
5. Waits for `Settlers7R.exe` if the launcher cannot start it automatically.
6. Sets the game process priority to **High**.
7. Applies the topology-derived CPU affinity mask.

The script only targets the running The Settlers 7 process.

## CPU support

The optimizer no longer uses hard-coded masks or assumes that SMT siblings have adjacent logical-processor numbers. It uses the Windows `GetLogicalProcessorInformationEx(RelationProcessorCore)` API to discover the actual relationship between physical cores and logical processors.

This also makes mixed/hybrid layouts safer: a single-threaded core remains available, while an SMT-enabled core contributes one of its logical processors to the target mask.

### Processor-group limitation

The current implementation intentionally supports **one Windows processor group only**. A processor group can contain up to 64 logical processors on 64-bit Windows.

If Windows reports more than one processor group, the script exits instead of applying a partial or misleading affinity mask. Correctly optimizing a process across multiple processor groups requires group-aware thread-affinity handling rather than the single process-affinity mask used by this utility.

Use 64-bit PowerShell on modern systems. A 32-bit PowerShell process cannot represent affinity masks above 32 logical processors.

## Requirements

- Windows
- Windows PowerShell 5.1 or PowerShell 7
- The Settlers 7 installed through Ubisoft Connect or already running manually
- A CPU topology contained within one Windows processor group

## Usage

Open PowerShell in the repository folder and run:

```powershell
.\settlers7-cpu-optimizer.ps1
```

If The Settlers 7 is already running, the script uses the existing process and does not try to launch another instance.

Otherwise, the script tries to launch the game through Ubisoft Connect. If the `uplay://` URI cannot be opened on your system, the script continues running and waits for you to launch the game manually.

You need to run the optimizer each time you launch the game, because Windows process affinity and priority are reset when the game closes.

## Testing

CI validates the project on Windows by:

- parsing the script with Windows PowerShell 5.1;
- parsing it with PowerShell 7;
- exercising the Windows processor-topology API in both runtimes;
- running the Pester unit-test suite;
- running PSScriptAnalyzer.

The CI tool versions are pinned for reproducible builds.

## Releases

Normal releases are created through the repository's **Release** GitHub Actions workflow. It validates the script and test suite before publishing the PowerShell script as the release asset.

## Performance impact

Historically reported improvement: **7-30 FPS**, depending on CPU, GPU, game state, and scene complexity.

The screenshots below were captured at 4K with maximum settings on an Intel i7-7700K and GTX 1080 Ti.

## Screenshots

### Comparison 1

**Before**

![Settlers 7 - Before 1](https://user-images.githubusercontent.com/84144527/118640305-1c914200-b7d9-11eb-96d2-eb66fd4524eb.jpg)
![Settlers 7 - Before 11](https://user-images.githubusercontent.com/84144527/118640312-1e5b0580-b7d9-11eb-9e7e-7b66f50a38c8.png)

**After**

![Settlers 7 - After 1](https://user-images.githubusercontent.com/84144527/118640280-1602ca80-b7d9-11eb-9b5d-b55cdfe00e81.jpg)
![Settlers 7 - After 11](https://user-images.githubusercontent.com/84144527/118640303-1bf8ab80-b7d9-11eb-9c4e-e62fdfeb7d6a.png)

---

### Comparison 2

**Before**

![Settlers 7 - Before 2](https://user-images.githubusercontent.com/84144527/118640309-1dc26f00-b7d9-11eb-9c3b-62edac0f2e38.jpg)
![Settlers 7 - Before 22](https://user-images.githubusercontent.com/84144527/118640314-1e5b0580-b7d9-11eb-8d18-912cf291ff8d.png)

**After**

![Settlers 7 - After 2](https://user-images.githubusercontent.com/84144527/118640293-1a2ee800-b7d9-11eb-8eac-68f280f677ba.jpg)
![Settlers 7 - After 22](https://user-images.githubusercontent.com/84144527/118640304-1c914200-b7d9-11eb-868b-bc11e3bf07b1.png)

---

### Direct zoomed comparison

![Settlers 7 - Before 11](https://user-images.githubusercontent.com/84144527/118640312-1e5b0580-b7d9-11eb-9e7e-7b66f50a38c8.png)
![Settlers 7 - After 11](https://user-images.githubusercontent.com/84144527/118640303-1bf8ab80-b7d9-11eb-9c4e-e62fdfeb7d6a.png)
![Settlers 7 - Before 22](https://user-images.githubusercontent.com/84144527/118640314-1e5b0580-b7d9-11eb-8d18-912cf291ff8d.png)
![Settlers 7 - After 22](https://user-images.githubusercontent.com/84144527/118640304-1c914200-b7d9-11eb-868b-bc11e3bf07b1.png)

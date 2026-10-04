# The Settlers 7 CPU Optimizer

[![CI](https://github.com/Aveer/The-Settlers-7-CPU-Optimizer/actions/workflows/ci.yml/badge.svg)](https://github.com/Aveer/The-Settlers-7-CPU-Optimizer/actions/workflows/ci.yml)

A small Windows utility that improves CPU scheduling for **The Settlers 7** by changing the game's process affinity and priority after launch.

The Settlers 7 can perform poorly on some CPUs with Hyper-Threading enabled. This tool works around that behavior by limiting the game process to one logical processor per physical core and setting the process priority to **High**. Depending on your hardware and the in-game situation, this can improve performance without changing graphics settings.

## Recommended version

The recommended and maintained version is the PowerShell script in this repository:

```powershell
.\settlers7-cpu-optimizer.ps1
```

This version is simple, readable, and does not require Python, a virtual environment, PyInstaller, or a packaged executable.

## Legacy executable

The old v1.x prebuilt `.exe` versions in GitHub Releases are **legacy builds from 2021**. They are preserved for historical/reference purposes and are no longer the maintained version of the optimizer.

Some antivirus tools may flag the old `.exe` as suspicious. This is likely a false positive caused by the way the old Python application was packaged into a standalone executable, but you should still make your own decision before running any executable downloaded from the internet.

For normal use, use the PowerShell script instead of the legacy `.exe`.

## What it does

When started, the optimizer:

1. Detects your physical CPU cores and logical CPU threads.
2. Verifies that the CPU has a supported uniform two-threads-per-core topology.
3. Reuses an already-running `Settlers7R.exe` process, or tries to launch the game through Ubisoft Connect.
4. Waits for `Settlers7R.exe` if the launcher cannot start it automatically.
5. Sets the game process priority to **High**.
6. Applies a CPU affinity mask that keeps one logical processor from each supported sibling pair.

The script only targets the running The Settlers 7 process.

## Requirements

- Windows
- PowerShell
- The Settlers 7 installed through Ubisoft Connect or already running manually
- A supported CPU topology and logical-thread count

## Supported CPUs

The optimizer currently supports conventional CPUs with **exactly two logical threads per physical core** and one of the following logical-thread counts:

`2, 4, 6, 8, 12, 16, 20, 24, 32, 48`

The affinity masks preserve the behavior of the original v1.x utility and assume that the two logical processors belonging to each physical core are exposed as adjacent logical-processor indices.

The script intentionally stops instead of applying an affinity mask when the detected topology is not a uniform 2-way SMT layout. In particular, **hybrid P/E-core CPUs, SMT-disabled systems, and partial-SMT layouts are not supported** by the current implementation.

On 32-bit PowerShell, affinity masks that exceed the 32-bit pointer range are rejected with a clear error; use 64-bit PowerShell for those CPUs.

## Usage

Open PowerShell in the repository folder and run:

```powershell
.\settlers7-cpu-optimizer.ps1
```

If The Settlers 7 is already running, the script uses the existing process and does not try to launch another instance.

Otherwise, the script tries to launch the game through Ubisoft Connect. If the `uplay://` URI cannot be opened on your system, the script continues running and waits for you to launch the game manually.

You need to run the optimizer each time you launch the game, because Windows process affinity and priority are reset when the game closes.

## Performance impact

Reported improvement: **7-30 FPS**, depending on CPU, GPU, game state, and scene complexity.

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

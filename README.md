# The Settlers 7 CPU Optimizer

A small Windows utility that improves CPU scheduling for **The Settlers 7** by changing the game's process affinity and priority after launch.

The Settlers 7 can perform poorly on some CPUs with Hyper-Threading enabled. This tool works around that behavior by limiting the game process to physical CPU cores and setting the process priority to **High**. Depending on your hardware and the in-game situation, this can improve performance without changing graphics settings.

Current version: **1.02**

## What it does

When started, the optimizer:

1. Launches The Settlers 7 through Ubisoft Launcher, when available.
2. Waits for the game process to start.
3. Changes the game process affinity so it avoids Hyper-Threading threads.
4. Sets the game process priority to **High**.
5. Closes automatically after the optimization is applied.

The tool only targets the running The Settlers 7 process.

## Performance impact

Reported improvement: **7-30 FPS**, depending on CPU, GPU, game state, and scene complexity.

The screenshots below were captured at 4K with maximum settings on an Intel i7-7700K and GTX 1080 Ti.

## Supported CPUs

The optimizer supports CPUs with the following logical thread counts:

`2, 4, 6, 8, 12, 16, 20, 24, 32, 48`

It is intended for CPUs with Hyper-Threading or a similar logical-threading technology.

## Usage

### Option 1: Run the executable

Download and run the `.exe` file, then wait for the optimizer to finish.

The tool needs to be started each time you launch the game, because Windows process affinity and priority are reset when the game closes.

### Option 2: Run from source

Download the source code and run:

```bash
python main.py
```

## Antivirus warning

Some antivirus tools may flag the packaged `.exe` file as suspicious. This can happen with bundled Python executables, but you should still make your own decision before running any executable downloaded from the internet.

If you are unsure, review the source code and run `main.py` directly with Python instead of using the packaged executable.

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

# The-Settlers-7-CPU-Optimizer
Optimizes The Settlers 7 (All version) to better utylize CPU. Settlers 7 does not like HT technology so this script changes the affinity of the process to disable HT threads for the running process of Settlers 7. It grants 7-30 FPS boost (depends on the hardware and situation in game) without any graphical compromises. It also sets the process to High priority which grants further benefits.

Script:
1. Launches the game from Ubisoft launcher (can be launched manualy from other sources too).
2. Disables HT for the Settlers 7 process
3. Sets the priority of Settlers 7 process to High.
4. Needs to be started everytime you launch a game in order to optimize the process.
5. Automatically closes once optimization is done

Effect:

7-30 FPS boost without any compromises (depends on the hardware and situation in game)


Supported CPUs with: 2, 4, 6, 8, 12, 16, 20, 24, 32, 48 threads.
Works only for CPUs with HT technology

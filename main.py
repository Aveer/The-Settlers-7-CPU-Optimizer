from time import sleep
from multiprocessing import cpu_count
from os import startfile
import psutil
import affinity


filepath = 'uplay://launch/11788/0'  # Path to the game so it can be started by the script
pName = "Settlers7R.exe"  # name of the process


# Detects the amount of CPU threads on the system. Detects if system is using HT technology.
def get_cpu_threads():
    ct = cpu_count()
    rc = psutil.cpu_count(logical=False)
    print("Number of physical cores: ", rc )
    print("Number of threads: ", ct)

    if ct/rc == 2:
        print("HT is on")
    else:
        print("HT is off. Unable to optimize. Exiting script.")
        exit()
    return ct


# Detects the proper affinity mask value for CPU in order to disable HT for the process
def detect_target_affinity(cpu_threads):
    affinity_dict = {2: 2, 4: 10, 6: 42, 8: 170, 12: 2730, 16: 43690, 20: 699050, 24: 11184810, 32: 2863311530,
                     48: 187649984473770}

    if cpu_threads in affinity_dict.keys():
        return affinity_dict[cpu_threads]
    else:
        print("Unsupported amount of CPU threads. Unable to optimize. Closing the script.")
        exit()


# Returns PID of process by provided process name. Also sets priority of process to "High Priority".
def get_pid(pName):
    pid = 0
    ps = False
    for proc in psutil.process_iter():
        if proc.name() == pName:
            proc.nice(psutil.HIGH_PRIORITY_CLASS)
            print("High priority set for:", pName)
            pid = str(proc)
            pid = pid.split("=")
            pid = int(pid[1].split(",")[0])
            print("PID for process {} = {}".format(pName, pid))
            ps = True
            return pid, ps

    print("The Settlers 7 not launched. Please launch it manually if the script was not able to launch it automatically via Ubisoft Launcher")
    return pid, ps


# Sets Affinity to disable HT for a process.
def set_affinity(PID, target_affinity):
    try:
        affinity.set_process_affinity_mask(PID, target_affinity)
    except:
        print("Unknown error")
        exit()
    print("New, optimized CPU affinity for {} applied".format(pName))


# Prints current affinity settings for a process.
def current_affinity(PID):
    ca = affinity.get_process_affinity_mask(PID)
    print("Current affinity settings for {} = {}".format(pName, ca))


if __name__ == "__main__":
    pid_status = False
    cpu_threads = get_cpu_threads()
    target_affinity = detect_target_affinity(cpu_threads)
    sleep(1)
    startfile(filepath)
    print("Trying to start the game via Ubisoft Launcher")
    sleep(3)

    while pid_status == False:
        try:
            PID, pid_status = get_pid(pName)
            sleep(1)
        except PermissionError:
            print("The Settlers 7 was detected but was closed while running the script. Exiting the script")
            exit()

    current_affinity(PID)
    set_affinity(PID, target_affinity)
    current_affinity(PID)
    print("Settlers 7 was optimized successfully")

    for x in range(5):
        sleep(1)
        print("exiting in", -x+5)
    exit()

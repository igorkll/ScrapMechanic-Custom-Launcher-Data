import sys
import ctypes 
import os
import time
import shutil
import psutil    

while True:
    time.sleep(1)
    finded = False
    for p in psutil.process_iter():
        if p.name() == "ScrapMechanic.exe":
            finded = True
    if not finded:
        break

try:
    shutil.copytree(sys.argv[2], sys.argv[3], False, None, shutil.copy2, False, True)
    ctypes.windll.user32.MessageBoxW(0, "the better API has been updated to version: " + sys.argv[5], "successfully", 0)
    os.system(sys.argv[4])
except Exception as e:
    ctypes.windll.user32.MessageBoxW(0, "failed to update betterAPI: " + str(e), "errpr", 0)
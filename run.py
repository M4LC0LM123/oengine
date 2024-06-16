import os
import sys

os.chdir("windows")
run = "run.bat"

if (sys.platform == "darwin"):
    os.chdir("../macos")
    run = "sh run.sh"
elif (sys.platform == "linux" or sys.platform == "linux2"):
    os.chdir("../linux")
    run = "sh run.sh"

os.system(run)
os.chdir("../")
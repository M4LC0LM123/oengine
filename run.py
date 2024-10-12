import os
import sys

editor = False
if (len(sys.argv) > 1):
    if (sys.argv[1] == "-editor"):
        editor = True

if (editor):
    os.chdir("editor")

os.chdir("windows")
run = "run.bat"

if (sys.platform == "darwin"):
    os.chdir("../macos")
    run = "sh run.sh"
elif (sys.platform == "linux" or sys.platform == "linux2"):
    os.chdir("../linux")
    run = "sh run.sh"


os.system(run)

if (editor): os.chdir("../../")
else: os.chdir("../")

import os
import sys

editor = False
debug = False
if (len(sys.argv) > 1):
    if (sys.argv[1] == "-editor"):
        editor = True
    elif (sys.argv[1] == "-debug"):
    	debug = True

if (editor):
    os.chdir("editor")

os.chdir("windows")
run = "run.bat"
if (debug):
    run = "run_debug.bat"

if (sys.platform == "darwin"):
    os.chdir("../macos")
    run = "sh run.sh"
    if (debug):
    	run = "sh run_debug.sh"
elif (sys.platform == "linux" or sys.platform == "linux2"):
    os.chdir("../linux")
    run = "sh run.sh"
    if (debug):
    	run = "sh run_debug.sh"


os.system(run)

if (editor): os.chdir("../../")
else: os.chdir("../")

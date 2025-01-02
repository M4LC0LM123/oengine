import tkinter as tk
from tkinter import filedialog
from tkinter import messagebox
from dataclasses import dataclass
import os
import shutil
import enum

WIDTH = 300
HEIGHT = 200
OFFS = 5

@dataclass
class Color:
    r: int
    g: int
    b: int

    def to_hex(self):
        return "#%02x%02x%02x" % (self.r, self.g, self.b)

def to_hex(color: Color):
    return "#%02x%02x%02x" % (color.r, color.g, color.b)

class FileType(enum.Enum):
    FILE = 0
    FOLDER = 1
    
@dataclass
class Module:
    type: FileType
    name: str

@dataclass
class Colors:
    WHITE: Color = Color(255, 255, 255)
    main: Color = Color(99, 141, 160)
    accent: Color = Color(63, 105, 135)
    darker: Color = Color(41, 59, 68)
    lighter: Color = Color(119, 169, 191)
colors = Colors()

def str_vec2(x, y, sep = "x"):
    return str(x) + sep + str(y)

def str_trans(x, y, w, h):
    return "%dx%d+%d+%d" % (w, h, x, y) 

def move_win(e: tk.Event):
    root.geometry(str_trans(e.x_root - WIDTH / 2, e.y_root - 25 / 2, WIDTH, HEIGHT))

def get_dir():
    global path
    path = filedialog.askdirectory()
    path_label = tk.Label(
        text=path,
        bg=colors.main.to_hex(),
        fg=colors.WHITE.to_hex()
    ); path_label.place(x=50 + OFFS * 2, y=25 + OFFS)

def copy_module(path, name, type):
    res = path + "/" + name

    if (type == FileType.FOLDER):
        shutil.copytree(name, res)
    elif (type == FileType.FILE):
        shutil.copy(name, res)

def create_proj():
    global path
    global name_entry
    global mods
    os.chdir("../../")

    name = "OengineProject"
    if (name_entry.get() != ""):
        name = name_entry.get()

    res_dir = path + "/" + name

    if (os.path.exists(res_dir)):
        messagebox.showerror("Directory error", "Error: the directory" + res_dir + " already exists")
        return

    os.mkdir(res_dir)

    for mod in mods:
        copy_module(res_dir, mod.name, mod.type)
    
path = ""
mods = [
    Module(FileType.FOLDER, "resources"),
    Module(FileType.FOLDER, "macos"),
    Module(FileType.FOLDER, "macos-arm64"),
    Module(FileType.FOLDER, "assets"),
    Module(FileType.FOLDER, "linux"),
    Module(FileType.FOLDER, "oengine"),
    Module(FileType.FOLDER, "src"),
    Module(FileType.FOLDER, "windows"),
    Module(FileType.FILE, "ols.json"),
    Module(FileType.FILE, "odinfmt.json"),
    Module(FileType.FILE, "run.py"),
]

root = tk.Tk()
root.geometry(str_trans(200, 200, WIDTH, HEIGHT))
root.resizable(False, False)
root.overrideredirect(True)
root.configure(bg=colors.main.to_hex())

title_bar = tk.Frame(root, bg=colors.main.to_hex(), relief="raised")
title_bar.place(x=0, y=0, width=WIDTH, height=25)
title_bar.bind("<B1-Motion>", move_win)

title_label = tk.Label(title_bar, text="Oengine generator", bg=colors.main.to_hex(), fg=colors.WHITE.to_hex())
title_label.pack(side=tk.LEFT, pady=2)

exit_btn = tk.Button(
    title_bar, 
    text="X", 
    command=root.quit, 
    bg=colors.main.to_hex(), 
    fg=colors.WHITE.to_hex(),
    activebackground=colors.accent.to_hex(),
    activeforeground=colors.WHITE.to_hex()
); exit_btn.pack(side=tk.RIGHT, padx=3, pady=3, ipadx=5)

path_btn = tk.Button(
    root, 
    text="Path",
    bg=colors.main.to_hex(),
    fg=colors.WHITE.to_hex(),
    activebackground=colors.accent.to_hex(),
    activeforeground=colors.WHITE.to_hex(),
    command=get_dir
); path_btn.place(x=OFFS, y=25 + OFFS, width=50, height=25)

name_label = tk.Label(
    root,
    text="Name",
    bg=colors.main.to_hex(),
    fg=colors.WHITE.to_hex(),
); name_label.place(x=OFFS, y=50 + OFFS * 2, width=50, height=25)

name_entry = tk.Entry(
    root,
    bg=colors.accent.to_hex(),
    fg=colors.WHITE.to_hex()
); name_entry.place(x=50 + OFFS * 2, y=50 + OFFS * 2, width=100, height=25)

create_btn = tk.Button(
    root,
    text="Create",
    bg=colors.main.to_hex(),
    fg=colors.WHITE.to_hex(),
    activebackground=colors.accent.to_hex(),
    activeforeground=colors.WHITE.to_hex(),
    command=create_proj
); create_btn.place(x=WIDTH - 50 - OFFS, y=HEIGHT - 25 - OFFS, width=50, height=25)

root.mainloop()

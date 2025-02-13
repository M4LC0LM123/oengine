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

main_text = """package main

import "core:fmt"
import str "core:strings"
import rl "vendor:raylib"
import oe "../oengine"

main :: proc() {
    oe.w_create();
    oe.w_set_title("gejm");
    oe.w_set_target_fps(60);
    oe.window.debug_stats = true;

    oe.ew_init(oe.vec3_y() * 50);
    oe.load_registry("../registry.json");

    camera := oe.cm_init(oe.vec3_zero());
    is_mouse_locked: bool = false;
    oe.ecs_world.camera = &camera;

    for (oe.w_tick()) {
        oe.ew_update();

        if (oe.key_pressed(oe.Key.ESCAPE)) {
            is_mouse_locked = !is_mouse_locked;
        }

        oe.cm_set_fps(&camera, 0.1, is_mouse_locked);
        oe.cm_set_fps_controls(&camera, 10, is_mouse_locked, true);
        oe.cm_default_fps_matrix(&camera);
        oe.cm_update(&camera);

        // render
        oe.w_begin_render();
        rl.ClearBackground(rl.SKYBLUE);

        rl.BeginMode3D(camera.rl_matrix);
        oe.ew_render();

        rl.EndMode3D();
        oe.w_end_render();
    }

    oe.ew_deinit();
    oe.w_close();
}
"""

reg_text = """{
    "dbg_pos": 3,
}
"""

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
    mod_path = os.getcwd() + "/" + name

    if (type == FileType.FOLDER):
        shutil.copytree(mod_path, res)
    elif (type == FileType.FILE):
        shutil.copy(mod_path, res)

def create_proj():
    global path
    global name_entry
    global mods
    global main_text
    global reg_text
    global editor
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

    if (editor.get()):
        copy_module(res_dir, "editor", FileType.FOLDER)

    fr = open(res_dir + "/registry.json", "w")
    fr.write(reg_text)
    fr.close()

    os.mkdir(res_dir + "/src")
    fm = open(res_dir + "/src/main.odin", "w")
    fm.write(main_text)
    fm.close()
    
path = ""
mods = [
    Module(FileType.FOLDER, "resources"),
    Module(FileType.FOLDER, "macos"),
    Module(FileType.FOLDER, "macos-arm64"),
    Module(FileType.FOLDER, "linux"),
    Module(FileType.FOLDER, "oengine"),
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

editor = tk.BooleanVar()

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

editor_check = tk.Checkbutton(
    root,
    bg=colors.main.to_hex(),
    activebackground=colors.main.to_hex(),
    variable=editor,
    onvalue=True,
    offvalue=False,
); editor_check.place(x=OFFS, y=75 + OFFS * 3, width=25, height=25)

editor_label = tk.Label(
    root,
    text="Include editor",
    bg=colors.main.to_hex(),
    fg=colors.WHITE.to_hex(),
); editor_label.place(x=25 + OFFS * 2, y = 75 + OFFS * 3, width=75, height=25)

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

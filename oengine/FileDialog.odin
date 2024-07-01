package oengine

import "core:fmt"
import "core:path/filepath"
import rl "vendor:raylib"
import sdl "vendor:sdl2"
import ttf "vendor:sdl2/ttf"
import strs "core:strings"

BUTTON_WIDTH :: 180
BUTTON_HEIGHT :: 30

fd_file_path :: proc() -> string {
    @static curr_dir: cstring;
    curr_dir = rl.GetWorkingDirectory();
    @static files: rl.FilePathList;
    files = rl.LoadDirectoryFiles(curr_dir);

    if (ttf.WasInit() == 0) {
        ttf.Init();
    }

    @static fd_font: ^ttf.Font;
    fd_font = ttf.OpenFont(strs.clone_to_cstring(str_add(OE_FONTS_PATH, "Roboto-Regular.ttf")), 28);
    if (fd_font == nil) {
        dbg_log(str_add("Failed to load font: ", string(ttf.GetError())), DebugType.ERROR);
    }

    render := proc(renderer: ^sdl.Renderer) {
        sdl.SetRenderDrawColor(renderer, gui_main_color.r, gui_main_color.g, gui_main_color.b, gui_main_color.a);
        sdl.RenderClear(renderer);

        sdl_draw_text(renderer, fd_font, string(curr_dir), 10, 10, 500, 25, WHITE);

        for i in 0..<files.count {
            sdl_draw_text(renderer, fd_font, string(files.paths[i]), 10, 45 + 25 * i, 500, 25, WHITE);
        }
    }

    window := sdl_create_window(800, 600, "Files");
    sdl_window(window, sdl_create_renderer(window), nil, render);

    return "";
}

package oengine

import "core:fmt"
import "core:path/filepath"
import rl "vendor:raylib"
import sdl "vendor:sdl2"

BUTTON_WIDTH :: 180
BUTTON_HEIGHT :: 30

fd_file_path :: proc() -> string {
    files := rl.LoadDirectoryFiles(rl.GetWorkingDirectory());

    for i in 0..<files.count {
        fmt.println(files.paths[i]);
    }

    window := sdl_create_window(500, 500, "Files");
    sdl_window(window, sdl_create_renderer(window), nil, proc(renderer: ^sdl.Renderer) {
        sdl.SetRenderDrawColor(renderer, 0, 255, 0, 255);
        sdl.RenderClear(renderer);
    });

    return "";
}

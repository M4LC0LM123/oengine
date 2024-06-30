package oengine

import "core:fmt"
import "core:path/filepath"
import rl "vendor:raylib" 

BUTTON_WIDTH :: 180
BUTTON_HEIGHT :: 30

fd_file_path :: proc() -> string {
    files := rl.LoadDirectoryFiles(rl.GetWorkingDirectory());

    for i in 0..<files.count {
        fmt.println(files.paths[i]);
    }

    return "";
}

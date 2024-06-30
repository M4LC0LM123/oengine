package oengine

import "core:fmt"
import "core:os"
import rl "vendor:raylib" 

fd_file_path :: proc() -> string {
    files := rl.LoadDirectoryFiles(rl.GetWorkingDirectory());

    for i in 0..<files.count {
        fmt.println(files.paths[i]);
    }

    return "";
}

package oengine

import "core:fmt"
import "core:os"
import strs "core:strings"

/* simple example

file := oe.file_handle("../assets/test.od");
oe.file_write(file, "WRITTEN THIS:0");

data := oe.file_to_string_arr("../assets/test.od");

for line in data {
    fmt.println(line);
}

*/

File :: struct {
    handle: os.Handle,
    size: u32,
}

file_to_string_arr :: proc(path: string) -> []string {
    data, ok := os.read_entire_file(path);
    if (!ok) {
        dbg_log(str_add({"Failed to read file ", path}), .WARNING);
        return {};
    }
    defer delete(data);

    str_data, ok2 := strs.split_lines(string(data));
    return str_data;
}

FileMode :: enum {
    READ_DONLY      = 0x00000,
    WRITE_RONLY     = 0x00001,
    READ_AND_WRITE  = 0x00002,
    CREATE          = 0x00040,
    EXCL            = 0x00080,
    NOCTTY          = 0x00100,
    TRUNC           = 0x00200,
    NONBLOCK        = 0x00800,
    APPEND          = 0x00400,
    SYNC            = 0x01000,
    ASYNC           = 0x02000,
    CLOEXEC         = 0x80000,
}

file_handle :: proc(path: string, mode: FileMode = .READ_AND_WRITE | .APPEND | .CREATE) -> File {
    handle, ok := os.open(path, int(mode));
    if (ok != 0) {
        dbg_log(str_add({"Failed to open file ", path}), .WARNING);
        return {};
    }
    
    return File {
        handle = handle,
        size = u32(len(file_to_string_arr(path))),
    };
}

file_write :: proc(file: File, text: string) {
    n, err := os.write_string(file.handle, str_add({"\n", text}));

    if (err != 0) {
        dbg_log(str_add("Failed to write to file: ", err), .WARNING);
    }
}

file_close :: proc(file: File) {
    err := os.close(file.handle);

    if (bool(err) != false) {
        dbg_log(str_add("Failed to close file: ", err), .WARNING);
    }
}
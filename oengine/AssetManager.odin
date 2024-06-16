package oengine

import "core:fmt"
import "core:encoding/json"
import "core:io"
import "core:os"
import strs "core:strings"

Asset :: union {
    Texture,
    Model,
    Shader,
    CubeMap,
}

asset_manager: struct {
    registry: map[string]Asset,
}

save_registry :: proc(path: string) {
    using asset_manager;
    mode := FileMode.WRITE_RONLY | FileMode.CREATE;
    file := file_handle(path, mode);

    res := "{";

    for tag, asset in registry {
        #partial switch var in asset {
            case Texture:
                res = str_add({res, "\n   \"", tag, "\": ", "\"", var.path, "\""});
            case Model:
                res = str_add({res, "\n   \"", tag, "\": ", "\"", var.path, "\""});
        }
    }

    res = str_add(res, "\n}");
    file_write(file, res);
    file_close(file);
}

load_registry :: proc(path: string) {
    data, ok := os.read_entire_file_from_filename(path);
    if (!ok) {
        dbg_log("Failed to open file ", DebugType.WARNING);
        return;
    }
    defer delete(data);

    json_data, err := json.parse(data);
    if (err != json.Error.None) {
		dbg_log("Failed to parse the json file", DebugType.WARNING);
		dbg_log(str_add("Error: ", err), DebugType.WARNING);
		return;
	}
	defer json.destroy_value(json_data);

    root := json_data.(json.Object);

    for tag, asset_path in root {
        fmt.println(tag, asset_path);
    }
}

asset_variant :: proc(self: Asset, $T: typeid) -> T {
    return self.(T);
}

reg_asset :: proc(tag: string, asset: Asset) {
    using asset_manager;
    registry[tag] = asset;
}

get_asset :: proc(tag: string) -> Asset {
    using asset_manager;
    
    if (registry[tag] == nil) {
        dbg_log(str_add({"Asset ", tag, " doesn\'t exist"}), DebugType.WARNING);
        return nil;
    }

    return registry[tag];
}

get_asset_var :: proc(tag: string, $T: typeid) -> T {
    using asset_manager;
    
    if (registry[tag] == nil) {
        dbg_log(str_add({"Asset ", tag, " doesn\'t exist"}), DebugType.WARNING);
    }

    return asset_variant(registry[tag], T);
}

asset_exists :: proc(tag: string) -> bool {
    return asset_manager.registry[tag] != nil;
}

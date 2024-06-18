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
                res = str_add(
                    {res, "\n\t\"", strs.clone(tag), "\": {\n", 
                        "\t\t\"path\": \"", strs.clone(var.path), "\",\n",
                        "\t\t\"type\": \"", "Texture", "\"",
                    "\n\t},"}
                );
            case Model:
                res = str_add(
                    {res, "\n\t\"", strs.clone(tag), "\": {\n", 
                        "\t\t\"path\": \"", var.path, "\",\n",
                        "\t\t\"type\": \"", "Model", "\"",
                    "\n\t},"}
                );
            case CubeMap:
                res = str_add(
                    {res, "\n\t\"", strs.clone(tag), "\": {\n",
                        "\t\t\"type\": \"", "CubeMap", "\",\n",
                        "\t\t\"path_front\": \"", strs.clone(var[0].path), "\",\n",
                        "\t\t\"path_back\": \"", strs.clone(var[1].path), "\",\n",
                        "\t\t\"path_left\": \"", strs.clone(var[2].path), "\",\n",
                        "\t\t\"path_right\": \"", strs.clone(var[3].path), "\",\n",
                        "\t\t\"path_top\": \"", strs.clone(var[4].path), "\",\n",
                        "\t\t\"path_bottom\": \"", strs.clone(var[5].path), "\"",
                    "\n\t},"}
                );
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

    json_data, err := json.parse(data);
    if (err != json.Error.None) {
		dbg_log("Failed to parse the json file", DebugType.WARNING);
		dbg_log(str_add("Error: ", err), DebugType.WARNING);
		return;
	}

    root := json_data.(json.Object);

    for tag, asset in root {
        asset_json := asset.(json.Object);
        type := asset_json["type"].(json.String);

        if (type == "CubeMap") {
            front := asset_json["path_front"].(json.String);
            back := asset_json["path_back"].(json.String);
            left := asset_json["path_left"].(json.String);
            right := asset_json["path_right"].(json.String);
            top := asset_json["path_top"].(json.String);
            bottom := asset_json["path_bottom"].(json.String);

            reg_asset(strs.clone(tag), SkyBox {
                load_texture(strs.clone(front)), load_texture(strs.clone(back)),
                load_texture(strs.clone(left)), load_texture(strs.clone(right)),
                load_texture(strs.clone(top)), load_texture(strs.clone(bottom)),
            });
        } else {
            path := asset_json["path"].(json.String);

            if (type == "Texture") {
                reg_asset(strs.clone(tag), load_texture(strs.clone(path)));
            } else if (type == "Model") {
                reg_asset(strs.clone(tag), load_model(strs.clone(path)));
            }
        }
    }

    delete(data);
    json.destroy_value(json_data);
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

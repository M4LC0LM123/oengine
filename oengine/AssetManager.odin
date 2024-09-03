package oengine

import "core:fmt"
import "core:encoding/json"
import "core:io"
import "core:os"
import "core:path/filepath"
import sc "core:strconv"
import strs "core:strings"
import rl "vendor:raylib"

DataID :: struct {
    tag: string,
    id: u32,
    transform: Transform,
}

Asset :: union {
    Texture,
    Model,
    Shader,
    CubeMap,
    Sound,
    DataID,
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
            case Sound:
                res = str_add(
                    {res, "\n\t\"", strs.clone(tag), "\": {\n", 
                        "\t\t\"path\": \"", strs.clone(var.path), "\",\n",
                        "\t\t\"volume\": \"", strs.clone(str_add("", var.volume)), "\",\n",
                        "\t\t\"type\": \"", "Sound", "\"",
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
            front := get_path(asset_json["path_front"].(json.String));
            back := get_path(asset_json["path_back"].(json.String));
            left := get_path(asset_json["path_left"].(json.String));
            right := get_path(asset_json["path_right"].(json.String));
            top := get_path(asset_json["path_top"].(json.String));
            bottom := get_path(asset_json["path_bottom"].(json.String));

            reg_asset(strs.clone(tag), SkyBox {
                load_texture(strs.clone(front)), load_texture(strs.clone(back)),
                load_texture(strs.clone(left)), load_texture(strs.clone(right)),
                load_texture(strs.clone(top)), load_texture(strs.clone(bottom)),
            });
        } else if (type == "Sound") {
            path := get_path(asset_json["path"].(json.String));
            vol, ok := sc.parse_f32(asset_json["path"].(json.String));
            res := load_sound(strs.clone(path));
            if (ok) do set_sound_vol(&res, vol);
            
            reg_asset(strs.clone(tag), res);
        } else {
            res := get_path(asset_json["path"].(json.String));

            if (type == "Texture") {
                reg_asset(strs.clone(tag), load_texture(strs.clone(res)));
            } else if (type == "Model") {
                reg_asset(strs.clone(tag), load_model(strs.clone(res)));
            }
        }
    }

    delete(data);
    json.destroy_value(json_data);
}

@(private)
get_path :: proc(path: string) -> string {
    absolute, ok := filepath.abs(path);
    res, err := filepath.rel(string(rl.GetWorkingDirectory()), absolute);
    t: bool;
    res, t = strs.replace_all(res, "\\", "/");
    return res;
}

get_reg_data_ids :: proc() -> [dynamic]DataID {
    using asset_manager;

    res := make([dynamic]DataID);

    for tag, asset in registry {
        if (asset_is(asset, DataID)) {
            append(&res, asset_variant(asset, DataID));
        }
    }

    return res;
}

get_reg_textures :: proc() -> map[string]Texture {
    using asset_manager;

    res := make(map[string]Texture);

    for tag, asset in registry {
        if (asset_is(asset, Texture)) {
            res[tag] = asset_variant(asset, Texture);
        }
    }

    return res;
}

get_reg_textures_tags :: proc() -> [dynamic]string {
    using asset_manager;

    res := make([dynamic]string);

    for tag, asset in registry {
        if (asset_is(asset, Texture)) {
            append(&res, tag);
        }
    }

    return res;
}

asset_variant :: proc(self: Asset, $T: typeid) -> T {
    return self.(T);
}

asset_is :: proc(self: Asset, $T: typeid) -> bool {
    #partial switch v in self {
        case T: return true;
    }

    return false;
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

deinit_assets :: proc() {
    using asset_manager;
    for i, v in registry {
        if (asset_is(v, Texture)) do deinit_texture(get_asset_var(i, Texture));
        else if (asset_is(v, Model)) do deinit_model(get_asset_var(i, Model));
        else if (asset_is(v, Shader)) do deinit_shader(get_asset_var(i, Shader));
        else if (asset_is(v, CubeMap)) do deinit_cubemap(get_asset_var(i, CubeMap));
        else if (asset_is(v, Sound)) do deinit_sound(get_asset_var(i, Sound));
    }
}

package oengine

import "core:fmt"
import "core:encoding/json"
import "core:io"
import "core:os"
import "core:path/filepath"
import sc "core:strconv"
import strs "core:strings"
import rl "vendor:raylib"
import "fa"

MAX_DIDS :: 2048
MAX_TEXTURES :: 2048

ComponentMarshall :: struct {
    tag, type: string
}

DataID :: struct {
    reg_tag: string, // tag registerd in registry
    tag: string,
    id: u32,
    transform: Transform,
    flags: fa.FixedArray(u32, 16),
    comps: fa.FixedArray(ComponentMarshall, 16),
}

Asset :: union {
    Texture,
    Model,
    Shader,
    CubeMap,
    Sound,
    DataID,
}

LoadInstruction :: #type proc(asset_json: json.Object) -> rawptr
LoaderFunc :: #type proc(ent: AEntity, tag: string)

ComponentParse :: struct {
    name: string,
    instr: LoadInstruction
}

ComponentType :: struct {
    name: string,
    type: typeid,
}

asset_manager: struct {
    registry: map[string]Asset,
    component_types: map[ComponentParse]typeid,
    component_loaders: map[string]LoaderFunc,
    component_reg: map[ComponentType]rawptr,
}

reg_component :: proc(
    t: typeid, 
    instr: LoadInstruction = nil, 
    loader: LoaderFunc = nil
) {
    using asset_manager;
    tag := fmt.aprintf("%v", t);

    component_types[{tag, instr}] = t;
    component_loaders[tag] = loader;
}

get_component_type :: proc(s: string) -> typeid {
    using asset_manager;
    for k, v in component_types {
        if (k.name == s) do return v;
    }

    return nil;
}

get_component_instr :: proc(s: string) -> LoadInstruction {
    using asset_manager;
    for k, v in component_types {
        if (k.name == s) do return k.instr;
    }

    return nil;
}

get_component_data :: proc(s: string, $T: typeid) -> ^T {
    comp := cast(^T)asset_manager.component_reg[{s, T}];
    return new_clone(comp^);
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

    // first load assets
    for tag, asset in root {
        if (tag == "dbg_pos") {
            val := i32(asset.(json.Float));
            window._dbg_stats_pos = val;
            continue;
        } else if (tag == "exe_path") {
            val := asset.(json.String);
            epath: string;
            s_id, e_id: i32;
            semi0, semi1: i32 = -1, -1;

            for i in 0..<len(val) {
                c := val[i];
                if (c == '{') {
                    s_id = auto_cast i;
                } else if (c == '}') {
                    e_id = auto_cast i;
                } else if (c == ';') {
                    if (semi0 == -1) {
                        semi0 = auto_cast i;
                    } else {
                        semi1 = auto_cast i;
                    }
                }
            }

            epath = val[:s_id];
            
            plat: string;
            if (sys_os() == .Windows) {
                plat = val[s_id + 1:semi0]; 
            } else if (sys_os() == .Linux) {
                plat = val[semi0 + 1:semi1];
            } else if (sys_os() == .Darwin) {
                plat = val[semi1 + 1:e_id];
            }
            epath = str_add(epath, plat);
            epath = str_add(epath, val[e_id + 1:]);

            window._exe_path = strs.clone(epath);

            continue;
        }

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
        } else if (type == "Texture") {
            res := get_path(asset_json["path"].(json.String));

            tex := load_texture(strs.clone(res));
            reg_asset(strs.clone(tag), tex);
        } else if (type == "Model") {
            res := get_path(asset_json["path"].(json.String));
            reg_asset(strs.clone(tag), load_model(strs.clone(res)));
        }
    }

    // then load components
    for tag, asset in root {
        if (tag == "dbg_pos" || tag == "exe_path") { continue; }

        asset_json := asset.(json.Object);
        type := asset_json["type"].(json.String);

        if (type == "CubeMap" ||
            type == "Sound" ||
            type == "Texture" ||
            type == "Model") { continue; }

        ct := ComponentType {
            name = strs.clone(tag),
            type = get_component_type(type),
        };

        instr := get_component_instr(type);
        if (instr != nil) {
            asset_manager.component_reg[ct] = instr(asset_json);
        } else {
            dbg_log("Parse instructions are nil", .ERROR);
        }
    }

    delete(data);
    json.destroy_value(json_data);
}

reload_assets :: proc() {
    using asset_manager;

    for tag, &asset in registry {
        if (asset_has_path(asset)) {
            load_asset(&asset);
        }
    }
}

am_texture_atlas :: proc() -> Atlas {
    res := init_atlas();
    textures := get_reg_textures_arr();

    width: i32;
    height: i32;

    for i in 0..<len(textures) {
        tex := textures[i];
        width += tex.width;
        height += tex.height;
    }

    res.width = width;
    res.height = height;

    target := rl.LoadRenderTexture(width, height);
    rl.BeginTextureMode(target);
    rl.ClearBackground(BLANK);

    free_rects := make([dynamic]Rect);
    append(&free_rects, Rect{0, 0, f32(width), f32(height)});

    for i in 0..<len(textures) {
        tex := textures[i];

        best_rect := find_best_fit_rect(&free_rects, tex.width, tex.height);
        if (best_rect.width == 0 || best_rect.height == 0) {
            break; // No space left
        }

        rect := Rect{best_rect.x, best_rect.y, f32(tex.width), f32(tex.height)};
        atlas_texture(&res, rect, tex.tag, true);

        rl.DrawTexturePro(
            tex,
            {0, 0, f32(tex.width), f32(tex.height)},
            {rect.x, rect.y, rect.width, rect.height},
            {}, 0, WHITE
        );

        split_free_space(&free_rects, rect);
    }

    rl.EndTextureMode();
    res.texture = tex_flip_vert(load_texture(target.texture));
    return res;
}

@(private)
asset_has_path :: proc(asset: Asset) -> bool {
    if (!asset_is(asset, DataID)) {
        return true;
    }

    return false;
}

load_asset :: proc(asset: ^Asset) {
    #partial switch &v in asset {
        case Texture:
            v = load_texture(v.path);
            dbg_log(str_add("Loading texture: ", v.path));
        case Model:
            v = load_model(v.path);
            dbg_log(str_add("Loading model: ", v.path));
        case Shader:
            v = load_shader(v.v_path, v.f_path);
            dbg_log(str_add("Loading shader: ", v.v_path));
            dbg_log(str_add("Loading shader: ", v.f_path));
        case CubeMap:
            for &i in v {
                i = load_texture(i.path);
                dbg_log(str_add("Loading cubemap texture: ", i.path));
            }
        case Sound:
            v = load_sound(v.path);
            dbg_log(str_add("Loading sound: ", v.path));
    }
}

get_asset_type :: proc(asset: Asset) -> $T {
    #partial switch v in asset {
        case Texture:
            return asset.(Texture);
        case Model:
            return asset.(Model);
        case Shader:
            return asset.(Shader);
        case CubeMap:
            return asset.(CubeMap);
        case Sound:
            return asset.(Sound);
        case DataID:
            return asset.(DataID);
    }

    return nil;
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

get_reg_textures :: proc() -> fa.FixedMap(string, Texture, MAX_TEXTURES) {
    using asset_manager;

    res := fa.fixed_map(string, Texture, MAX_TEXTURES);

    for tag, asset in registry {
        if (asset_is(asset, Texture)) {
            fa.map_set(&res, tag, asset_variant(asset, Texture));
        }
    }

    return res;
}

TextureTag :: struct {
    using handle: Texture,
    tag: string,
}

get_reg_textures_arr :: proc() -> [dynamic]TextureTag {
    using asset_manager;

    res := make([dynamic]TextureTag);

    for tag, asset in registry {
        if (asset_is(asset, Texture)) {
            append(&res, TextureTag{asset_variant(asset, Texture), tag});
        }
    }

    return res;
}

get_reg_textures_tags :: proc() -> fa.FixedArray(string, MAX_TEXTURES) {
    using asset_manager;

    res := fa.fixed_array(string, MAX_TEXTURES);

    for tag, asset in registry {
        if (asset_is(asset, Texture)) {
            fa.append(&res, tag);
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

unreg_asset :: proc(tag: string) {
    using asset_manager;
    registry[tag] = nil;
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

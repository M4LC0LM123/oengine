package main

import "core:fmt"
import rl "vendor:raylib"
import sdl "vendor:sdl2"
import oe "../../oengine"
import "../../oengine/fa"
import "core:math"
import "core:path/filepath"
import sc "core:strconv"
import strs "core:strings"

BUTTON_WIDTH :: 180
WINDOW_HEIGHT :: 250

registry_tool :: proc(ct: CameraTool) {
    oe.gui_begin("Registry", x = 0, y = 0, h = WINDOW_HEIGHT, can_exit = false);
    wr := oe.gui_rect(oe.gui_window("Registry"));

    grid := oe.gui_grid(0, 0, 40, wr.width * 0.75, 10);

    root := strs.clone_from_cstring(rl.GetWorkingDirectory());
    @static dir: string;
    if (oe.gui_button("Set exe dir", grid.x, grid.y, grid.width, grid.height)) {
        dir = oe.nfd_folder();
        rl.ChangeDirectory(strs.clone_to_cstring(dir));
    }

    grid = oe.gui_grid(1, 0, 40, wr.width * 0.75, 10);
    oe.gui_text(dir, 20, grid.x, grid.y);

    grid = oe.gui_grid(2, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Load registry", grid.x, grid.y, grid.width, grid.height)) {
        path := oe.nfd_file();
        if (filepath.ext(path) == ".json") {
            oe.load_registry(path);
            globals.registry_atlas = oe.am_texture_atlas();
        }
        rl.ChangeDirectory(oe.to_cstr(root));
    }

    grid = oe.gui_grid(3, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Load atlas", grid.x, grid.y, grid.width, grid.height)) {
        path := oe.nfd_folder();
        globals.registry_atlas = oe.load_atlas(path);
    }

    grid = oe.gui_grid(4, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Load config", grid.x, grid.y, grid.width, grid.height)) {
        path := oe.nfd_file();
        if (filepath.ext(path) == ".oecfg") {
            paths := load_config(path);

            if (paths[0] != oe.STR_EMPTY) {
                rl.ChangeDirectory(strs.clone_to_cstring(paths[0]));
            }
            if (paths[1] != oe.STR_EMPTY) {
                if (filepath.ext(paths[1]) == ".json") {
                    oe.load_registry(paths[1]);
                    globals.registry_atlas = oe.am_texture_atlas();
                }
                rl.ChangeDirectory(oe.to_cstr(root));
            }
            if (paths[2] != oe.STR_EMPTY) {
                globals.registry_atlas = oe.load_atlas(paths[2]);
            }
        }
    }

    oe.gui_end();
}

msc_tool :: proc(ct: CameraTool) {
    oe.gui_begin("MSC tool", x = 0, y = WINDOW_HEIGHT + oe.gui_top_bar_height, h = WINDOW_HEIGHT, can_exit = false);
    wr := oe.gui_rect(oe.gui_window("MSC tool"));

    @static new_instance: bool = false;
    // new_instance = oe.gui_tick(new_instance, 10, 10, 30, 30);
    //
    // oe.gui_text("New instance", 20, 50, 10);

    grid := oe.gui_grid(0, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Triangle plane", grid.x, grid.y, grid.width, grid.height)) {
        msc := msc_check(new_instance);

        oe.msc_append_tri(
            msc, {}, {1, 0, 0}, {0, 1, 0}, 
            msc_target_pos(ct), 
            normal = oe.surface_normal({{}, {1, 0, 0}, {0, 1, 0}}));
    }

    grid = oe.gui_grid(1, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Plane", grid.x, grid.y, grid.width, grid.height)) {
        msc := msc_check(new_instance);

        oe.msc_append_quad(msc, {}, {1, 0, 0}, {0, 1, 0}, {1, 1, 0}, msc_target_pos(ct));
    }

    grid = oe.gui_grid(2, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Cuboid", grid.x, grid.y, grid.width, grid.height)) {
        msc := msc_check(new_instance);
       
        msc_cuboid(msc, msc_target_pos(ct));
    }

    grid = oe.gui_grid(3, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Recalc aabbs", grid.x, grid.y, grid.width, grid.height)) {
        for i in 0..<oe.ecs_world.physics.mscs.len {
            msc := oe.ecs_world.physics.mscs.data[i];
            msc._aabb = oe.tris_to_aabb(msc.tris);
        }
    }

    grid = oe.gui_grid(4, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Clear", grid.x, grid.y, grid.width, grid.height)) {
        fa.clear(&oe.ecs_world.physics.mscs);
    }

    oe.gui_end();
}

map_proj_tool :: proc(ct: CameraTool) {
    oe.gui_begin(
        "Map project", 
        x = 0, y = WINDOW_HEIGHT * 2 + oe.gui_top_bar_height * 2, 
        h = WINDOW_HEIGHT, can_exit = false);
    wr := oe.gui_rect(oe.gui_window("Map project"));

    grid := oe.gui_grid(0, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Load msc", grid.x, grid.y, grid.width, grid.height)) {
        path := oe.nfd_file();
        if (filepath.ext(path) == ".json") {
            msc := oe.msc_init();
            oe.msc_from_json(msc, path);
        } else if (filepath.ext(path) == ".obj") {
            msc := oe.msc_init();
            oe.msc_from_model(msc, oe.load_model(path));
        }
    }

    grid = oe.gui_grid(1, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Save msc", grid.x, grid.y, grid.width, grid.height)) {
        path := oe.nfd_file();
        if (path != oe.STR_EMPTY) {
            oe.msc_to_json(oe.ecs_world.physics.mscs.data[0], path);

            if (oe.ecs_world.physics.mscs.len == 0) {
                oe.load_data_ids(path);
            }
        }
    }

    grid = oe.gui_grid(2, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Clear", grid.x, grid.y, grid.width, grid.height)) {
        fa.clear(&oe.ecs_world.physics.mscs);

        dids := oe.get_reg_data_ids();
        defer delete(dids);
        for did in dids {
            oe.unreg_asset(did.reg_tag);
        }
    }

    grid = oe.gui_grid(3, 1, 40, wr.width * 0.5, 10);
    @static map_name: string;
    map_name = oe.gui_text_box(
        "map_name_input", 
        grid.x, grid.y, grid.width, grid.height);

    grid = oe.gui_grid(3, 0, 40, wr.width * 0.5, 10);
    if (oe.gui_button("Save map", grid.x, grid.y, grid.width, grid.height)) {
        path := oe.nfd_folder();
        oe.save_map(map_name, path);
    }

    grid = oe.gui_grid(4, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Load map", grid.x, grid.y, grid.width, grid.height)) {
        path := oe.nfd_folder();
        oe.load_map(path, globals.registry_atlas);
    }

    oe.gui_end();
}

texture_tool :: proc(ct: CameraTool) {
    if (ct._active_msc_id == ACTIVE_EMPTY || ct._active_id == ACTIVE_EMPTY) do return;

    oe.gui_begin("Texture tool", 
        x = 0, y = WINDOW_HEIGHT * 3 + 10 + oe.gui_top_bar_height * 3, 
        h = WINDOW_HEIGHT, active = false);

    texs := oe.get_reg_textures_tags();

    @static rot: i32;
    if (oe.gui_button("R", oe.gui_window("Texture tool").width - 40, 10, 30, 30)) {
        rot += 1;
        if (rot > 3) do rot = 0;

        active := oe.ecs_world.physics.mscs.data[ct._active_msc_id].tris[ct._active_id];
        oe.tri_recalc_uvs(active, rot);
    }

    t := oe.gui_text_box("TilingTextBox", oe.gui_window("Texture tool").width - 40, 50, 30, 30);
    @static tiling: int; ok: bool;
    tiling, ok = sc.parse_int(t);
    if (oe.gui_button("OK", oe.gui_window("Texture tool").width - 40, 90, 30, 30)) {
        active := oe.ecs_world.physics.mscs.data[ct._active_msc_id].tris[ct._active_id];

        tag := oe.str_add(active.texture_tag, oe.str_add("_tiling_", tiling));
        oe.reg_asset(
            tag,
            oe.tile_texture(oe.get_asset_var(active.texture_tag, oe.Texture), i32(tiling))
        );

        active.texture_tag = tag;
        oe.gui.text_boxes["TilingTextBox"].text = "";
    }

    if (oe.gui_button("FLIP", oe.gui_window("Texture tool").width - 40, 130, 30, 30)) {
        active := oe.ecs_world.physics.mscs.data[ct._active_msc_id].tris[ct._active_id];
        active.flipped = !active.flipped;
        active.normal = -active.normal;
    }

    COLS :: 6
    rows := i32(math.ceil(f32(texs.len) / f32(COLS)));
    w: f32 = 30;
    h: f32 = 30;

    for row: i32; row < rows; row += 1 {
        for col: i32; col < COLS; col += 1 {
            curr_id := row * COLS + col;

            if (curr_id < i32(texs.len)) {
                x := 10 + f32(col) * (w + 5);
                y := 10 + f32(row) * (h + 5);
                tag := texs.data[curr_id];

                if (oe.gui_button(
                    tag, x, y, w, h, 
                    texture = oe.get_asset_var(tag, oe.Texture)
                    )) {
                    active := oe.ecs_world.physics.mscs.data[ct._active_msc_id].tris[ct._active_id];
                    active.texture_tag = tag;
                }
            }
        }
    }

    oe.gui_end();
}

data_id_tool :: proc(ct: CameraTool) {
    oe.gui_begin("DataID tool", x = f32(oe.w_render_width()) - 300, y = 0, can_exit = false);
    wr := oe.gui_rect(oe.gui_window("DataID tool"));

    @static tag: string;
    @static id: u32;
    grid := oe.gui_grid(0, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Add dataID", grid.x, grid.y, grid.width, grid.height)) {
        if (tag == "") do tag = "default";

        reg_tag := oe.str_add("data_id_", tag);
        if (oe.asset_manager.registry[reg_tag] != nil) {
            reg_tag = oe.str_add(reg_tag, oe.rand_digits(4));
        }

        oe.reg_asset(
            reg_tag, 
            oe.DataID {
                reg_tag, 
                tag, 
                id, 
                oe.Transform{msc_target_pos(ct), {}, oe.vec3_one()},
                fa.fixed_array(oe.ComponentMarshall, 16),
            }
        );
        oe.dbg_log(oe.str_add({"Added data id of tag: ", tag, " and id: ", oe.str_add("", id)}));
    }

    grid = oe.gui_grid(1, 0, 40, wr.width * 0.75, 10);
    tag = oe.gui_text_box("TagTextBox", grid.x, grid.y, grid.width, grid.height);
    grid = oe.gui_grid(1, 1, 40, wr.width * 0.75, 10);
    oe.gui_text("Tag", 25, grid.x, grid.y);

    grid = oe.gui_grid(2, 0, 40, wr.width * 0.75, 10);
    id_parse := oe.gui_text_box("IDTextBox", grid.x, grid.y, grid.width, grid.height);
    grid = oe.gui_grid(2, 1, 40, wr.width * 0.75, 10);
    oe.gui_text("ID", 25, grid.x, grid.y);

    grid = oe.gui_grid(3, 0, 40, wr.width * 0.75, 10);
    if (oe.gui_button("Clear", grid.x, grid.y, grid.width, grid.height)) {
        dids := oe.get_reg_data_ids();
        defer delete(dids);
        for did in dids {
            oe.unreg_asset(did.reg_tag);
        }
    }

    parsed, ok := sc.parse_int(id_parse);
    if (ok) do id = u32(parsed);

    oe.gui_end();
}

data_id_mod_tool :: proc(ct: CameraTool) {
    oe.gui_begin("DataID modifier", 
        x = f32(oe.w_render_width()) - 300, 
        y = 200 + oe.gui_top_bar_height,
        h = 400,
        active = false
    );

    @static tag: string;
    @static id: u32;
    if (oe.gui_button("Modify", 10, 10, BUTTON_WIDTH, 30)) {
        if (tag == "") do tag = "default";

        reg_tag := oe.str_add("data_id_", tag);
        if (oe.asset_manager.registry[reg_tag] != nil) {
            reg_tag = oe.str_add(reg_tag, oe.rand_digits(4));
        }

        t := oe.get_asset_var(editor_data.active_data_id, oe.DataID).transform;

        // actually just reregistering
        oe.unreg_asset(editor_data.active_data_id);

        editor_data.active_data_id = reg_tag;

        oe.reg_asset(reg_tag, 
            oe.DataID {
                reg_tag, 
                tag, 
                id, 
                t,
                fa.fixed_array(oe.ComponentMarshall, 16),
            }
        );
        oe.dbg_log(oe.str_add({"Modified data id of tag: ", tag, " and id: ", oe.str_add("", id)}));
    }

    tag = oe.gui_text_box("ModTagTextBox", 10, 50, BUTTON_WIDTH, 30);
    oe.gui_text("Tag", 25, BUTTON_WIDTH + 20, 50);

    id_parse := oe.gui_text_box("ModIDTextBox", 10, 90, BUTTON_WIDTH, 30);
    oe.gui_text("ID", 25, BUTTON_WIDTH + 20, 90);

    parsed, ok := sc.parse_int(id_parse);
    if (ok) do id = u32(parsed);

    if (oe.gui_button("Components", 10, 130, BUTTON_WIDTH, 30)) {
        oe.gui.windows["Add components"].active = true;
    }

    if (editor_data.active_data_id != "") {
        did := oe.get_asset_var(editor_data.active_data_id, oe.DataID);
        for i in 0..<did.comps.len {
            t := oe.str_add({
                did.comps.data[i].tag,
                ": ",
                did.comps.data[i].type
            });

            oe.gui_text(t, 25, 10, 170 + f32(i) * 25);
        }
    }

    oe.gui_end();
}

did_component_tool :: proc(ct: CameraTool) {
    oe.gui_begin("Add components", 
        x = f32(oe.w_render_width()) - 300, 
        y = 600 + oe.gui_top_bar_height * 2, active = false,
        h = 400,
    );

    i: i32;
    for k, v in oe.asset_manager.component_reg {
        if (oe.gui_button(
            k.name,
            x = 10,
            y = 10 + f32(i) * 40,
            w = BUTTON_WIDTH,
            h = 30,
        )) {
            tag := editor_data.active_data_id;
            did := oe.get_asset_var(tag, oe.DataID);
            fa.append(
                &did.comps, 
                oe.ComponentMarshall {k.name, oe.str_add("", k.type)}
            );

            oe.unreg_asset(did.reg_tag);
            oe.reg_asset(did.reg_tag, did);
            oe.dbg_log(
                oe.str_add({
                    "Modified data id of tag: ", 
                    tag, " and id: ", oe.str_add("", did.id)
                })
            );
        }

        i += 1;
    }

    oe.gui_end();
}

@(private = "file")
msc_target_pos :: proc(ct: CameraTool) -> oe.Vec3 {
    if (ct.mode == .PERSPECTIVE) do return ct.camera_perspective.position;

    snapped_x: f32 = math.round(ct.camera_orthographic.target.x / GRID_SPACING) * GRID_SPACING;
    snapped_y: f32 = -math.round(ct.camera_orthographic.target.y / GRID_SPACING) * GRID_SPACING;

    #partial switch ct.mode {
        case .ORTHO_XY:
            return {
                snapped_x / RENDER_SCALAR, 
                snapped_y / RENDER_SCALAR, 0};
        case .ORTHO_XZ:
            return {
                snapped_x / RENDER_SCALAR, 0, 
                snapped_y / RENDER_SCALAR};
        case .ORTHO_ZY:
            return { 0,
                snapped_x / RENDER_SCALAR, 
                snapped_y / RENDER_SCALAR};
    }

    return {};
}

@(private = "file")
load_config :: proc(path: string) -> [3]string {
    content := oe.file_to_string_arr(path);
    res: [3]string;

    for i in 0..<len(content) {
        s, _ := strs.remove_all(content[i], " ");
        sides, _ := strs.split(s, "=");
        left := sides[0];
        right := sides[1];
        absolute, _ := filepath.abs(right);
        absolute, _ = strs.replace_all(absolute, "\\", "/");

        switch left {
            case "exe_path":
                res[0] = absolute;
            case "reg_path":
                res[1] = absolute;
            case "atlas_path":
                res[2] = absolute;
        }
    }

    return res;
}

@(private = "file")
msc_check :: proc(new_instance: bool) -> ^oe.MSCObject {
    msc: ^oe.MSCObject;
    if (new_instance) {
        msc = oe.msc_init();
    } else {
        if (oe.ecs_world.physics.mscs.len > 0) {
            msc = oe.ecs_world.physics.mscs.data[oe.ecs_world.physics.mscs.len - 1];
        } else {
            msc = oe.msc_init();
        }
    }

    return msc;
}

@(private)
msc_cuboid :: proc(msc: ^oe.MSCObject, target: oe.Vec3) {
    // front
    oe.msc_append_quad(msc, 
        {-0.5, -0.5, -0.5}, 
        {0.5, -0.5, -0.5}, 
        {-0.5, 0.5, -0.5}, 
        {0.5, 0.5, -0.5}, 
    target);

    // back
    oe.msc_append_quad(msc, 
        {-0.5, -0.5, 0.5}, 
        {0.5, -0.5, 0.5}, 
        {-0.5, 0.5, 0.5}, 
        {0.5, 0.5, 0.5}, 
    target);

    // left
    oe.msc_append_quad(msc, 
        {-0.5, -0.5, -0.5}, 
        {-0.5, -0.5, 0.5}, 
        {-0.5, 0.5, -0.5}, 
        {-0.5, 0.5, 0.5}, 
    target);

    // right
    oe.msc_append_quad(msc, 
        {0.5, -0.5, -0.5}, 
        {0.5, -0.5, 0.5}, 
        {0.5, 0.5, -0.5}, 
        {0.5, 0.5, 0.5}, 
    target);

    // top
    oe.msc_append_quad(msc, 
        {-0.5, 0.5, -0.5}, 
        {0.5, 0.5, -0.5}, 
        {-0.5, 0.5, 0.5}, 
        {0.5, 0.5, 0.5}, 
    target);

    // bottom
    oe.msc_append_quad(msc, 
        {-0.5, -0.5, -0.5}, 
        {0.5, -0.5, -0.5}, 
        {-0.5, -0.5, 0.5}, 
        {0.5, -0.5, 0.5}, 
    target);
}

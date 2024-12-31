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

registry_tool :: proc(ct: CameraTool) {
    oe.gui_begin("Registry", x = 0, y = 0, h = 150, can_exit = false);

    root := strs.clone_from_cstring(rl.GetWorkingDirectory());
    @static dir: string;
    if (oe.gui_button("Set asset dir", 10, 10, BUTTON_WIDTH, 30)) {
        dir = oe.fd_dir();
        rl.ChangeDirectory(strs.clone_to_cstring(dir));
    }

    oe.gui_text(dir, 20, 10, 50);

    if (oe.gui_button("Load registry", 10, 100, BUTTON_WIDTH, 30)) {
        path := oe.fd_file_path();
        if (filepath.ext(path) == ".json") {
            oe.load_registry(path);
        }
        rl.ChangeDirectory(strs.clone_to_cstring(root));
    }

    oe.gui_end();
}

msc_tool :: proc(ct: CameraTool) {
    oe.gui_begin("MSC tool", x = 0, y = 150 + oe.gui_top_bar_height, h = 210, can_exit = false);

    @static new_instance: bool = false;
    // new_instance = oe.gui_tick(new_instance, 10, 10, 30, 30);
    //
    // oe.gui_text("New instance", 20, 50, 10);

    if (oe.gui_button("Triangle plane", 10, 10, BUTTON_WIDTH, 30)) {
        msc := msc_check(new_instance);

        oe.msc_append_tri(msc, {}, {1, 0, 0}, {0, 1, 0}, msc_target_pos(ct));
    }

    if (oe.gui_button("Plane", 10, 50, BUTTON_WIDTH, 30)) {
        msc := msc_check(new_instance);

        oe.msc_append_quad(msc, {}, {1, 0, 0}, {0, 1, 0}, {1, 1, 0}, msc_target_pos(ct));
    }

    if (oe.gui_button("Cuboid", 10, 90, BUTTON_WIDTH, 30)) {
        msc := msc_check(new_instance);
       
        msc_cuboid(msc, msc_target_pos(ct));
    }

    if (oe.gui_button("Recalc aabbs", 10, 130, BUTTON_WIDTH, 30)) {
        for i in 0..<oe.ecs_world.physics.mscs.len {
            msc := oe.ecs_world.physics.mscs.data[i];
            msc._aabb = oe.tris_to_aabb(msc.tris);
        }
    }

    oe.gui_end();
}

map_proj_tool :: proc(ct: CameraTool) {
    oe.gui_begin("Map project", x = 0, y = 360 + oe.gui_top_bar_height * 2, can_exit = false);

    if (oe.gui_button("Load map", 10, 10, BUTTON_WIDTH, 30)) {
        path := oe.fd_file_path();
        if (filepath.ext(path) == ".json") {
            msc := oe.msc_init();
            oe.msc_from_json(msc, path);
        } else if (filepath.ext(path) == ".obj") {
            msc := oe.msc_init();
            oe.msc_from_model(msc, oe.load_model(path));
        }
    }

    if (oe.gui_button("Save map", 10, 50, BUTTON_WIDTH, 30)) {
        path := oe.fd_file_path();
        if (path != oe.STR_EMPTY) {
            for i in 0..<oe.ecs_world.physics.mscs.len {
                 oe.msc_to_json(oe.ecs_world.physics.mscs.data[i], path);
            }
        }
    }

    if (oe.gui_button("Clear", 10, 90, BUTTON_WIDTH, 30)) {
        fa.clear(&oe.ecs_world.physics.mscs);
    }

    oe.gui_end();
}

texture_tool :: proc(ct: CameraTool) {
    if (ct._active_msc_id == ACTIVE_EMPTY || ct._active_id == ACTIVE_EMPTY) do return;

    oe.gui_begin("Texture tool", x = 0, y = 560 + oe.gui_top_bar_height * 3, active = false);

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

    @static tag: string;
    @static id: u32;
    if (oe.gui_button("Add dataID", 10, 10, BUTTON_WIDTH, 30)) {
        if (tag == "") do tag = "default";

        reg_tag := oe.str_add("data_id_", tag);
        if (oe.asset_manager.registry[reg_tag] != nil) do reg_tag = oe.str_add(reg_tag, oe.rand_digits(4));

        oe.reg_asset(reg_tag, oe.DataID {reg_tag, tag, id, oe.Transform{msc_target_pos(ct), {}, oe.vec3_one()}});
        oe.dbg_log(oe.str_add({"Added data id of tag: ", tag, " and id: ", oe.str_add("", id)}));
    }

    tag = oe.gui_text_box("TagTextBox", 10, 50, BUTTON_WIDTH, 30);
    oe.gui_text("Tag", 25, BUTTON_WIDTH + 20, 50);

    id_parse := oe.gui_text_box("IDTextBox", 10, 90, BUTTON_WIDTH, 30);
    oe.gui_text("ID", 25, BUTTON_WIDTH + 20, 90);

    parsed, ok := sc.parse_int(id_parse);
    if (ok) do id = u32(parsed);

    oe.gui_end();
}

data_id_mod_tool :: proc(ct: CameraTool) {
    oe.gui_begin("DataID modifier", x = f32(oe.w_render_width()) - 300, y = 200 + oe.gui_top_bar_height, active = false);

    @static tag: string;
    @static id: u32;
    if (oe.gui_button("Modify", 10, 10, BUTTON_WIDTH, 30)) {
        if (tag == "") do tag = "default";

        reg_tag := oe.str_add("data_id_", tag);
        if (oe.asset_manager.registry[reg_tag] != nil) do reg_tag = oe.str_add(reg_tag, oe.rand_digits(4));

        // actually just reregistering
        oe.unreg_asset(editor_data.active_data_id.reg_tag);

        editor_data.active_data_id.id = id;
        editor_data.active_data_id.tag = tag;
        editor_data.active_data_id.reg_tag = reg_tag;

        oe.reg_asset(reg_tag, oe.DataID {reg_tag, tag, id, editor_data.active_data_id.transform});
        oe.dbg_log(oe.str_add({"Modified data id of tag: ", tag, " and id: ", oe.str_add("", id)}));
    }

    tag = oe.gui_text_box("ModTagTextBox", 10, 50, BUTTON_WIDTH, 30);
    oe.gui_text("Tag", 25, BUTTON_WIDTH + 20, 50);

    id_parse := oe.gui_text_box("ModIDTextBox", 10, 90, BUTTON_WIDTH, 30);
    oe.gui_text("ID", 25, BUTTON_WIDTH + 20, 90);

    parsed, ok := sc.parse_int(id_parse);
    if (ok) do id = u32(parsed);

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

package main

import "core:fmt"
import rl "vendor:raylib"
import sdl "vendor:sdl2"
import oe "../../oengine"
import "core:math"
import "core:path/filepath"
import sc "core:strconv"

BUTTON_WIDTH :: 180

registry_tool :: proc(ct: CameraTool) {
    oe.gui_begin("Registry", x = 0, y = 0, h = 150, can_exit = false);

    if (oe.gui_button("Load registry", 10, 10, BUTTON_WIDTH, 30)) {
        path := oe.fd_file_path();
        if (filepath.ext(path) == ".json") {
            oe.load_registry(path);
        }
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
        for msc in oe.ecs_world.physics.mscs {
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
            for msc in oe.ecs_world.physics.mscs {
                 oe.msc_to_json(msc, path);
            }
        }
    }

    if (oe.gui_button("Clear", 10, 90, BUTTON_WIDTH, 30)) {
        clear(&oe.ecs_world.physics.mscs);
    }

    oe.gui_end();
}

texture_tool :: proc(ct: CameraTool) {
    oe.gui_begin("Texture tool", x = 0, y = 560 + oe.gui_top_bar_height * 3, active = false);

    texs := oe.get_reg_textures_tags();

    for i in 0..<len(texs) {
        tag := texs[i];
        if (oe.gui_button(tag, 10, 10 + f32(i) * 35, BUTTON_WIDTH, 30)) {
            active := oe.ecs_world.physics.mscs[ct._active_msc_id].tris[ct._active_id];
            active.texture_tag = tag;
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
        if (oe.asset_manager.registry[reg_tag] != nil) do reg_tag = oe.str_add(reg_tag, rl.GetRandomValue(1000, 9999));

        oe.reg_asset(reg_tag, oe.DataID {tag, id, oe.Transform{ct.camera_perspective.position, {}, oe.vec3_one()}});
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
        if (len(oe.ecs_world.physics.mscs) > 0) {
            msc = oe.ecs_world.physics.mscs[len(oe.ecs_world.physics.mscs) - 1];
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

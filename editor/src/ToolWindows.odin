package main

import "core:fmt"
import rl "vendor:raylib"
import oe "../../oengine"
import "core:math"

BUTTON_WIDTH :: 180

msc_tool :: proc(ct: CameraTool) {
    oe.gui_begin("MSC tool", x = 0, y = 0, h = 210, can_exit = false);

    @static new_instance: bool;
    new_instance = oe.gui_tick(new_instance, 10, 10, 30, 30);

    oe.gui_text("New instance", 20, 50, 10);

    if (oe.gui_button("Triangle plane", 10, 50, BUTTON_WIDTH, 30)) {
        msc := msc_check(new_instance);

        oe.msc_append_tri(msc, {}, {1, 0, 0}, {0, 1, 0}, msc_target_pos(ct));
    }

    if (oe.gui_button("Plane", 10, 90, BUTTON_WIDTH, 30)) {
        msc := msc_check(new_instance);

        oe.msc_append_quad(msc, {}, {1, 0, 0}, {0, 1, 0}, {1, 1, 0}, msc_target_pos(ct));
    }

    if (oe.gui_button("Cuboid", 10, 130, BUTTON_WIDTH, 30)) {
        msc := msc_check(new_instance);
       
        msc_cuboid(msc, msc_target_pos(ct));
    }

    if (oe.gui_button("Recalc aabbs", 10, 170, BUTTON_WIDTH, 30)) {
        for msc in oe.ecs_world.physics.mscs {
            msc._aabb = oe.tris_to_aabb(msc.tris);
        }
    }

    oe.gui_end();
}

map_proj_tool :: proc(ct: CameraTool) {
    oe.gui_begin("Map project", x = 0, y = 210 + oe.gui_top_bar_height, can_exit = false);

    if (oe.gui_button("Load map", 10, 10, BUTTON_WIDTH, 30)) {
        oe.fd_file_path(); 
    }

    if (oe.gui_button("Save map", 10, 50, BUTTON_WIDTH, 30)) {
        oe.fd_file_path();
    }

    oe.gui_end();
}

@(private = "file")
msc_target_pos :: proc(ct: CameraTool) -> oe.Vec3 {
    if (ct.mode == .PERSPECTIVE) do return ct.camera_perspective.position;

    snapped_x: f32 = math.round(ct.camera_orthographic.target.x / GRID_SPACING) * GRID_SPACING;
    snapped_y: f32 = math.round(ct.camera_orthographic.target.y / GRID_SPACING) * GRID_SPACING;

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

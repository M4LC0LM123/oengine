package main

import "core:fmt"
import str "core:strings"
import rl "vendor:raylib"
import oe "../../oengine"

globals: struct {
    registry_atlas: oe.Atlas,
};

main :: proc() {
    monitor := rl.GetCurrentMonitor();
    oe.w_create(oe.EDITOR_INSTANCE);
    rl.MaximizeWindow();
    oe.w_set_resolution(rl.GetMonitorWidth(monitor), rl.GetMonitorHeight(monitor));
    oe.w_set_title("oengine-editor");
    oe.w_set_target_fps(60);

    oe.ew_init(oe.vec3_y() * 50);

    camera_tool := ct_init();
    oe.ecs_world.camera = &camera_tool.camera_perspective;

    distances := make([dynamic]f32);
    collided_dids := make([dynamic]oe.DataID);

    for (oe.w_tick()) {
        // update
        oe.ew_update();
        ct_update(&camera_tool);

        handle_mouse_ray(&distances, &collided_dids); 

        // render
        oe.w_begin_render();
        rl.ClearBackground(rl.BLACK);

        ct_render(&camera_tool);

        registry_tool(camera_tool);
        msc_tool(camera_tool);
        map_proj_tool(camera_tool);
        data_id_tool(camera_tool);
        texture_tool(camera_tool);
        data_id_mod_tool(camera_tool);
        did_component_tool(camera_tool);

        oe.w_end_render();
    }

    oe.ew_deinit();
    oe.w_close();
}

handle_mouse_ray :: proc(distances: ^[dynamic]f32, collided_dids: ^[dynamic]oe.DataID) {
    collision_count: i32;
    clear(distances);
    clear(collided_dids);
    editor_data.hovered_data_id = "";
    dids := oe.get_reg_data_ids();
    defer delete(dids);
    for i in 0..<len(dids) {
        data_id := oe.get_asset_var(dids[i].reg_tag, oe.DataID);
        mouse_ray := rl.GetMouseRay(oe.window.mouse_position, oe.ecs_world.camera.rl_matrix);
        collision := rl.GetRayCollisionBox(mouse_ray, oe.transform_to_rl_bb(data_id.transform));

        if (collision.hit) {
            collision_count += 1;
            append(distances, collision.distance);
            append(collided_dids, data_id);
        }
    }

    did: int = 0;
    if (collision_count > 1) {
        // multiple collisions
        min_dist := distances[0];
        id: int;
        for i in 1..<len(distances) {
            dist := distances[i];

            if (dist < min_dist) {
                min_dist = dist;
                id = i;
            }
        }

        did = id;
    }

    if (collision_count == 0) {
        if (oe.mouse_pressed(.LEFT) && !oe.gui_mouse_over()) { 
            editor_data.active_data_id = oe.STR_EMPTY; 
            oe.gui.windows["DataID modifier"].active = false;
            oe.gui.windows["Add components"].active = false;
        }
        return;
    }

    editor_data.hovered_data_id = collided_dids[did].reg_tag;

    if (oe.mouse_pressed(.LEFT)) {
        editor_data.active_data_id = editor_data.hovered_data_id;
        did := oe.get_asset_var(editor_data.active_data_id, oe.DataID);

        oe.gui.windows["DataID modifier"].active = true;
        oe.gui.text_boxes["ModTagTextBox"].text = did.tag;
        oe.gui.text_boxes["ModIDTextBox"].text = oe.str_add("", did.id);
    }
}

update :: proc() {
    if (editor_data.active_data_id != oe.STR_EMPTY) {
        if (oe.key_pressed(.DELETE)) {
            oe.unreg_asset(editor_data.active_data_id);
            editor_data.active_data_id = oe.STR_EMPTY;
        }
    }

    for i in 0..<oe.ecs_world.physics.mscs.len {
        oe.ecs_world.physics.mscs.data[i].atlas = globals.registry_atlas;
    }
}

render :: proc() {
    if (editor_data.hovered_data_id != oe.STR_EMPTY) { 
        did := oe.get_asset_var(editor_data.hovered_data_id, oe.DataID);
        t := did.transform;
        oe.draw_cube_wireframe(t.position, t.rotation, t.scale, oe.YELLOW); 
    }
    
    if (editor_data.active_data_id != oe.STR_EMPTY) {
        did := oe.get_asset_var(editor_data.active_data_id, oe.DataID);
        t := did.transform;
        oe.draw_cube_wireframe(t.position, t.rotation, t.scale, oe.BLUE); 
    }

}

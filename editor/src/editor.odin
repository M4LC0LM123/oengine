package main

import "core:fmt"
import str "core:strings"
import rl "vendor:raylib"
import oe "../../oengine"

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
    collided_dids := make([dynamic]^oe.DataID);

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

        oe.w_end_render();
    }

    oe.ew_deinit();
    oe.w_close();
}

handle_mouse_ray :: proc(distances: ^[dynamic]f32, collided_dids: ^[dynamic]^oe.DataID) {
    collision_count: i32;
    clear(distances);
    clear(collided_dids);
    editor_data.hovered_data_id = nil;
    for &data_id in oe.get_reg_data_ids() {
        mouse_ray := rl.GetMouseRay(oe.window.mouse_position, oe.ecs_world.camera.rl_matrix);
        collision := rl.GetRayCollisionBox(mouse_ray, oe.transform_to_rl_bb(data_id.transform));

        if (collision.hit) {
            // fmt.println("Collision with ", data_id);
            collision_count += 1;
            append(distances, collision.distance);
            append(collided_dids, &data_id);
        }
    }

    if (collision_count == 1) {
        // one collision
        editor_data.hovered_data_id = collided_dids[0];
    } else if (collision_count > 1) {
        // multiple collisions
        min_dist := distances[0];
        id: int;
        for i in 0..<len(distances) {
            dist := distances[i];

            if (dist < min_dist) {
                min_dist = dist;
                id = i;
            }
        }

        editor_data.hovered_data_id = collided_dids[id];
    }
}

render :: proc() {
    if (editor_data.hovered_data_id != nil) { 
        t := editor_data.hovered_data_id.transform;
        oe.draw_cube_wireframe(t.position, t.rotation, t.scale, oe.YELLOW); 
    }
}

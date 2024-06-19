package main

import "core:fmt"
import str "core:strings"
import rl "vendor:raylib"
import oe "../../oengine"

main :: proc() {
    oe.w_create();
    oe.w_set_title("gejm");
    oe.w_set_target_fps(60);
    oe.window.debug_stats = true;

    oe.ew_init(oe.vec3_y() * 50);

    camera := oe.cm_init(oe.vec3_zero());
    is_mouse_locked: bool = false;
    oe.ecs_world.camera = &camera;

    for (oe.w_tick()) {
        // update
        oe.ew_update();

        if (oe.key_pressed(oe.Key.ESCAPE)) {
            is_mouse_locked = !is_mouse_locked;
        }

        oe.cm_set_fps(&camera, 0.1, is_mouse_locked);
        oe.cm_set_fps_controls(&camera, 10, is_mouse_locked, true);
        oe.cm_default_fps_matrix(&camera);
        oe.cm_update(&camera);

        // render
        oe.w_begin_render();
        rl.ClearBackground(rl.SKYBLUE);

        rl.BeginMode3D(camera.rl_matrix);
        oe.ew_render();

        rl.EndMode3D();

        oe.gui_end();

        oe.w_end_render();
    }

    oe.ew_deinit();
    oe.w_close();
}

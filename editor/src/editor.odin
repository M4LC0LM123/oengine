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

    for (oe.w_tick()) {
        // update
        oe.ew_update();
        ct_update(&camera_tool);

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

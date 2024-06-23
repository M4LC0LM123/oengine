package main

import "core:fmt"
import rl "vendor:raylib"
import oe "../../oengine"

msc_tool :: proc(ct: CameraTool) {
    oe.gui_begin("MSC tool", x = 0, y = 0, can_exit = false);

    @(static) new_instance: bool;
    new_instance = oe.gui_tick(new_instance, 10, 10, 30, 30);

    if (oe.gui_button("triangle_plane", 10, 50, 150, 30)) {
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

        oe.msc_append_tri(msc, {}, {1, 0, 0}, {0, 1, 0}, ct.camera_perspective.position);
    }

    oe.gui_end();
}



package main

import "core:fmt"
import rl "vendor:raylib"
import oe "../../oengine"

GRID_SPACING :: 25
GRID_COLOR :: oe.Color {255, 255, 255, 125}

CameraMode :: enum {
    PERSPECTIVE = 0,
    ORTHO_XY,
    ORTHO_XZ,
    ORTHO_ZY
}

CameraTool :: struct {
    camera_perspective: oe.Camera,
    mouse_locked: bool,
    camera_orthographic: rl.Camera2D,
    mode: CameraMode,

    _mouse_pos: oe.Vec2,
    _prev_mouse_pos: oe.Vec2,
}

ct_init :: proc() -> CameraTool {
    return CameraTool {
        camera_perspective = oe.cm_init({}),
        mouse_locked = false,
        camera_orthographic = rl.Camera2D {
            target = {},
            offset = {f32(oe.w_render_width()) * 0.5, f32(oe.w_render_height()) * 0.5},
            rotation = 0, zoom = 1,
        },
        mode = .PERSPECTIVE,
    };
}

ct_update :: proc(using self: ^CameraTool) {
    if (mode == .PERSPECTIVE) {
        ct_update_perspective(self);
    } else {
        ct_update_ortho(self);
    }

    key := oe.char_pressed();
    if (key >= 49 && key <= 52) {
        mode = CameraMode(key - 49);
    }
}

ct_render :: proc(using self: ^CameraTool) {
    if (mode == .PERSPECTIVE) {
        rl.BeginMode3D(camera_perspective.rl_matrix);
        oe.ew_render();
        rl.EndMode3D();
    } else {
        rl.BeginMode2D(camera_orthographic);
        oe.draw_grid2D(100, GRID_SPACING, GRID_COLOR);
        rl.EndMode2D();
    }
}

@(private = "file")
ct_update_perspective :: proc(using self: ^CameraTool) {
    if (oe.key_pressed(oe.Key.ESCAPE)) {
        mouse_locked = !mouse_locked;
    }

    oe.cm_set_fps(&camera_perspective, 0.1, mouse_locked);
    oe.cm_set_fps_controls(&camera_perspective, 10, mouse_locked, true);
    oe.cm_default_fps_matrix(&camera_perspective);
    oe.cm_update(&camera_perspective);
}

@(private = "file")
ct_update_ortho :: proc(using self: ^CameraTool) {
    _mouse_pos = rl.GetScreenToWorld2D(oe.window.mouse_position, camera_orthographic);
    _prev_mouse_pos = _mouse_pos;

    new_zoom := camera_orthographic.zoom + rl.GetMouseWheelMoveV().y * 0.01;
    if (new_zoom <= 0) do new_zoom = 0.01;

    zoom_factor := new_zoom / camera_orthographic.zoom;
    camera_orthographic.offset -= (_mouse_pos - camera_orthographic.target) * (zoom_factor - 1);
    camera_orthographic.zoom = new_zoom;

    if (oe.key_pressed(.SPACE)) {
        camera_orthographic.target = {};
    }

    if (oe.mouse_down(.MIDDLE)) {
        delta := rl.GetMouseDelta();
        delta = delta * (-1 / camera_orthographic.zoom);

        camera_orthographic.target += delta;
    }
}

package main

import "core:fmt"
import rl "vendor:raylib"
import oe "../../oengine"

GRID_SPACING :: 25
GRID_COLOR :: oe.Color {255, 255, 255, 125}
RENDER_SCALAR :: 25
POINT_SIZE :: 5

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
        ct_render_ortho(self);
        rl.EndMode2D();
    }
}

@(private = "file")
ct_render_ortho :: proc(using self: ^CameraTool) {
    oe.draw_grid2D(100, GRID_SPACING, GRID_COLOR);

    // cross
    rl.rlPushMatrix();
    rl.rlTranslatef(camera_orthographic.target.x, camera_orthographic.target.y, 0);
    rl.DrawLineV({-5, 0}, {5, 0}, oe.PINK);
    rl.DrawLineV({0, -5}, {0, 5}, oe.PINK);
    rl.rlPopMatrix();

    for msc in oe.ecs_world.physics.mscs {
        for tri in msc.tris {
            tri_render_ortho(self, tri);
        } 
    }
}

@(private = "file")
tri_render_ortho :: proc(using self: ^CameraTool, tri: ^oe.TriangleCollider) {
    rl.rlPushMatrix();
    rl.rlScalef(RENDER_SCALAR, RENDER_SCALAR, 0);

    #partial switch mode {
        case .ORTHO_XY:
            t := tri.pts;
            rl.DrawLineV(t[0].xy, t[1].xy, rl.YELLOW);
            rl.DrawLineV(t[0].xy, t[2].xy, rl.YELLOW);
            rl.DrawLineV(t[1].xy, t[2].xy, rl.YELLOW);
            rl.rlPopMatrix();

            res := update_point_ortho(self, tri.pts[0].xy);
            tri.pts[0] = {res.x, res.y, 0};
            res = update_point_ortho(self, tri.pts[1].xy);
            tri.pts[1] = {res.x, res.y, 0};
            res = update_point_ortho(self, tri.pts[2].xy);
            tri.pts[2] = {res.x, res.y, 0};
        case .ORTHO_XZ:
            t := tri.pts;
            rl.DrawLineV(t[0].xz, t[1].xz, rl.YELLOW);
            rl.DrawLineV(t[0].xz, t[2].xz, rl.YELLOW);
            rl.DrawLineV(t[1].xz, t[2].xz, rl.YELLOW);
            rl.rlPopMatrix();

            res := update_point_ortho(self, tri.pts[0].xz);
            tri.pts[0] = {res.x, 0, res.y};
            res = update_point_ortho(self, tri.pts[1].xz);
            tri.pts[1] = {res.x, 0, res.y};
            res = update_point_ortho(self, tri.pts[2].xz);
            tri.pts[2] = {res.x, 0, res.y};
        case .ORTHO_ZY:
            t := tri.pts;
            rl.DrawLineV(t[0].zy, t[1].zy, rl.YELLOW);
            rl.DrawLineV(t[0].zy, t[2].zy, rl.YELLOW);
            rl.DrawLineV(t[1].zy, t[2].zy, rl.YELLOW);
            rl.rlPopMatrix();

            res := update_point_ortho(self, tri.pts[0].zy);
            tri.pts[0] = {0, res.x, res.y};
            res = update_point_ortho(self, tri.pts[1].zy);
            tri.pts[1] = {0, res.x, res.y};
            res = update_point_ortho(self, tri.pts[2].zy);
            tri.pts[2] = {0, res.x, res.y};
    }

    rl.rlPopMatrix();
}

@(private = "file")
update_point_ortho :: proc(using self: ^CameraTool, pt: oe.Vec2) -> oe.Vec2 {
    res := pt * RENDER_SCALAR;

    @static _moving: bool;

    mp := rl.GetScreenToWorld2D(oe.window.mouse_position, camera_orthographic);
    if (oe.mouse_pressed(.LEFT) && rl.CheckCollisionPointCircle(mp, res, POINT_SIZE)) {
        _moving = true;
    }

    if (_moving) {
        if (oe.mouse_released(.LEFT))  {
            _moving = false;
        }

        res = mp;
    }

    rl.DrawCircleV(res, POINT_SIZE, oe.BLUE);
    return res / RENDER_SCALAR;
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
    // zoom to mouse
    // camera_orthographic.offset -= (_mouse_pos - camera_orthographic.target) * (zoom_factor - 1);
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

package main

import "core:fmt"
import rl "vendor:raylib"
import oe "../../oengine"
import "core:math"

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
        for i in 0..<len(msc.tris) {
            tri_render_ortho(self, msc.tris[i], i);
        }
    }
}

@(private = "file")
tri_render_ortho :: proc(using self: ^CameraTool, tri: ^oe.TriangleCollider, #any_int id: i32) {
    rl.rlPushMatrix();
    rl.rlScalef(RENDER_SCALAR, RENDER_SCALAR, 0);

    #partial switch mode {
        case .ORTHO_XY:
            t := tri.pts;
            rl.DrawLineV(t[0].xy, t[1].xy, rl.YELLOW);
            rl.DrawLineV(t[0].xy, t[2].xy, rl.YELLOW);
            rl.DrawLineV(t[1].xy, t[2].xy, rl.YELLOW);
            rl.rlPopMatrix();

            for i in 0..<len(tri.pts) {
                res := update_point_ortho(self, tri.pts[i].xy, i, id);
                tri.pts[i] = {res.x, res.y, tri.pts[i].z};
            }
        case .ORTHO_XZ:
            t := tri.pts;
            rl.DrawLineV(t[0].xz, t[1].xz, rl.YELLOW);
            rl.DrawLineV(t[0].xz, t[2].xz, rl.YELLOW);
            rl.DrawLineV(t[1].xz, t[2].xz, rl.YELLOW);
            rl.rlPopMatrix();

            for i in 0..<len(tri.pts) {
                res := update_point_ortho(self, tri.pts[i].xz, i, id);
                tri.pts[i] = {res.x, tri.pts[i].y, res.y};
            }
        case .ORTHO_ZY:
            t := tri.pts;
            rl.DrawLineV(t[0].zy, t[1].zy, rl.YELLOW);
            rl.DrawLineV(t[0].zy, t[2].zy, rl.YELLOW);
            rl.DrawLineV(t[1].zy, t[2].zy, rl.YELLOW);
            rl.rlPopMatrix();

            for i in 0..<len(tri.pts) {
                res := update_point_ortho(self, tri.pts[i].zy, i, id);
                tri.pts[i] = {tri.pts[i].x, res.y, res.x};
            }
    }

    rl.rlPopMatrix();
}

@(private = "file")
update_point_ortho :: proc(using self: ^CameraTool, pt: oe.Vec2, #any_int vertex_id, id: i32) -> oe.Vec2 {
    res := pt * RENDER_SCALAR;

    @static _moving: bool;
    @static _moving_id: i32;
    @static _moving_vertex_id: i32;

    rl.DrawCircleV(res, POINT_SIZE, oe.BLUE);

    mp := rl.GetScreenToWorld2D(oe.window.mouse_position, camera_orthographic);
    if (rl.CheckCollisionPointCircle(mp, res, POINT_SIZE)) {
        if (oe.mouse_pressed(.LEFT)) {    
            _moving = true;
            _moving_id = id;
            _moving_vertex_id = vertex_id;
        }

        rl.DrawCircleV(res, POINT_SIZE, oe.GREEN);
    }

    if (_moving && _moving_vertex_id == vertex_id && _moving_id == id) {
        if (oe.mouse_released(.LEFT))  {
            _moving = false; 
        }

        snapped_x := math.round(mp.x / GRID_SPACING) * GRID_SPACING;
        snapped_y := math.round(mp.y / GRID_SPACING) * GRID_SPACING;

        res = {snapped_x, snapped_y};
    }

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

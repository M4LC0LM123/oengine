package main

import "core:fmt"
import rl "vendor:raylib"
import oe "../../oengine"
import "core:math"

GRID_SPACING :: 25
GRID_COLOR :: oe.Color {255, 255, 255, 125}
RENDER_SCALAR :: 25
POINT_SIZE :: 5
ACTIVE_EMPTY :: -1

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

    _active_id, _active_msc_id: i32,
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
        _active_id = ACTIVE_EMPTY,
        _active_msc_id = ACTIVE_EMPTY,
    };
}

ct_update :: proc(using self: ^CameraTool) {
    if (mode == .PERSPECTIVE) {
        ct_update_perspective(self);
    } else {
        ct_update_ortho(self);
    }

    key := i32(oe.keycode_pressed());
    if (key >= 49 && key <= 52) {
        mode = CameraMode(key - 49);
    }

    // fmt.println(_active_msc_id, _active_id);
}

ct_render :: proc(using self: ^CameraTool) {
    if (mode == .PERSPECTIVE) {
        rl.BeginMode3D(camera_perspective.rl_matrix);
        oe.ew_render();
        render();
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
    rl.rlScalef(1, -1, 1);
    rl.DrawLineV({-5, 0}, {5, 0}, oe.PINK);
    rl.DrawLineV({0, -5}, {0, 5}, oe.PINK);
    rl.rlPopMatrix();

    for msc_id in 0..<len(oe.ecs_world.physics.mscs) {
        msc := oe.ecs_world.physics.mscs[msc_id];
        for i in 0..<len(msc.tris) {
            tri_render_ortho(self, msc.tris[i], i, msc_id);
        }
    }

    if (_active_id == ACTIVE_EMPTY || _active_msc_id == ACTIVE_EMPTY) do return;

    if (oe.key_pressed(.T)) {
        oe.gui_toggle_window("Texture tool");
    }

    if (oe.key_pressed(.DELETE)) {
        ordered_remove(&oe.ecs_world.physics.mscs[_active_msc_id].tris, int(_active_id));
        _active_id = ACTIVE_EMPTY;
        _active_msc_id = ACTIVE_EMPTY;
        return;
    }

    active_3d := oe.ecs_world.physics.mscs[_active_msc_id].tris[_active_id].pts;
    active := msc_tri_to_ortho_tri(active_3d, mode);

    rl.rlPushMatrix();
    rl.rlScalef(1, -1, 1);
    rl.DrawTriangle(
        active[0] * RENDER_SCALAR, 
        active[1] * RENDER_SCALAR, 
        active[2] * RENDER_SCALAR, GRID_COLOR
    );
    rl.rlPopMatrix();
}

@(private = "file")
tri_render_ortho :: proc(using self: ^CameraTool, tri: ^oe.TriangleCollider, #any_int id, msc_id: i32) {
    rl.rlPushMatrix();
    rl.rlScalef(RENDER_SCALAR, -RENDER_SCALAR, 1);

    tri.pts = update_tri_ortho(self, tri.pts, id, msc_id);

    #partial switch mode {
        case .ORTHO_XY:
            t := tri.pts;
            rl.DrawLineV(t[0].xy, t[1].xy, rl.YELLOW);
            rl.DrawLineV(t[0].xy, t[2].xy, rl.YELLOW);
            rl.DrawLineV(t[1].xy, t[2].xy, rl.YELLOW);
            rl.rlPopMatrix();

            for i in 0..<len(tri.pts) {
                res := update_point_ortho(self, tri.pts[i].xy, i, id, msc_id);
                tri.pts[i] = {res.x, res.y, tri.pts[i].z};
            }
        case .ORTHO_XZ:
            t := tri.pts;
            rl.DrawLineV(t[0].xz, t[1].xz, rl.YELLOW);
            rl.DrawLineV(t[0].xz, t[2].xz, rl.YELLOW);
            rl.DrawLineV(t[1].xz, t[2].xz, rl.YELLOW);
            rl.rlPopMatrix();

            for i in 0..<len(tri.pts) {
                res := update_point_ortho(self, tri.pts[i].xz, i, id, msc_id);
                tri.pts[i] = {res.x, tri.pts[i].y, res.y};
            }
        case .ORTHO_ZY:
            t := tri.pts;
            rl.DrawLineV(t[0].zy, t[1].zy, rl.YELLOW);
            rl.DrawLineV(t[0].zy, t[2].zy, rl.YELLOW);
            rl.DrawLineV(t[1].zy, t[2].zy, rl.YELLOW);
            rl.rlPopMatrix();

            for i in 0..<len(tri.pts) {
                res := update_point_ortho(self, tri.pts[i].zy, i, id, msc_id);
                tri.pts[i] = {tri.pts[i].x, res.y, res.x};
            }
    }

    rl.rlPopMatrix();
}

@(private = "file")
msc_tri_to_ortho_tri :: proc(pts: [3]oe.Vec3, mode: CameraMode) -> [3]oe.Vec2 {
    #partial switch mode {
        case .ORTHO_XY:
            return { pts[0].xy, pts[1].xy, pts[2].xy };
        case .ORTHO_XZ:
            return { pts[0].xz, pts[1].xz, pts[2].xz };
        case .ORTHO_ZY:
            return { pts[0].zy, pts[1].zy, pts[2].zy };
    }

    return { pts[0].xy, pts[1].xy, pts[2].xy };
}

@(private = "file")
ortho_tri_to_msc_tri :: proc(pts: [3]oe.Vec2, pts_3d: [3]oe.Vec3, mode: CameraMode) -> [3]oe.Vec3 {
    #partial switch mode {
        case .ORTHO_XY:
            return { 
                {pts[0].x, pts[0].y, pts_3d[0].z}, 
                {pts[1].x, pts[1].y, pts_3d[1].z}, 
                {pts[2].x, pts[2].y, pts_3d[2].z}, 
            };
        case .ORTHO_XZ:
            return { 
                {pts[0].x, pts_3d[0].y, pts[0].y}, 
                {pts[1].x, pts_3d[1].y, pts[1].y}, 
                {pts[2].x, pts_3d[2].y, pts[2].y}, 
            };
        case .ORTHO_ZY:
            return { 
                {pts_3d[0].x, pts[0].y, pts[0].x}, 
                {pts_3d[1].x, pts[1].y, pts[1].x}, 
                {pts_3d[2].x, pts[2].y, pts[2].x}, 
            };
    }

    return { 
        {pts[0].x, pts[0].y, pts_3d[0].z}, 
        {pts[1].x, pts[1].y, pts_3d[1].z}, 
        {pts[2].x, pts[2].y, pts_3d[2].z}, 
    };
}

@(private = "file")
update_tri_ortho :: proc(using self: ^CameraTool, pts: [3]oe.Vec3, #any_int id, msc_id: i32) -> [3]oe.Vec3 {
    res := pts * RENDER_SCALAR;

    @static _moving: bool;
    @static _moving_id: i32;
    @static _moving_msc_id: i32;
    @static _offsets: [3]oe.Vec2;

    mp := rl.GetScreenToWorld2D(oe.window.mouse_position, camera_orthographic);
    mp.y = -mp.y;
    tri := msc_tri_to_ortho_tri(res, mode);
    if (rl.CheckCollisionPointTriangle(mp, tri[0], tri[1], tri[2])) {
        rl.DrawTriangle(
            tri[0] / RENDER_SCALAR, 
            tri[1] / RENDER_SCALAR, 
            tri[2] / RENDER_SCALAR, GRID_COLOR
        );

        if (oe.mouse_pressed(.LEFT) && !oe.gui_mouse_over()) {
            _moving = true;
            _moving_id = id;
            _active_id = id;
            _moving_msc_id = msc_id;
            _active_msc_id = msc_id;

            snapped_x := math.round(mp.x / GRID_SPACING) * GRID_SPACING;
            snapped_y := math.round(mp.y / GRID_SPACING) * GRID_SPACING;

            _offsets = {
                {snapped_x - tri[0].x, snapped_y - tri[0].y},
                {snapped_x - tri[1].x, snapped_y - tri[1].y},
                {snapped_x - tri[2].x, snapped_y - tri[2].y},
            };
        }
    } else {
        if (!oe.gui_mouse_over() &&
            oe.mouse_pressed(.LEFT) &&
            _active_id == id && 
            _active_msc_id == msc_id) { 
            _active_id = ACTIVE_EMPTY;
            _active_msc_id = ACTIVE_EMPTY;
        }
    }

    if (_moving && _moving_id == id && _moving_msc_id == msc_id) {
        if (oe.mouse_released(.LEFT)) do _moving = false;

        for i in 0..<3 {
            snapped_x := math.round(mp.x / GRID_SPACING) * GRID_SPACING;
            snapped_y := math.round(mp.y / GRID_SPACING) * GRID_SPACING;

            tri[i] = {snapped_x - _offsets[i].x, snapped_y - _offsets[i].y};
        }
    }

    res = ortho_tri_to_msc_tri(tri, res, mode); 

    return res / RENDER_SCALAR;
}

@(private = "file")
update_point_ortho :: proc(using self: ^CameraTool, pt: oe.Vec2, #any_int vertex_id, id, msc_id: i32) -> oe.Vec2 {
    res := pt * RENDER_SCALAR;
    res.y *= -1;

    @static _moving: bool;
    @static _moving_id: i32;
    @static _moving_msc_id: i32;
    @static _moving_vertex_id: i32;

    rl.DrawCircleV(res, POINT_SIZE, oe.BLUE);

    mp := rl.GetScreenToWorld2D(oe.window.mouse_position, camera_orthographic);
    if (rl.CheckCollisionPointCircle(mp, res, POINT_SIZE)) {
        if (oe.mouse_pressed(.LEFT) && !oe.gui_mouse_over()) {    
            _moving = true;
            _moving_id = id;
            _moving_vertex_id = vertex_id;
            _moving_msc_id = msc_id;
        }

        rl.DrawCircleV(res, POINT_SIZE, oe.GREEN);
    }

    if (_moving && _moving_vertex_id == vertex_id && _moving_id == id && _moving_msc_id == msc_id) {
        if (oe.mouse_released(.LEFT))  {
            _moving = false; 
        }

        snapped_x := math.round(mp.x / GRID_SPACING) * GRID_SPACING;
        snapped_y := math.round(mp.y / GRID_SPACING) * GRID_SPACING;

        res = {snapped_x, snapped_y};
    }

    res.y *= -1;
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

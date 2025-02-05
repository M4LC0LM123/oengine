package main

import "core:fmt"
import oe "../oengine"
import "../oengine/gl"
import "core:math"

// Camera variables
camera_pos: [3]f32 = {0, 0, 3}; // Camera position
camera_target: [3]f32 = {0, 0, 0}; // Looking at origin
camera_up: [3]f32 = {0, 1, 0}; // Up direction

main :: proc() {
    oe.w_create();
    oe.w_set_title("gejm");
    oe.w_set_target_fps(60);

    gl.Enable(gl.DEPTH_TEST);
    gl.DepthFunc(gl.LEQUAL);
    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.Enable(gl.CULL_FACE);
    gl.CullFace(gl.BACK);

    // Set up the projection matrix
    gl.MatrixMode(gl.PROJECTION);
    gl.LoadIdentity();

    // Define perspective manually using glFrustum
    near: f64 = 0.001;
    far: f64 = 100.0;
    fov: f64 = 60.0;
    aspect: f64 = f64(oe.w_render_width()) / f64(oe.w_render_height());
    top: f64 = near * math.tan(fov * 0.5 * oe.Deg2Rad);
    bottom: f64 = -top;
    right: f64 = top * aspect;
    left: f64 = -right;

    gl.Frustum(left, right, bottom, top, near, far);

    gl.MatrixMode(gl.MODELVIEW);
    gl.LoadIdentity();

    for (oe.w_tick()) {
        // Camera movement
        move_speed: f32 = 5;
        if oe.key_down(.W) {
            camera_pos[2] -= move_speed * oe.w_delta_time(); // Move forward
        }
        if oe.key_down(.S) {
            camera_pos[2] += move_speed * oe.w_delta_time(); // Move backward
        }
        if oe.key_down(.A) {
            camera_pos[0] -= move_speed * oe.w_delta_time(); // Move left
        }
        if oe.key_down(.D) {
            camera_pos[0] += move_speed * oe.w_delta_time(); // Move right
        }

        // Update rotation
        @static rotation: f32;
        rotation += 10 * oe.w_delta_time();

        // Render
        oe.w_begin_render();
        gl.ClearColor(0.1, 0.1, 0.1, 1);
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        gl.MatrixMode(gl.PROJECTION);
        gl.LoadIdentity();
        gl.Frustum(left, right, bottom, top, near, far);

        gl.MatrixMode(gl.MODELVIEW);
        gl.LoadIdentity();
        mat := oe.mat4_to_arr(oe.mat4_look_at(camera_pos, camera_target, camera_up));
        gl.MultMatrixf(&mat[0]);
        gl.Translatef(-camera_pos.x, -camera_pos.y, -camera_pos.z);

        gl.Enable(gl.LIGHTING);
        gl.Enable(gl.LIGHT0);
        gl.ShadeModel(gl.SMOOTH);

        l_pos := oe.Vec3 {1, 2, 1};
        l_ambient := oe.Vec4 {0.2, 0.2, 0.2, 1};
        l_diffuse := oe.Vec4 {0.8, 0.8, 0.8, 1};
        l_specular := oe.Vec4 {1.0, 1.0, 1.0, 1.0};

        gl.Lightfv(gl.LIGHT0, gl.POSITION, raw_data(l_pos[:]));
        gl.Lightfv(gl.LIGHT0, gl.AMBIENT, raw_data(l_ambient[:]));
        gl.Lightfv(gl.LIGHT0, gl.DIFFUSE, raw_data(l_diffuse[:]));
        gl.Lightfv(gl.LIGHT0, gl.SPECULAR, raw_data(l_specular[:]));

        gl.PushMatrix();
        gl.Rotatef(rotation, 1, 1, 1);

        gl.Begin(gl.QUADS);
        // Front face
        gl.Color3f(1.0, 0.0, 0.0);
        gl.Vertex3f(-0.5, -0.5, 0.5);
        gl.Vertex3f(0.5, -0.5, 0.5);
        gl.Vertex3f(0.5, 0.5, 0.5);
        gl.Vertex3f(-0.5, 0.5, 0.5);

        // Back face
        gl.Color3f(0.0, 1.0, 0.0);
        gl.Vertex3f(-0.5, -0.5, -0.5);
        gl.Vertex3f(-0.5, 0.5, -0.5);
        gl.Vertex3f(0.5, 0.5, -0.5);
        gl.Vertex3f(0.5, -0.5, -0.5);

        // Left face
        gl.Color3f(0.0, 0.0, 1.0);
        gl.Vertex3f(-0.5, -0.5, -0.5);
        gl.Vertex3f(-0.5, -0.5, 0.5);
        gl.Vertex3f(-0.5, 0.5, 0.5);
        gl.Vertex3f(-0.5, 0.5, -0.5);

        // Right face
        gl.Color3f(1.0, 1.0, 0.0);
        gl.Vertex3f(0.5, -0.5, -0.5);
        gl.Vertex3f(0.5, 0.5, -0.5);
        gl.Vertex3f(0.5, 0.5, 0.5);
        gl.Vertex3f(0.5, -0.5, 0.5);

        // Top face
        gl.Color3f(1.0, 0.0, 1.0);
        gl.Vertex3f(-0.5, 0.5, -0.5);
        gl.Vertex3f(-0.5, 0.5, 0.5);
        gl.Vertex3f(0.5, 0.5, 0.5);
        gl.Vertex3f(0.5, 0.5, -0.5);

        // Bottom face
        gl.Color3f(0.0, 1.0, 1.0);
        gl.Vertex3f(-0.5, -0.5, -0.5);
        gl.Vertex3f(0.5, -0.5, -0.5);
        gl.Vertex3f(0.5, -0.5, 0.5);
        gl.Vertex3f(-0.5, -0.5, 0.5);

        gl.End();

        gl.PopMatrix();

        gl.Disable(gl.LIGHTING);
        oe.w_end_render();
    }

    oe.w_close();
}

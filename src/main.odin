package main

import "core:fmt"
import str "core:strings"
import oe "../oengine"
import "../oengine/gl"
import "core:math"

main :: proc() {
    oe.w_create();
    oe.w_set_title("gejm");
    oe.w_set_target_fps(60);

    for (oe.w_tick()) {
        // update
        @static rotation: f32;
        rotation += 10 * oe.w_delta_time();

        // render
        oe.w_begin_render();
        gl.ClearColor(1, 1, 1, 1);
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        gl.MatrixMode(gl.PROJECTION);
        gl.LoadIdentity();

        top := 0.01 * math.tan(f64(60 * 0.5 * oe.Deg2Rad));
        right := top * (f64(oe.w_render_width()) / f64(oe.w_render_height()));

        gl.Frustum(-right, right, -top, top, 0.01, 1000);

        gl.MatrixMode(gl.MODELVIEW);
        gl.LoadIdentity();
        view := oe.mat4_to_arr(oe.mat4_look_at({0, 0, 10}, {}, oe.vec3_y()));
        gl.MultMatrixf(raw_data(view[:]));
        gl.Enable(gl.DEPTH_TEST);

        gl.PushMatrix();
        gl.Rotatef(rotation, 1, 1, 1);

        gl.Begin(gl.QUADS); // Start drawing a quad primitive
        // Front face
        gl.Color3f(1.0, 0.0, 0.0); // Red
        gl.Vertex3f(-0.5, -0.5, 0.5);
        gl.Vertex3f(0.5, -0.5, 0.5);
        gl.Vertex3f(0.5, 0.5, 0.5);
        gl.Vertex3f(-0.5, 0.5, 0.5);

        // Back face
        gl.Color3f(0.0, 1.0, 0.0); // Green
        gl.Vertex3f(-0.5, -0.5, -0.5);
        gl.Vertex3f(-0.5, 0.5, -0.5);
        gl.Vertex3f(0.5, 0.5, -0.5);
        gl.Vertex3f(0.5, -0.5, -0.5);

        // Left face
        gl.Color3f(0.0, 0.0, 1.0); // Blue
        gl.Vertex3f(-0.5, -0.5, -0.5);
        gl.Vertex3f(-0.5, -0.5, 0.5);
        gl.Vertex3f(-0.5, 0.5, 0.5);
        gl.Vertex3f(-0.5, 0.5, -0.5);

        // Right face
        gl.Color3f(1.0, 1.0, 0.0); // Yellow
        gl.Vertex3f(0.5, -0.5, -0.5);
        gl.Vertex3f(0.5, 0.5, -0.5);
        gl.Vertex3f(0.5, 0.5, 0.5);
        gl.Vertex3f(0.5, -0.5, 0.5);

        // Top face
        gl.Color3f(1.0, 0.0, 1.0); // Magenta
        gl.Vertex3f(-0.5, 0.5, -0.5);
        gl.Vertex3f(-0.5, 0.5, 0.5);
        gl.Vertex3f(0.5, 0.5, 0.5);
        gl.Vertex3f(0.5, 0.5, -0.5);

        // Bottom face
        gl.Color3f(0.0, 1.0, 1.0); // Cyan
        gl.Vertex3f(-0.5, -0.5, -0.5);
        gl.Vertex3f(0.5, -0.5, -0.5);
        gl.Vertex3f(0.5, -0.5, 0.5);
        gl.Vertex3f(-0.5, -0.5, 0.5);

        gl.End();

        gl.PopMatrix();

        gl.MatrixMode(gl.MODELVIEW);
        gl.LoadIdentity();
        gl.Disable(gl.DEPTH_TEST);

        gl.MatrixMode(gl.PROJECTION);
        gl.LoadIdentity();
        gl.Ortho(
            0, f64(oe.w_render_width()), 
            f64(oe.w_render_height()), 0, 
            0, 1
        );

        gl.MatrixMode(gl.MODELVIEW);
        gl.LoadIdentity();

        gl.PushMatrix();
        gl.Scalef(100, 100, 0);
        gl.Begin(gl.TRIANGLES);

        gl.Color3f(1.0, 0.0, 0.0);
        gl.Vertex2f(0, 0.5);
        gl.Color3f(0.0, 1.0, 0.0);
        gl.Vertex2f(0.5, 0.5);
        gl.Color3f(0.0, 0.0, 1.0);
        gl.Vertex2f(0.25, 0);

        gl.End();
        gl.PopMatrix();

        oe.w_end_render();
    }

    // oe.ew_deinit();
    oe.w_close();
}

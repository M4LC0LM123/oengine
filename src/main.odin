package main

import "core:fmt"
import str "core:strings"
import oe "../oengine"
import "../oengine/gl"

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

        // gl.PushMatrix();
        // gl.Rotatef(rotation, 1, 1, 1);
        //
        // gl.Begin(gl.QUADS); // Start drawing a quad primitive
        // // Front face
        // gl.Color3f(1.0, 0.0, 0.0); // Red
        // gl.Vertex3f(-0.5, -0.5, 0.5);
        // gl.Vertex3f(0.5, -0.5, 0.5);
        // gl.Vertex3f(0.5, 0.5, 0.5);
        // gl.Vertex3f(-0.5, 0.5, 0.5);
        //
        // // Back face
        // gl.Color3f(0.0, 1.0, 0.0); // Green
        // gl.Vertex3f(-0.5, -0.5, -0.5);
        // gl.Vertex3f(-0.5, 0.5, -0.5);
        // gl.Vertex3f(0.5, 0.5, -0.5);
        // gl.Vertex3f(0.5, -0.5, -0.5);
        //
        // // Left face
        // gl.Color3f(0.0, 0.0, 1.0); // Blue
        // gl.Vertex3f(-0.5, -0.5, -0.5);
        // gl.Vertex3f(-0.5, -0.5, 0.5);
        // gl.Vertex3f(-0.5, 0.5, 0.5);
        // gl.Vertex3f(-0.5, 0.5, -0.5);
        //
        // // Right face
        // gl.Color3f(1.0, 1.0, 0.0); // Yellow
        // gl.Vertex3f(0.5, -0.5, -0.5);
        // gl.Vertex3f(0.5, 0.5, -0.5);
        // gl.Vertex3f(0.5, 0.5, 0.5);
        // gl.Vertex3f(0.5, -0.5, 0.5);
        //
        // // Top face
        // gl.Color3f(1.0, 0.0, 1.0); // Magenta
        // gl.Vertex3f(-0.5, 0.5, -0.5);
        // gl.Vertex3f(-0.5, 0.5, 0.5);
        // gl.Vertex3f(0.5, 0.5, 0.5);
        // gl.Vertex3f(0.5, 0.5, -0.5);
        //
        // // Bottom face
        // gl.Color3f(0.0, 1.0, 1.0); // Cyan
        // gl.Vertex3f(-0.5, -0.5, -0.5);
        // gl.Vertex3f(0.5, -0.5, -0.5);
        // gl.Vertex3f(0.5, -0.5, 0.5);
        // gl.Vertex3f(-0.5, -0.5, 0.5);
        //
        // gl.End();
        //
        // gl.PopMatrix();


        gl.Ortho(
            0, f64(oe.w_render_width()), 
            f64(oe.w_render_height()), 0, 
            0, 1
        );

        gl.Begin(gl.LINES);
        gl.Color3f(0.0, 0.0, 1.0);
        gl.Vertex2f(0, 0);
        gl.Vertex2f(-100, 0);


        gl.End();


        oe.w_end_render();
    }

    // oe.ew_deinit();
    oe.w_close();
}

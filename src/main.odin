package main

import "core:fmt"
import oe "../oengine"
import "../oengine/gl"
import "core:math"

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

    camera := oe.cm_init({0, 0, 3});
    mouse_locked := false;

    for (oe.w_tick()) {
        if (oe.key_pressed(.ESCAPE)) {
            mouse_locked = !mouse_locked;
        }

        oe.cm_update(&camera);
        oe.cm_set_fps(&camera, 0.1, mouse_locked);
        oe.cm_set_fps_controls(&camera, 10, mouse_locked, true);
        oe.cm_default_fps_matrix(&camera);

        // Update rotation
        @static rotation: f32;
        // rotation += 10 * oe.w_delta_time();

        // Render
        oe.w_begin_render();
        gl.ClearColor(0.1, 0.1, 0.1, 1);
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        oe.cm_begin(camera);

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

        oe.cm_end();

        gl.Disable(gl.LIGHTING);
        oe.w_end_render();
    }

    oe.w_close();
}

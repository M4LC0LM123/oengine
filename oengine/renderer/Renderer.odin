package rendering

import oe "../../oengine"
import "core:fmt"

import SDL "vendor:sdl2"
import gl "vendor:OpenGL"

MAX_TRIANGLES :: 2048
MAX_VERTICES :: MAX_TRIANGLES * 3

RenderVertex :: struct {
    pos: oe.Vec3,
    color: oe.Color,
    uv: oe.Vec2,
    tex_id: f32,
}

Renderer :: struct {
    vao, vbo, shader: u32,

    projection, view, model: oe.Mat4,

    triangle_data: [MAX_VERTICES]RenderVertex,
    triangle_count: u32,

    textures: []i32,
    texture_count: u32,
}

renderer_init :: proc(using self: ^Renderer) {
    gl.GenVertexArrays(1, &vao);
    gl.BindVertexArray(vao);

    gl.GenBuffers(1, &vbo);
    gl.BindBuffer(u32(gl.GL_Enum.ARRAY_BUFFER), vbo);
    gl.BufferData(
        u32(gl.GL_Enum.ARRAY_BUFFER),
        MAX_VERTICES * size_of(RenderVertex), nil, gl.DYNAMIC_DRAW
    );

    gl.VertexAttribPointer(0, 3, 
        u32(gl.GL_Enum.FLOAT), false,
        size_of(RenderVertex), offset_of(RenderVertex, pos)
    );
    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(1, 4,
        u32(gl.GL_Enum.FLOAT), false,
        size_of(RenderVertex), offset_of(RenderVertex, color)
    );
    gl.EnableVertexAttribArray(1);

    gl.VertexAttribPointer(2, 2, 
        u32(gl.GL_Enum.FLOAT), false,
        size_of(RenderVertex), offset_of(RenderVertex, uv)
    );
    gl.EnableVertexAttribArray(2);
    gl.VertexAttribPointer(3, 1,
        u32(gl.GL_Enum.FLOAT), false,
        size_of(RenderVertex), offset_of(RenderVertex, tex_id)
    );
    gl.EnableVertexAttribArray(3);

    model = oe.mat4_identity();
    view = oe.mat4_translate(oe.mat4_identity(), {0, 0, -3});
    projection = oe.mat4_perspective(oe.to_radians(60), 4 / 3, 0.1, 100);

    ok: bool;
    shader, ok = gl.load_shaders_source(VERT_SHADER, FRAG_SHADER);

    gl.UseProgram(shader);
    proj_loc := gl.GetUniformLocation(shader, "u_proj");
    view_loc := gl.GetUniformLocation(shader, "u_view");
    model_loc := gl.GetUniformLocation(shader, "u_model");

    s := oe.mat4_to_arr(projection);
    v := oe.mat4_to_arr(view);
    m := oe.mat4_to_arr(model);
    gl.UniformMatrix4fv(proj_loc, 1, false, raw_data(s[:]));
    gl.UniformMatrix4fv(view_loc, 1, false, raw_data(v[:]));
    gl.UniformMatrix4fv(model_loc, 1, false, raw_data(m[:]));


    tex_loc := gl.GetUniformLocation(shader, "u_tex");
    textures = []i32{0, 1, 2, 3, 4, 5, 6, 7};
    gl.Uniform1iv(tex_loc, 8, raw_data(textures));

    gl.Enable(u32(gl.GL_Enum.BLEND));
    gl.BlendFunc(u32(gl.GL_Enum.SRC_ALPHA), u32(gl.GL_Enum.ONE_MINUS_SRC_ALPHA));
}

render_free :: proc(using self: ^Renderer) {
    gl.DeleteBuffers(1, &vbo);
    gl.DeleteVertexArrays(1, &vao);

    gl.DeleteProgram(shader);
}

render_begin :: proc(using self: ^Renderer) {
    gl.Clear(u32(gl.GL_Enum.COLOR_BUFFER_BIT | gl.GL_Enum.DEPTH_BUFFER_BIT));

    triangle_count = 0;
    texture_count = 0;
}

renderer_end :: proc(using self: ^Renderer) {
    for i in 0..<texture_count {
        gl.ActiveTexture(u32(gl.GL_Enum.TEXTURE0) + 1);
        gl.BindTexture(u32(gl.GL_Enum.TEXTURE_2D), u32(textures[i]));
    }

    gl.UseProgram(shader);
    gl.BindVertexArray(vao);
    gl.BindBuffer(u32(gl.GL_Enum.ARRAY_BUFFER), vbo);
    gl.BufferSubData(
        u32(gl.GL_Enum.ARRAY_BUFFER), 0, 
        int(triangle_count * 3 * size_of(RenderVertex)), raw_data(triangle_data[:])
    );

    gl.DrawArrays(u32(gl.GL_Enum.TRIANGLES), 0, i32(triangle_count * 3));
}

renderer_triangle :: proc(
    using self: ^Renderer,
    a, b, c: oe.Vec3,
    a_color, b_color, c_color: oe.Color,
    a_uv, b_uv, c_uv: oe.Vec2, texture: u32) {
    tex_index := 1248;
    for i in 0..<texture_count {
        if (u32(textures[i]) == texture) {
            tex_index = int(i);
            break;
        }
    }

    if (tex_index == 1248 && texture_count < 8) {
        textures[texture_count] = i32(texture);
        tex_index = int(texture_count);
        texture_count += 1;
    }

    if (triangle_count >= MAX_TRIANGLES || tex_index == 1248) {
        renderer_end(self);
        render_begin(self);
    }

    triangle_data[triangle_count * 3 + 0].pos = a;
    triangle_data[triangle_count * 3 + 0].pos = a;
	triangle_data[triangle_count * 3 + 0].color = a_color;
	triangle_data[triangle_count * 3 + 1].pos = b;
	triangle_data[triangle_count * 3 + 1].color = b_color;
	triangle_data[triangle_count * 3 + 2].pos = c;
	triangle_data[triangle_count * 3 + 2].color = c_color;
	
	triangle_data[triangle_count * 3 + 0].uv = a_uv;
	triangle_data[triangle_count * 3 + 0].tex_id = f32(tex_index);
	triangle_data[triangle_count * 3 + 1].uv = b_uv;
	triangle_data[triangle_count * 3 + 1].tex_id = f32(tex_index);
	triangle_data[triangle_count * 3 + 2].uv = c_uv;
	triangle_data[triangle_count * 3 + 2].tex_id = f32(tex_index);

    triangle_count += 1;
}

_cached_white: u32 = 4096;

renderer_get_white_tex :: proc() -> u32 {
    if (_cached_white == 4096) {
        tex: u32;
        image := []u32{ 255, 255, 255, 255 };
        gl.GenTextures(1, &tex);
        gl.BindTexture(u32(gl.GL_Enum.TEXTURE_2D), tex);

        gl.TexImage2D(
            u32(gl.GL_Enum.TEXTURE_2D), 0, 
            i32(gl.GL_Enum.RGBA8), 1, 1, 0, 
            u32(gl.GL_Enum.RGBA), u32(gl.GL_Enum.UNSIGNED_BYTE), raw_data(image)
        );

        gl.TexParameteri(
            u32(gl.GL_Enum.TEXTURE_2D), 
            u32(gl.GL_Enum.TEXTURE_MIN_FILTER), 
            i32(gl.GL_Enum.LINEAR)
        );

        gl.TexParameteri(
            u32(gl.GL_Enum.TEXTURE_2D), 
            u32(gl.GL_Enum.TEXTURE_MAG_FILTER), 
            i32(gl.GL_Enum.LINEAR)
        );

        gl.TexParameteri(
            u32(gl.GL_Enum.TEXTURE_2D), 
            u32(gl.GL_Enum.TEXTURE_WRAP_S), 
            i32(gl.GL_Enum.CLAMP_TO_EDGE)
        );

        gl.TexParameteri(
            u32(gl.GL_Enum.TEXTURE_2D), 
            u32(gl.GL_Enum.TEXTURE_WRAP_T), 
            i32(gl.GL_Enum.CLAMP_TO_EDGE)
        );
        
        _cached_white = tex;
    }

    return _cached_white;
}

VERT_SHADER := `#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec4 aColor;
layout(location = 2) in vec2 aUV;
layout(location = 3) in float aTexIndex;

out vec4 vColor;
out vec2 vUV;
out float vTexIndex;

uniform mat4 u_proj;
uniform mat4 u_view;
uniform mat4 u_model;

void main() {
    vColor = aColor;
    vUV = aUV;
    vTexIndex = aTexIndex;
    gl_Position = u_proj * u_view * u_model * vec4(aPos, 1.0); // Apply the projection and view matrices
}`;

FRAG_SHADER := `#version 330 core

in vec4 vColor;
in vec2 vUV;
in float vTexIndex;

out vec4 FragColor;

uniform sampler2D u_tex[8];

void main() {
    int index = int(vTexIndex);
    vec4 texColor = texture(u_tex[index], vUV);
    FragColor = vColor * texColor;
}`;

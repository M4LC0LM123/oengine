package oengine

import strs "core:strings"
import "core:fmt"
import rl "vendor:raylib"

Fluid :: struct {
    transform: Transform,
    texture: Texture,
    color: Color,
    _shader: Shader,
    
    freq_x:  f32,
    freq_y:  f32,
    amp_x:   f32,
    amp_y:   f32,
    speed_x: f32,
    speed_y: f32,

    set: proc(self: ^Fluid, name: string, val: f32),
}

@(private = "file")
f_init_all :: proc(using f: ^Fluid, s_texture: Texture, s_transform: Transform) {
    transform = s_transform;

    texture = s_texture;
    color = WHITE;

    _shader = load_shader(rl.LoadShaderFromMemory(nil, WAVE_FRAG));

    freqXLoc   := shader_location(_shader, "freqX");
    freqYLoc   := shader_location(_shader, "freqY");
    ampXLoc    := shader_location(_shader, "ampX");
    ampYLoc    := shader_location(_shader, "ampY");
    speedXLoc  := shader_location(_shader, "speedX");
    speedYLoc  := shader_location(_shader, "speedY");

    freq_x = 25;
    freq_y = 25;
    amp_x = 8;
    amp_y = 8;
    speed_x = 5;
    speed_y = 5;
    size := Vec2 {f32(texture.width), f32(texture.height)};

    rl.SetShaderValue(_shader, shader_location(_shader, "size"), &size, .VEC2);
    rl.SetShaderValue(_shader, freqXLoc, &freq_x, rl.ShaderUniformDataType.FLOAT);
    rl.SetShaderValue(_shader, freqYLoc, &freq_y, rl.ShaderUniformDataType.FLOAT);
    rl.SetShaderValue(_shader, ampXLoc, &amp_x, rl.ShaderUniformDataType.FLOAT);
    rl.SetShaderValue(_shader, ampYLoc, &amp_x, rl.ShaderUniformDataType.FLOAT);
    rl.SetShaderValue(_shader, speedXLoc, &speed_x, rl.ShaderUniformDataType.FLOAT);
    rl.SetShaderValue(_shader, speedYLoc, &speed_y, rl.ShaderUniformDataType.FLOAT);

    set = f_set;
}

f_init :: proc(s_texture: Texture, s_transform: Transform) -> ^Component {
    using component := new(Component);
    
    component.variant = new(Fluid);
    f_init_all(component.variant.(^Fluid), s_texture, s_transform);

    update = f_update;
    render = f_render;
    deinit = f_deinit;

    return component;
}

f_update :: proc(component: ^Component, ent: ^Entity) {
    using self := c_variant(component, ^Fluid);

    seconds := f32(rl.GetTime());
    rl.SetShaderValue(_shader, shader_location(_shader, "seconds"), &seconds, .FLOAT);
}

f_render :: proc(component: ^Component) {
    using self := c_variant(component, ^Fluid);

    render_pos := transform.position;
    render_pos.y = transform.position.y + transform.scale.y * 0.5;

    rl.BeginShaderMode(_shader);

    draw_textured_plane(
        texture, 
        render_pos, 
        transform.scale.xz, 
        transform.rotation.y,
        color
    );

    rl.EndShaderMode();
}

f_deinit :: proc(component: ^Component) {
    using self := c_variant(component, ^Fluid);

    deinit_shader(_shader);
    deinit_texture(texture);
}

f_set :: proc(using self: ^Fluid, name: string, val: f32) {
    value := val;

    rl.SetShaderValue(
        _shader, 
        shader_location(_shader, strs.clone_to_cstring(name)),
        &value, .FLOAT
    );
}
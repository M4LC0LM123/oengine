package oengine

import "core:fmt"
import rl "vendor:raylib"

MAX_LIGHTS :: 100

LightType :: enum i32 {
    DIRECTIONAL,
    POINT
}

rlLight :: struct {
    type: LightType,
    enabled: bool,
    position: Vec3,
    target: Vec3,
    color: Color,
    attenuation: f32,

    enabled_loc: rl.ShaderLocationIndex,
    type_loc: rl.ShaderLocationIndex,
    pos_loc: rl.ShaderLocationIndex,
    target_loc: rl.ShaderLocationIndex,
    color_loc: rl.ShaderLocationIndex,
    attenuation_loc: rl.ShaderLocationIndex,
}

DEFAULT_LIGHT: Shader;
light_count := 0;

create_light :: proc(type: LightType, position, target: Vec3, color: Color) -> rlLight {
    light: rlLight;

    if (light_count < MAX_LIGHTS) {
        light.enabled = true;
        light.type = type;
        light.position = position;
        light.target = target;
        light.color = color;

        light.enabled_loc = shader_location(DEFAULT_LIGHT, rl.TextFormat("lights[%v].enabled", light_count));
        light.type_loc = shader_location(DEFAULT_LIGHT, rl.TextFormat("lights[%v].type", light_count));
        light.pos_loc = shader_location(DEFAULT_LIGHT, rl.TextFormat("lights[%v].position", light_count));
        light.target_loc = shader_location(DEFAULT_LIGHT, rl.TextFormat("lights[%v].target", light_count));
        light.color_loc = shader_location(DEFAULT_LIGHT, rl.TextFormat("lights[%v].color", light_count));

        update_light(light);
        
        light_count += 1;
    }

    return light;
}

@(private)
init_lights_global :: proc() {
    DEFAULT_LIGHT = load_shader(rl.LoadShaderFromMemory(LIGHT_VERT, LIGHT_FRAG));
    DEFAULT_LIGHT.locs[rl.ShaderLocationIndex.VECTOR_VIEW] = i32(rl.GetShaderLocation(DEFAULT_LIGHT, "viewPos"));

    ambient_loc := rl.GetShaderLocation(DEFAULT_LIGHT, "ambient");
    ambient := Vec4 {0.2, 0.2, 0.2, 0.7};
    rl.SetShaderValue(
        DEFAULT_LIGHT, rl.ShaderLocationIndex(ambient_loc), 
        &ambient, rl.ShaderUniformDataType.VEC4
    );
}

@(private)
update_light :: proc(light: rlLight) {
    enabled := i32(light.enabled);
    rl.SetShaderValue(DEFAULT_LIGHT, light.enabled_loc, &enabled, rl.ShaderUniformDataType.INT);

    type := i32(light.type);
    rl.SetShaderValue(DEFAULT_LIGHT, light.type_loc, &type, rl.ShaderUniformDataType.INT);

    pos := light.position;
    rl.SetShaderValue(DEFAULT_LIGHT, light.pos_loc, &pos, rl.ShaderUniformDataType.VEC3);

    tar := light.target;
    rl.SetShaderValue(DEFAULT_LIGHT, light.target_loc, &tar, rl.ShaderUniformDataType.VEC3);

    clr := clr_to_arr(light.color, f32) / f32(255);
    rl.SetShaderValue(DEFAULT_LIGHT, light.color_loc, &clr, rl.ShaderUniformDataType.VEC4);
}

@(private)
update_lights_global :: proc(camera: Camera) {
    camera_pos := camera.position;

    rl.SetShaderValue(
        DEFAULT_LIGHT, 
        rl.ShaderLocationIndex(DEFAULT_LIGHT.locs[rl.ShaderLocationIndex.VECTOR_VIEW]), 
        &camera_pos, rl.ShaderUniformDataType.VEC3
    );
}

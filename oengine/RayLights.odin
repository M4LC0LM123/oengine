package oengine

import rl "vendor:raylib"
import "core:math"

RAY_MAX_LIGHTS :: 16

RayContext :: struct {
    light_count: i32,
    shader: Shader,
}

RayLight :: struct {
    type:           RayLightType,
    enabled:        bool,
    position:       [3]f32,
    target:         [3]f32,
    color:          rl.Color,
    intensity:      f32,
    attenuation:    f32,
    enabledLoc:     i32,
    typeLoc:        i32,
    positionLoc:    i32,
    targetLoc:      i32,
    colorLoc:       i32,
    attenuationLoc: i32,
    inner_loc:      i32,
    outer_loc:      i32,
    intensity_loc:  i32,
}

RayLightType :: enum i32 {
    Directional,
    Point,
    Spot,
}

ray_create_light :: proc(#any_int id: i32, type: RayLightType, position, target: [3]f32, color: rl.Color, shader: rl.Shader, intensity: f32 = 1) -> (light: RayLight) {
    if id < RAY_MAX_LIGHTS {
        light.enabled = true
        light.type = type
        light.position = position
        light.target = target
        light.color = color
        light.intensity = intensity;

        light.enabledLoc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].enabled", id)))
        light.typeLoc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].type", id)))
        light.positionLoc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].position", id)))
        light.targetLoc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].target", id)))
        light.colorLoc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].color", id)))
        light.inner_loc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].inner_cutoff", id)));
        light.outer_loc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].outer_cutoff", id)));
        light.intensity_loc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].intensity", id)));

        update_light_values(shader, light)
    }

    return
}

ray_light_cutoffs :: proc(shader: rl.Shader, light: RayLight, inner, outer: f32) {
    inner_cos := math.cos(inner * Deg2Rad);
    outer_cos := math.cos(outer * Deg2Rad);

    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.inner_loc), &inner_cos, .FLOAT);
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.outer_loc), &outer_cos, .FLOAT);
}

update_light_count :: proc(shader: rl.Shader, count: i32) {
    loc := rl.GetShaderLocation(shader, "light_count");

    count := count;
    rl.SetShaderValue(shader, loc, &count, .INT);
}

ray_fog_color :: proc(shader: rl.Shader, color: Color) {
    color_loc := shader_location(shader, "fogColor");

    color_f := Vec4 {
        f32(color.r) / 255,
        f32(color.g) / 255,
        f32(color.b) / 255,
        f32(color.a) / 255,
    };

    rl.SetShaderValue(shader, color_loc, &color_f, .VEC4);
}

ray_fog_density :: proc(shader: rl.Shader, density: f32) {
    density_loc := shader_location(shader, "fogDensity");
    density_v := density;

    rl.SetShaderValue(shader, density_loc, &density_v, .FLOAT);
}

ray_ambient :: proc(shader: rl.Shader, ambient: Color) {
    ambient_loc := rl.GetShaderLocation(shader, "ambient");
    ambient_val := Vec4 {
        f32(ambient.r) / 255,
        f32(ambient.g) / 255,
        f32(ambient.b) / 255,
        f32(ambient.a) / 255,
    };
    rl.SetShaderValue(shader, ambient_loc, &ambient_val, .VEC4);
}

ray_view_loc :: proc(shader: rl.Shader) {
    shader.locs[rl.ShaderLocationIndex.VECTOR_VIEW] = i32(rl.GetShaderLocation(shader, "viewPos"));
}

ray_set_view :: proc(shader: rl.Shader, camera: Camera) {
    position := camera.position;

    rl.SetShaderValue(
        shader, 
        rl.ShaderLocationIndex(shader.locs[rl.ShaderLocationIndex.VECTOR_VIEW]), 
        &position, 
        .VEC3
    );
}

update_light_values :: proc(shader: rl.Shader, light: RayLight) {
    light := light

    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.enabledLoc), &light.enabled, .INT)
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.typeLoc), &light.type, .INT)

    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.positionLoc), &light.position, .VEC3)

    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.targetLoc), &light.target, .VEC3)

    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.intensity_loc), &light.intensity, .FLOAT);

    color := [4]f32{ f32(light.color.r)/255, f32(light.color.g)/255, f32(light.color.b)/255, f32(light.color.a)/255 }
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(light.colorLoc), &color, .VEC4)
}

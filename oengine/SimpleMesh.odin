package oengine

import "core:math"
import "core:fmt"
import rl "vendor:raylib"
import ecs "ecs"

Sprite :: struct {
    src: rl.Rectangle,
    up: Vec3,
    size, origin: Vec2,
    rotation: f32,
}

sprite_default :: proc(texture: Texture) -> Sprite {
    return Sprite {
        src = {0, 0, f32(texture.width), f32(texture.height)},
        up = vec3_y(),
        size = {1, 1},
        origin = {f32(texture.width) * 0.5, f32(texture.height) * 0.5},
        rotation = 0,
    };
}

SimpleMesh :: struct {
    transform: Transform,
    shape: ShapeType,
    
    tex: union {
        Model,
        CubeMap,
        Slope,
        Sprite,
    },

    is_lit: bool,
    use_fog: bool,
    texture: Texture,
    color: Color,
    starting_color: Color,
    shader: Shader,
}

sm_init :: proc {
    sm_init_def,
    sm_init_tex,
    sm_init_cube,
    sm_init_model,
    sm_init_slope,
    sm_init_sprite,
}

@(private = "file")
sm_init_all :: proc(using sm: ^SimpleMesh, s_shape: ShapeType, s_color: Color) {
    transform = transform_default();
    shape = s_shape;

    if (int(shape) < 10) {
        tex = mesh_loaders[int(shape)]();
    }

    is_lit = true;
    use_fog = OE_FAE;
    texture = load_texture(rl.LoadTextureFromImage(rl.GenImageColor(16, 16, WHITE)));
    color = s_color;
    starting_color = color;
}

sm_init_def :: proc(s_shape: ShapeType = .BOX, s_color: Color = rl.WHITE) -> SimpleMesh {
    sm: SimpleMesh;

    sm_init_all(&sm, s_shape, s_color);

    return sm;
}

sm_init_tex :: proc(s_texture: Texture, s_shape: ShapeType = .BOX, s_color: Color = rl.WHITE) -> SimpleMesh {
    sm: SimpleMesh;

    sm_init_all(&sm, s_shape, s_color);
    sm.texture = s_texture;
    sm.tex.(Model).materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = s_texture.data;

    return sm;
}

sm_init_cube :: proc(cube_map: CubeMap, s_color: Color = rl.WHITE) -> SimpleMesh {
    sm: SimpleMesh;

    sm_init_all(&sm, .CUBEMAP, s_color);
    sm.tex = cube_map;

    return sm;
}

sm_init_model :: proc(model: Model, s_color: Color = rl.WHITE) -> SimpleMesh {
    sm: SimpleMesh;

    sm_init_all(&sm, .MODEL, s_color);
    sm.tex = model;

    return sm;
}

sm_init_slope :: proc(slope: Slope, s_color: Color = rl.WHITE) -> SimpleMesh {
    sm: SimpleMesh;

    sm_init_all(&sm, .SLOPE, s_color);
    sm.tex = slope;

    return sm;
}

// temp fix, since the sm_init_tex can also take only a texture as parameter here 
// you have to pass .SPRITE or any int to distinguish it from sm_init_tex
sm_init_sprite :: proc(s_texture: Texture, #any_int i: i32, s_color: Color = rl.WHITE) -> SimpleMesh {
    sm: SimpleMesh;

    sm_init_all(&sm, .SPRITE, s_color);
    sm.texture = s_texture;
    sm.tex = sprite_default(s_texture);

    return sm;
}

sm_render :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    t, sm:= ecs.get_components(ent, Transform, SimpleMesh);
    if (is_nil(t, sm)) do return;
    using sm;

    transform = t^;

    if (ecs_world.FAE && use_fog) {
        color = mix_color(world_fog.color, starting_color, world_fog.visibility); 
    }

    target := transform;

    if (sys_os() == .Linux && shape == .CYLINDER) {
        target.position.y = transform.position.y - 0.5;
    }

    if (!sm_tex_is(sm, Model)) {
        if (shader_defined(shader)) {
            rl.BeginShaderMode(shader);
        }
    }

    #partial switch v in tex {
        case Model:
            draw_model(v, target, color, is_lit);
        case CubeMap:
            draw_cube_map(v, target, color);
        case Slope:
            draw_slope(
                v, target.position,
                target.rotation, target.scale,
                texture, color,
            );
        case Sprite:
            rl.DrawBillboardPro(
                ecs_world.camera.rl_matrix, texture,
                v.src, target.position, v.up,
                v.size, v.origin, v.rotation,
                color,
            );
    }

    if (sm_tex_is(sm, Model)) do return;
    rl.EndShaderMode();
}

sm_deinit :: proc(component: ^Component) {
    using self := component.variant.(^SimpleMesh);

    #partial switch v in tex {
        case Model:
            deinit_model(v);
        case CubeMap:
            for i in 0..<6 {
                deinit_texture(v[i]);
            }
    }

    deinit_texture(texture);
    deinit_shader(shader);
}

sm_toggle_lit :: proc(using self: ^SimpleMesh) {
    is_lit = !is_lit;
}

sm_tex :: proc(using self: ^SimpleMesh, $T: typeid) -> T {
    return tex.(T);
}

sm_tex_is :: proc(using self: ^SimpleMesh, $T: typeid) -> bool {
    #partial switch v in tex {
        case T:
            return true;
    } 

    return false;
}

sm_texture :: proc(using self: ^SimpleMesh) -> Texture {
    #partial switch v in tex {
        case Model:
            return load_texture(v.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture);
    }

    return texture;
}

sm_set_texture :: proc(using self: ^SimpleMesh, s_texture: Texture) {
    texture = s_texture; 

    #partial switch v in tex {
        case Model:
            v.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = texture.data;
    }
}

sm_set_tiling :: proc {
    sm_set_tiling_def,
    sm_set_tiling_cube,
}

sm_set_tiling_def :: proc(using self: ^SimpleMesh, tx: i32) {
    sm_set_texture(self, tile_texture(texture, tx));
}

sm_set_tiling_cube :: proc(using self: ^SimpleMesh, tx: i32, side: CubeMapSide) {
    if (!sm_tex_is(self, CubeMap)) do return;

    res := sm_tex(self, CubeMap);

    if (side == .ALL) {
        for i in 0..<6 {
            res[i] = tile_texture(sm_tex(self, CubeMap)[i], tx);
        }
    } else {         
        res[side] = tile_texture(sm_tex(self, CubeMap)[side], tx);
    }

    tex = res;
}

sm_set_shader :: proc(using self: ^SimpleMesh, s_shader: Shader) {
    if (!shader_defined(s_shader)) {
        dbg_log("Shader undefined", .WARNING);
        return;
    }

    shader = s_shader;

    if (sys_os() == .Darwin) {
        dbg_log("Mac doesn't support shaders on models for now");
        return;
    }

    if (sm_tex_is(self, Model)) {
        sm_tex(self, Model).materials[0].shader = shader.data;
    }
}

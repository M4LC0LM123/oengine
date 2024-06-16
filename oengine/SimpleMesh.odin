package oengine

import "core:math"
import "core:fmt"
import rl "vendor:raylib"

SimpleMesh :: struct {
    transform: Transform,
    shape: ShapeType,
    
    tex: union {
        Model,
        CubeMap,
        Slope,
    },

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
}

@(private = "file")
sm_init_all :: proc(using sm: ^SimpleMesh, s_shape: ShapeType, s_color: Color) {
    transform = transform_default();
    shape = s_shape;

    if (int(shape) < 10) {
        tex = mesh_loaders[int(shape)]();
    }

    if (ecs_world.LAE) {
        sm_set_shader(sm, DEFAULT_LIGHT);
    }

    texture = load_texture(rl.LoadTextureFromImage(rl.GenImageColor(16, 16, WHITE)));
    color = s_color;
    starting_color = color;
}

sm_init_def :: proc(s_shape: ShapeType = .BOX, s_color: Color = rl.WHITE) -> ^Component {
    using component := new(Component);

    component.variant = new(SimpleMesh);
    sm_init_all(component.variant.(^SimpleMesh), s_shape, s_color);

    update = sm_update;
    render = sm_render;
    deinit = sm_deinit;

    return component;
}

sm_init_tex :: proc(s_texture: Texture, s_shape: ShapeType = .BOX, s_color: Color = rl.WHITE) -> ^Component {
    using component := new(Component);

    component.variant = new(SimpleMesh);
    sm_init_all(component.variant.(^SimpleMesh), s_shape, s_color);
    component.variant.(^SimpleMesh).texture = s_texture;
    component.variant.(^SimpleMesh).tex.(Model).materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = s_texture.data;

    update = sm_update;
    render = sm_render;
    deinit = sm_deinit;

    return component;
}

sm_init_cube :: proc(cube_map: CubeMap, s_color: Color = rl.WHITE) -> ^Component {
    using component := new(Component);

    component.variant = new(SimpleMesh);
    sm_init_all(component.variant.(^SimpleMesh), .CUBEMAP, s_color);
    component.variant.(^SimpleMesh).tex = cube_map;

    update = sm_update;
    render = sm_render;
    deinit = sm_deinit;

    return component;
}

sm_init_model :: proc(model: Model, s_color: Color = rl.WHITE) -> ^Component {
    using component := new(Component);

    component.variant = new(SimpleMesh);
    sm_init_all(component.variant.(^SimpleMesh), .MODEL, s_color);
    component.variant.(^SimpleMesh).tex = model;

    update = sm_update;
    render = sm_render;
    deinit = sm_deinit;

    return component;
}

sm_init_slope :: proc(slope: Slope, s_color: Color = rl.WHITE) -> ^Component {
    using component := new(Component);

    component.variant = new(SimpleMesh);
    sm_init_all(component.variant.(^SimpleMesh), .SLOPE, s_color);
    component.variant.(^SimpleMesh).tex = slope;

    update = sm_update;
    render = sm_render;
    deinit = sm_deinit;

    return component;
}

sm_update :: proc(component: ^Component, ent: ^Entity) {
    using self := component.variant.(^SimpleMesh);
    transform = ent.transform;

    if (ecs_world.FAE) {
        color = mix_color(world_fog.color, starting_color, world_fog.visibility); 
    }
}

sm_render :: proc(component: ^Component) {
    using self := component.variant.(^SimpleMesh);

    target := transform;

    if (sys_os() == .Linux && shape == .CYLINDER) {
        target.position.y = transform.position.y - 0.5;
    }

    if (!sm_tex_is(self, Model)) {
        if (shader_defined(shader)) {
            rl.BeginShaderMode(shader);
        } else {
            if (ecs_world.LAE && !sm_tex_is(self, Model)) do rl.BeginShaderMode(DEFAULT_LIGHT);
        }
    }

    #partial switch v in tex {
        case Model:
            draw_model(v, target, color);
        case CubeMap:
            draw_cube_map(v, target, color);
        case Slope:
            draw_slope(
                v, target.position,
                target.rotation, target.scale,
                texture, color,
            );
    }

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

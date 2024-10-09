package oengine

import rl "vendor:raylib"
import ecs "ecs"
import "core:fmt"

Transform :: struct {
    position: Vec3,
    rotation: Vec3,
    scale: Vec3
}

transform_default :: proc() -> Transform {
    return Transform {
        position = vec3_zero(),
        rotation = vec3_zero(),
        scale = vec3_one(),
    };
}

transform_render :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    t := ecs.get_component(ent, Transform);
    if (is_nil(t)) do return;

    if (OE_DEBUG) do draw_cube_wireframe(t.position, t.rotation, t.scale, GREEN); 
}

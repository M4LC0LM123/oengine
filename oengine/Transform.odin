package oengine

import rl "vendor:raylib"
import ecs "ecs/src"
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

transform_render :: proc(ctx: ^ecs.Context, ent: ecs.Entity) {
    t, err := ecs.get_component(ctx, ent, Transform);
    if (err != .NO_ERROR) do return;

    draw_cube_wireframe(t.position, t.rotation, t.scale, GREEN); 
}

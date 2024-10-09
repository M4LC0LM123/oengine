package main

import "core:fmt"
import ecs "../../ecs_impl"

Vec3 :: [3]int
Pos :: distinct Vec3

vec3_update :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    v := ecs.get_component(ent, Vec3);
    v^ += {1, 1, 1};
}

vec3_render :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    v := ecs.get_component(ent, Vec3);
    fmt.println(v);
}

main :: proc() {
    ctx := ecs.ecs_init();

    ecs.register_system(&ctx, vec3_update, ecs.ECS_UPDATE);
    ecs.register_system(&ctx, vec3_render, ecs.ECS_RENDER);

    ent := ecs.entity_init(&ctx);
    pos := ecs.add_component(ent, Vec3 {6, 9, 4});
    t := ecs.add_component(ent, Pos {69, 420, 0});

    for i in 0..<1000{
        ecs.ecs_update(&ctx);
        ecs.ecs_render(&ctx);
    }

    ecs.ecs_deinit(&ctx);
}

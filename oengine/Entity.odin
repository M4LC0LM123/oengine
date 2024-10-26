package oengine

import "core:fmt"
import ecs "ecs"
import rl "vendor:raylib"

AEntity :: ^ecs.Entity

aent_init :: proc(tag: string = "Entity") -> AEntity {
    res := ecs.entity_init(&ecs_world.ecs_ctx);
    res.tag = tag;

    add_component(res, transform_default());

    return res;
}

add_component :: proc(ent: AEntity, component: $T) -> ^T {
    c := ecs.add_component(ent, component);
  
    if (type_of(component) == RigidBody) {
        append(&ecs_world.physics.bodies, cast(^RigidBody)c);
    }

    return c;
}

has_component :: proc(ent: AEntity, $T: typeid) -> bool {
    return ecs.has_component(ent, T);
}

get_component :: proc(ent: AEntity, $T: typeid) -> ^T {
    c := ecs.get_component(ent, T);
    return c;
}

remove_component :: proc(ent: AEntity, $T: typeid) {
    ecs.remove_component(ent, T);
}

aent_deinit :: proc(ent: AEntity) {
    ecs.ecs_remove(&ecs_world.ecs_ctx, ent);
}


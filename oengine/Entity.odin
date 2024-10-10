package oengine

import "core:fmt"
import ecs "ecs"
import rl "vendor:raylib"

AEntity :: struct {
    data: ^ecs.Entity,
    tag: string,
}

aent_init :: proc(tag: string = "Entity") -> AEntity {
    res := AEntity {
        data = ecs.entity_init(&ecs_world.ecs_ctx),
        tag = tag,
    };

    add_component(res, transform_default());

    return res;
}

add_component :: proc(ent: AEntity, component: $T) -> ^T {
    c := ecs.add_component(ent.data, component);
  
    if (type_of(component) == RigidBody) {
        append(&ecs_world.physics.bodies, cast(^RigidBody)c);
    }

    return c;
}

has_component :: proc(ent: AEntity, $T: typeid) -> bool {
    return ecs.has_component(ent.data, T);
}

get_component :: proc(ent: AEntity, $T: typeid) -> ^T {
    c := ecs.get_component(ent.data, T);
    return c;
}

remove_component :: proc(ent: AEntity, $T: typeid) {
    ecs.remove_component(ent.data, T);
}

aent_deinit :: proc(ent: AEntity) {
    ecs.ecs_remove(&ecs_world.ecs_ctx, ent.data);
}


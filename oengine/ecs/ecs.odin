package ecs

import "core:fmt"
import "../fa"

MAX_ENTS :: 2048
MAX_SYS :: 64

Context :: struct {
    entities: fa.FixedArray(^Entity, MAX_ENTS),
    _update_systems: fa.FixedArray(SystemFunc, MAX_SYS),
    _render_systems: fa.FixedArray(SystemFunc, MAX_SYS),
}

ecs_init :: proc() -> Context {
    return Context {
        entities = fa.fixed_array(^Entity, MAX_ENTS),
        _update_systems = fa.fixed_array(SystemFunc, MAX_SYS),
        _render_systems = fa.fixed_array(SystemFunc, MAX_SYS),
    };
}

register_system :: proc(ctx: ^Context, sys: SystemFunc, #any_int render: i32) {
    if (!bool(render)) { 
        fa.append(&ctx._update_systems, sys); 
        return;
    }

    fa.append(&ctx._render_systems, sys);
}

ecs_update :: proc(ctx: ^Context) {
    using ctx;
    for i in 0..<fa.range(entities) {
        entity := entities.data[i];
        for j in 0..<fa.range(_update_systems) {
            system := _update_systems.data[j];
            system(ctx, entity);
        }
    }
}

ecs_render :: proc(ctx: ^Context) {
    using ctx;
    for i in 0..<fa.range(entities) {
        entity := entities.data[i];
        for j in 0..<fa.range(_render_systems) {
            system := _render_systems.data[j];
            system(ctx, entity);
        }
    }
}

ecs_remove :: proc(ctx: ^Context, ent: ^Entity) {
    fa.remove_arr(&ctx.entities, int(ent.id));
}

ecs_deinit :: proc(ctx: ^Context) {
}

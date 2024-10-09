package ecs

import "core:fmt"

Context :: struct {
    entities: [dynamic]^Entity,
    _update_systems: [dynamic]SystemFunc,
    _render_systems: [dynamic]SystemFunc,
}

ecs_init :: proc() -> Context {
    return Context {
        entities = make([dynamic]^Entity),
        _update_systems = make([dynamic]SystemFunc),
        _render_systems = make([dynamic]SystemFunc),
    };
}

register_system :: proc(ctx: ^Context, sys: SystemFunc, #any_int render: i32) {
    if (!bool(render)) { 
        append(&ctx._update_systems, sys); 
        return;
    }

    append(&ctx._render_systems, sys);
}

ecs_update :: proc(ctx: ^Context) {
    using ctx;
    for entity in entities {
        for system in _update_systems {
            system(ctx, entity);
        }
    }
}

ecs_render :: proc(ctx: ^Context) {
    using ctx;
    for entity in entities {
        for system in _render_systems {
            system(ctx, entity);
        }
    }
}

ecs_remove :: proc(ctx: ^Context, ent: ^Entity) {
    ordered_remove(&ctx.entities, int(ent.id));
}

ecs_deinit :: proc(ctx: ^Context) {
    delete(ctx.entities);
    delete(ctx._update_systems);
    delete(ctx._render_systems);
}

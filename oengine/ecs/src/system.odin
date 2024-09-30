package ecs

System :: struct {
    required_components: []typeid,
    system_proc: proc(^Context, Entity),
}

register_system :: proc(ctx: ^Context, required_components: []typeid, system_proc: proc(^Context, Entity)) {
  system := System{
    required_components = required_components,
    system_proc = system_proc,
  }
  append_elem(&ctx.systems, system)
}

run_systems :: proc(ctx: ^Context) {
  for system in ctx.systems {
    entities := get_entities_with_components(ctx, system.required_components)
    
    if len(entities) > 0 {
      for ent in entities {
        system.system_proc(ctx, ent)
      }
    }
  }
}

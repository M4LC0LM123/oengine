package oengine

import rl "vendor:raylib"
import "core:fmt"

FIXED_TIME_STEP :: 1.0 / 60.0

ecs_world: struct {
    ents: map[string]^Entity,
    physics: PhysicsWorld,
    camera: ^Camera,
    LAE: bool, // lights affect everything
    FAE: bool, // fog affects everything

    accumulator: f32,
}

ew_get_entity :: proc(tag: string) -> ^Entity {
    using ecs_world;
    ent := ents[tag];
    if (ent == nil) do dbg_log(str_add({"Entity: ", tag, " is nil"}), .WARNING);

    return ent;
}

ew_exists :: proc(tag: string) -> bool {
    return ecs_world.ents[tag] != nil;
}

ew_init :: proc(s_gravity: Vec3, s_iter: i32 = 15) {
    using ecs_world;
    ents = make(map[string]^Entity);
    asset_manager.registry = make(map[string]Asset);
    pw_init(&physics, s_gravity, s_iter);

    accumulator = 0;
    
    if (OE_USE_LIGHTS) {
        init_lights_global();
    }


    LAE = true;
    FAE = false;

    world_fog.density = 0.007;
    world_fog.gradient = 1.5;
}

ew_update :: proc() {
    using ecs_world;
    ew_fixed_update();

    if (OE_USE_LIGHTS) do update_lights_global(camera^);
    fog_update(camera.position);

    for tag in ents {
        ent := ew_get_entity(tag);
        ent->update();
    }

    // if (!w_transform_changed()) do pw_update(&physics, rl.GetFrameTime());
}

@(private = "file")
ew_fixed_update :: proc() {
    using ecs_world;

    dt := rl.GetFrameTime();
    accumulator += dt;

    for (accumulator >= FIXED_TIME_STEP) {
        if (!w_transform_changed() && window.instance_name != "oengine-editor") {
            pw_update(&physics, FIXED_TIME_STEP);
        }
        accumulator -= FIXED_TIME_STEP;
    }
}

ew_render :: proc() {
    using ecs_world;

    rl.rlEnableBackfaceCulling();
    if (PHYS_DEBUG) {
        draw_cube_wireframe(
            {physics.tree._bounds.x, physics.tree._bounds.y, physics.tree._bounds.z},
            vec3_zero(),
            {physics.tree._bounds.width, physics.tree._bounds.height, physics.tree._bounds.depth},
            rl.GREEN,
        )
    }

    for tag in ents {
        ent := ew_get_entity(tag);
        ent->render();
    }

    rl.rlDisableBackfaceCulling();
    for msc in physics.mscs {
        msc_render(msc);
    }
}

ew_deinit :: proc() {
    using ecs_world;
    if (OE_USE_LIGHTS) do rl.UnloadShader(DEFAULT_LIGHT);

    pw_deinit(&physics);

    delete(asset_manager.registry);
    delete(ents);
}

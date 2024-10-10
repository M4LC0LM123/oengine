package oengine

import rl "vendor:raylib"
import rlg "rllights"
import ecs "ecs"
import "core:fmt"
import "core:thread"

MAX_LIGHTS :: 44
FIXED_TIME_STEP :: 1.0 / 60.0

ecs_world: struct {
    ecs_ctx: ecs.Context,
    physics: PhysicsWorld,
    camera: ^Camera,
    rlg_ctx: rlg.Context,
    light_count: u32,
    FAE: bool, // fog affects everything

    accumulator: f32,
}

ew_init :: proc(s_gravity: Vec3, s_iter: i32 = 15) {
    using ecs_world;
    ecs_ctx = ecs.ecs_init();

    asset_manager.registry = make(map[string]Asset);
    pw_init(&physics, s_gravity, s_iter);

    accumulator = 0;

    rlg_ctx = rlg.CreateContext(MAX_LIGHTS);
    rlg.SetContext(rlg_ctx);

    FAE = true;
    world_fog.density = 0.007;
    world_fog.gradient = 1.5;

    img := rl.GenImageGradientLinear(128, 64, 0, WHITE, BLACK);
    tag_image = load_texture(rl.LoadTextureFromImage(img));

    ecs.register_system(&ecs_ctx, rb_update, ecs.ECS_UPDATE);
    ecs.register_system(&ecs_ctx, lc_update, ecs.ECS_UPDATE);
    ecs.register_system(&ecs_ctx, ps_update, ecs.ECS_UPDATE);

    ecs.register_system(&ecs_ctx, ps_render, ecs.ECS_RENDER);
    ecs.register_system(&ecs_ctx, sm_render, ecs.ECS_RENDER);
    ecs.register_system(&ecs_ctx, f_render, ecs.ECS_RENDER);

    if (OE_DEBUG) {
        ecs.register_system(&ecs_ctx, rb_render, ecs.ECS_RENDER);
    }

    if (PHYS_DEBUG) {
        ecs.register_system(&ecs_ctx, transform_render, ecs.ECS_RENDER);
    }
}

ew_update :: proc() {
    using ecs_world;
    thread.run(ew_fixed_update);

    fog_update(camera.position);
    rlg.SetViewPositionV(camera.position);

    ecs.ecs_update(&ecs_ctx);
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

    ecs.ecs_render(&ecs_ctx);

    if (PHYS_DEBUG) {
        draw_cube_wireframe(
            {physics.tree._bounds.x, physics.tree._bounds.y, physics.tree._bounds.z},
            vec3_zero(),
            {physics.tree._bounds.width, physics.tree._bounds.height, physics.tree._bounds.depth},
            rl.GREEN,
        )
    }

    if (OE_DEBUG) {
        for data_id in get_reg_data_ids() { draw_data_id(data_id); }
    }

    rl.rlDisableBackfaceCulling();
    for msc in physics.mscs {
        msc_render(msc);
    }
}

ew_deinit :: proc() {
    using ecs_world;

    rlg.DestroyContext(rlg_ctx);

    ecs.ecs_deinit(&ecs_ctx);

    pw_deinit(&physics);

    deinit_assets();

    delete(asset_manager.registry);
}

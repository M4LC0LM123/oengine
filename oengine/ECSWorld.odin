package oengine

import rl "vendor:raylib"
import rlg "rllights"
import ecs "ecs"
import "fa"
import "core:fmt"
import "core:thread"
import "nfd"

MAX_LIGHTS :: 44
FIXED_TIME_STEP :: 1.0 / 60.0

ecs_world: struct {
    ecs_ctx: ecs.Context,
    physics: PhysicsWorld,
    camera: ^Camera,
    rlg_ctx: rlg.Context,
    decals: [dynamic]^Decal,
    light_count: u32,
    FAE: bool, // fog affects everything

    accumulator: f32,
    physics_thread: ^thread.Thread,
}

ew_init :: proc(s_gravity: Vec3, s_iter: i32 = 8) {
    using ecs_world;
    ecs_ctx = ecs.ecs_init();

    asset_manager.registry = make(map[string]Asset);
    asset_manager.component_types = make(map[ComponentParse]typeid);
    asset_manager.component_loaders = make(map[string]LoaderFunc);
    asset_manager.component_reg = make(map[ComponentType]rawptr);
    pw_init(&physics, s_gravity, s_iter);

    nfd.Init();

    accumulator = 0;

    rlg_ctx = rlg.CreateContext(MAX_LIGHTS);
    rlg.SetContext(rlg_ctx);

    FAE = true;
    world_fog.density = 0.007;
    world_fog.gradient = 1.5;

    img := rl.GenImageGradientLinear(128, 64, 0, WHITE, BLACK);
    tag_image = load_texture(rl.LoadTextureFromImage(img));

    decals = make([dynamic]^Decal);

    reg_component(Transform, transform_parse);
    reg_component(RigidBody, rb_parse, rb_loader);
    reg_component(SimpleMesh, sm_parse, sm_loader);
    reg_component(Light, lc_parse, lc_loader);
    reg_component(Particles, ps_parse, ps_loader);
    reg_component(SpatialAudio, sa_parse, sa_loader);
    reg_component(Fluid, f_parse, f_loader);

    ecs.register_system(&ecs_ctx, rb_update, ecs.ECS_UPDATE);
    ecs.register_system(&ecs_ctx, lc_update, ecs.ECS_UPDATE);
    ecs.register_system(&ecs_ctx, ps_update, ecs.ECS_UPDATE);
    ecs.register_system(&ecs_ctx, sa_update, ecs.ECS_UPDATE);

    ecs.register_system(&ecs_ctx, ps_render, ecs.ECS_RENDER);
    ecs.register_system(&ecs_ctx, sm_render, ecs.ECS_RENDER);
    ecs.register_system(&ecs_ctx, f_render, ecs.ECS_RENDER);

    if (OE_DEBUG) {
        ecs.register_system(&ecs_ctx, rb_render, ecs.ECS_RENDER);
    }

    if (PHYS_DEBUG) {
        ecs.register_system(&ecs_ctx, transform_render, ecs.ECS_RENDER);
    }

    physics_thread = thread.create_and_start(ew_fixed_thread);
}

ew_get_ent :: proc {
    ew_get_ent_id,
    ew_get_ent_tag,
}

ew_get_ent_id :: proc(#any_int id: u32) -> AEntity {
    return ecs_world.ecs_ctx.entities.data[int(id)];
}

ew_get_ent_tag :: proc(tag: string) -> AEntity {
    using ecs_world;

    for i in 0..<fa.range(ecs_ctx.entities) {
        ent := ecs_ctx.entities.data[i];
        if (ent.tag == tag) do return ent;
    }

    return nil;
}

ew_get_ents :: proc(tag: string) -> []AEntity {
    using ecs_world;

    count: i32;
    for i in 0..<fa.range(ecs_ctx.entities) {
        ent := ecs_ctx.entities.data[i];
        if (ent.tag == tag) {
            count += 1;
        }
    }

    res := make([]AEntity, count);
    j: i32;
    for i in 0..<fa.range(ecs_ctx.entities) {
        ent := ecs_ctx.entities.data[i];
        if (ent.tag == tag) {
            res[j] = ent;
            j += 1;
        }
    }

    return res;
}

ew_update :: proc() {
    using ecs_world;
    // t := thread.create_and_start(ew_fixed_update, self_cleanup = true);
    // ew_fixed_update();

    fog_update(camera.position);
    rlg.SetViewPositionV(camera.position);

    ecs.ecs_update(&ecs_ctx);
}

@(private = "file")
ew_fixed_thread :: proc() {
    using ecs_world;
    last_time := rl.GetTime();
    
    for (!rl.WindowShouldClose()) {
        current_time := rl.GetTime();
        delta_time := current_time - last_time;
        if (delta_time >= FIXED_TIME_STEP) {
            if (!w_transform_changed() && window.instance_name != "oengine-editor") {
                pw_update(&physics, FIXED_TIME_STEP);
                ecs.ecs_fixed_update(&ecs_ctx);
            }
            last_time = current_time;
        } else {
            thread.yield();
        }
    }
}

@(private = "file")
ew_fixed_update :: proc() {
    using ecs_world;

    dt := rl.GetFrameTime();
    accumulator += dt;

    for (accumulator >= FIXED_TIME_STEP) {
        if (!w_transform_changed() && window.instance_name != "oengine-editor") {
            pw_update(&physics, FIXED_TIME_STEP);
            ecs.ecs_fixed_update(&ecs_ctx);
        }
        accumulator -= FIXED_TIME_STEP;
    }
}

ew_render :: proc() {
    using ecs_world;

    rl.rlEnableBackfaceCulling();

    frustum := CameraGetFrustum(camera^, w_render_aspect());
    if (OE_DEBUG) {
        DrawFrustum(frustum, RED);
    }

    // ecs.ecs_render(&ecs_ctx, camera);
    for i in 0..<fa.range(ecs_ctx.entities) {
        entity := ecs_ctx.entities.data[i];
        tr := get_component(entity, Transform);
        bbox := aabb_to_bounding_box(trans_to_aabb(tr^));

        if (FrustumContainsBox(frustum, bbox)) {
            for j in 0..<fa.range(ecs_ctx._render_systems) {
                system := ecs_ctx._render_systems.data[j];

                system(&ecs_ctx, entity);
            }
        }
    }

    for &d in decals {
        decal_render(d^);
    }

    if (PHYS_DEBUG) {
        draw_cube_wireframe(
            {physics.tree._bounds.x, physics.tree._bounds.y, physics.tree._bounds.z},
            vec3_zero(),
            {physics.tree._bounds.width, physics.tree._bounds.height, physics.tree._bounds.depth},
            rl.GREEN,
        );
        pw_debug(physics);
    }

    if (OE_DEBUG) {
        dids := get_reg_data_ids();
        for i in 0..<len(dids) { draw_data_id(dids[i]); }
        delete(dids);
        draw_debug_axis();
    }

    rl.rlDisableBackfaceCulling();
    for i in 0..<fa.range(physics.mscs) {
        msc_render(physics.mscs.data[i]);
    }
}

ew_deinit :: proc() {
    using ecs_world;

    thread.join(physics_thread);
    thread.destroy(physics_thread);

    rlg.DestroyContext(rlg_ctx);

    nfd.Quit();

    pw_deinit(&physics);

    deinit_assets();

    delete(asset_manager.registry);
}

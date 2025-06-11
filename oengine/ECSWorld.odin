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

FOG_COLOR :: GRAY
FOG_DENSITY :: 0

ecs_world: struct {
    ecs_ctx: ecs.Context,
    physics: PhysicsWorld,
    camera: ^Camera,
    rlg_ctx: rlg.Context,
    decals: [dynamic]^Decal,
    removed_decals: [dynamic]i32,
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

    set_fog_density(FOG_DENSITY);
    set_fog_color(FOG_COLOR);

    FAE = false; // deprecated
    world_fog.density = 0.007;
    world_fog.gradient = 1.5;

    img := rl.GenImageGradientLinear(128, 64, 0, WHITE, BLACK);
    tag_image = load_texture(rl.LoadTextureFromImage(img));

    decals = make([dynamic]^Decal);
    removed_decals = make([dynamic]i32);

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

ew_toggle_physics :: proc() {
    using ecs_world;
    physics.paused = !physics.paused;
}

world :: proc() -> type_of(ecs_world) {
    return ecs_world;
}

ew_clear :: proc() {
    using ecs_world;

    rlg.DestroyContext(rlg_ctx);

    pw_deinit(&physics);

    for i in 0..<ecs_ctx.entities.len {
        ent := ecs_ctx.entities.data[i];
        for j in 0..<ent.components.len {
            type, comp := fa.map_pair(ent.components, j);

            if (type == RigidBody) { continue; }
            free(comp);
        }
        free(ent);
    }

    for i in 0..<physics.mscs.len {
        msc := physics.mscs.data[i];
        
        if (msc.tris != nil) {
            for j in 0..<len(msc.tris) {
                tri := msc.tris[j];
                free(tri);
            }
            delete(msc.tris);
        }

        if (msc.tree != nil) {
            free_octree(msc.tree);
        }

        // msc.mesh = {};
        // free(msc);
    }

    fa.clear(&ecs_ctx.entities);
    fa.clear(&physics.bodies);
    fa.clear(&physics.mscs);

    rlg_ctx = rlg.CreateContext(MAX_LIGHTS);
    rlg.SetContext(rlg_ctx);
}

ew_get_ent :: proc {
    ew_get_ent_id,
    ew_get_ent_tag,
}

ew_get_ent_id :: proc(#any_int id: u32) -> AEntity {
    for i in 0..<ecs_world.ecs_ctx.entities.len {
        ent := ecs_world.ecs_ctx.entities.data[i];
        if (ent.id == id) { return ent; }
    }

    return nil;
}

ew_get_ent_tag :: proc(tag: string) -> AEntity {
    using ecs_world;

    for i in 0..<fa.range(ecs_ctx.entities) {
        ent := ecs_ctx.entities.data[i];
        if (ent.tag == tag) do return ent;
    }

    return nil;
}

ew_remove_ent :: proc(#any_int id: u32) {
    ent := ew_get_ent(id);
    if (ent == nil) { return; }

    if (has_component(ent, RigidBody)) {
        rb := get_component(ent, RigidBody);
        rb_id := fa.get_id(ecs_world.physics.bodies, rb);

        if (rb_id != -1) {
            fa.remove(&ecs_world.physics.bodies, rb_id);
        }
    }

    ecs.ecs_remove(&ecs_world.ecs_ctx, ent);
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

    for i in removed_decals {
        if (int(i) < len(decals)) {
            ordered_remove(&decals, int(i));
        }
    }
    clear(&removed_decals);
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

    frustum := camera.frustum;
    if (OE_DEBUG) {
        DrawFrustum(frustum, RED);
    }

    // ecs.ecs_render(&ecs_ctx, camera);
    for i in 0..<fa.range(ecs_ctx.entities) {
        entity := ecs_ctx.entities.data[i];

        bbox: rl.BoundingBox;
        switch entity.frustum_type {
            case .INTERNAL:
                tr := get_component(entity, Transform)^;
                bbox = aabb_to_bounding_box(trans_to_aabb(tr));
            case .PHYSICS:
                _tr := get_component(entity, RigidBody).transform;
                bbox = aabb_to_bounding_box(trans_to_aabb(_tr));
            case .CUSTOM:
                using entity;
                aabb := AABB{
                    custom_box.x, custom_box.y, custom_box.z,
                    custom_box.width, custom_box.height, custom_box.depth
                };
                bbox = aabb_to_bounding_box(aabb);
        }

        if (OE_DEBUG) {
            rl.DrawBoundingBox(bbox, ORANGE);
        }

        if (FrustumContainsBox(frustum, bbox)) {
            for j in 0..<fa.range(ecs_ctx._render_systems) {
                system := ecs_ctx._render_systems.data[j];

                system(&ecs_ctx, entity);
            }
        }
    }

    for i in 0..<len(decals) {
        d := decals[i];
        decal_render(d, i32(i));
    }

    if (PHYS_DEBUG) {
        pw_debug(&physics);
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

ent_in_view :: proc(ent: AEntity) -> bool {
    using ecs_world;
    tr := get_component(ent, Transform);
    bbox := aabb_to_bounding_box(trans_to_aabb(tr^));

    return FrustumContainsBox(camera.frustum, bbox);
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

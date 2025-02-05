package main

import "core:fmt"
import "core:bufio"
import "core:os"
import "core:io"
import str "core:strings"
import rl "vendor:raylib"
import oe "../oengine"
import ecs "../oengine/ecs"
import fa "../oengine/fa"
import "core:math"
import "core:math/linalg"
import rlg "../oengine/rllights"
import "core:mem"

main :: proc() {
    def_allocator := context.allocator;
    track_allocator: mem.Tracking_Allocator;
    mem.tracking_allocator_init(&track_allocator, def_allocator);
    context.allocator = mem.tracking_allocator(&track_allocator);

    reset_track_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
        err := false;

        for _, value in a.allocation_map {
            fmt.printf("%v: allocated %v bytes\n", value.location, value.size);
            err = true;
        }

        mem.tracking_allocator_clear(a);
        return err;
    }

    oe.w_create();
    oe.w_set_title("gejm");
    oe.w_set_target_fps(60);
    oe.window.debug_stats = true;

    oe.ew_init(oe.vec3_y() * 50);
    oe.load_registry("../registry.json");

    camera := oe.cm_init(oe.vec3_zero());
    is_mouse_locked: bool = false;
    oe.ecs_world.camera = &camera;

    skybox := oe.get_asset_var("skybox", oe.SkyBox);
    oe.set_skybox_filtering(skybox);
    albedo := oe.get_asset_var("albedo", oe.Texture);
    orm := oe.get_asset_var("orm", oe.Texture);
    troll := oe.get_asset_var("troll", oe.Texture);
    water_tex := oe.get_asset_var("water", oe.Texture);
    jump_sfx := oe.get_asset_var("huh", oe.Sound);
    dudlic := oe.get_asset_var("dudlic", oe.Texture);
    vesna := oe.get_asset_var("vesna", oe.Texture);
    leon := oe.get_asset_var("leon", oe.Texture);
    celsium := oe.get_asset_var("celsium_man", oe.Model);
    swat := oe.get_asset_var("swat", oe.Model);
    lara := oe.get_asset_var("lara", oe.Model);

    floor := oe.aent_init("Floor");
    floor_tr := oe.get_component(floor, oe.Transform);
    floor_tr.scale = {50, 1, 50};
    floor_rb := oe.add_component(floor, oe.rb_init(floor_tr^, 1.0, 0.5, true, oe.ShapeType.BOX));
    floor_sm := oe.add_component(floor, oe.sm_init(orm));
    oe.sm_set_tiling(floor_sm, 5);

    wall := oe.aent_init();
    wall_tr := oe.get_component(wall, oe.Transform);
    wall_tr.position = {10, 5, 0};
    wall_tr.scale = {1, 10, 10};
    wall_rb := oe.add_component(wall, oe.rb_init(wall_tr^, 1.0, 0.5, true, oe.ShapeType.BOX));
    wall_sm := oe.add_component(wall, oe.sm_init(albedo));

    wall2 := oe.aent_init();
    wall2_tr := oe.get_component(wall2, oe.Transform);
    wall2_tr.position = {-10, 5, 0};
    wall2_tr.scale = {1, 10, 10};
    wall2_rb := oe.add_component(wall2, oe.rb_init(wall2_tr^, 1.0, 0.5, true, oe.ShapeType.BOX));
    wall2_sm := oe.add_component(wall2, oe.sm_init(albedo));

    player := oe.aent_init("player");
    player_tr := oe.get_component(player, oe.Transform);
    player_tr.position.y = 5;
    player_rb := oe.add_component(
        player, oe.rb_init(
            {player_tr.position - {0, 0.5, 0}, player_tr.rotation, {1, 2, 1}}, 
            1.0, 0.5, false, oe.ShapeType.BOX)
    );
    player_sm := oe.add_component(player, oe.sm_init(oe.tex_flip_vert(troll)));
    player_sm.is_lit = false;
    player_jump := oe.add_component(player, oe.sa_init(player_tr.position, jump_sfx));
    player_rb.collision_mask = oe.coll_mask(1);

    light := oe.aent_init("light");
    light_tr := oe.get_component(light, oe.Transform);
    light_tr.position.y = 5;
    light_lc := oe.add_component(light, oe.lc_init());

    water := oe.aent_init("water");
    water_tr := oe.get_component(water, oe.Transform);
    water_tr.position.z = 37.5;
    water_tr.scale = {25, 1, 25};
    water_f := oe.add_component(water, oe.f_init(water_tex));
    water_f.color.a = 125;

    sprite := oe.aent_init("sprite_test");
    sprite_tr := oe.get_component(sprite, oe.Transform);
    sprite_tr.position = {-5, 3, -10};
    sprite_sm := oe.add_component(sprite, oe.sm_init(troll, 0));
    sprite_path := oe.FollowPath {{-5, 3, -10}, {0, 3, -11}, {5, 3, -10}, {5, 3, -15}, {-5, 3, -15}, {-5, 3, -10}};

    ps := oe.aent_init("ParticleSystem");
    ps_tr := oe.get_component(ps, oe.Transform);
    ps_tr.position = {5, 3, -10};
    ps_ps := oe.add_component(ps, oe.ps_init());
    t: oe.Timer;

    msc := oe.msc_init();
    oe.msc_from_json(msc, "../assets/maps/test.json");

    msc2 := oe.msc_init();
    oe.msc_from_model(
        msc2, oe.load_model("../assets/maps/bowl.obj"), oe.vec3_z() * -35
    );

    light2 := oe.aent_init("light");
    light2_tr := oe.get_component(light2, oe.Transform);
    light2_tr.position = {0, 5, -35};
    light2_lc := oe.add_component(light2, oe.lc_init());

    animated := oe.aent_init("anim");
    animated_tr := oe.get_component(animated, oe.Transform);
    animated_tr.position = {-2.5, 4, -10};
    animated_tr.scale *= 3;
    animated_m := oe.model_clone(swat);
    animated_m.transform = rl.MatrixRotateY(-90 * oe.Deg2Rad);
    animated_sm := oe.add_component(animated, oe.sm_init(animated_m));
    animated_ma := oe.ma_load(animated_sm.tex.(oe.Model).path);

    lara_ent := oe.aent_init("lara");
    lara_tr := oe.get_component(lara_ent, oe.Transform);
    lara_tr.position = {2.5, 4, -10};
    lara_tr.scale *= 3;
    lara_sm := oe.add_component(lara_ent, oe.sm_init(oe.model_clone(swat)));
    lara_ma := oe.ma_load(lara_sm.tex.(oe.Model).path);
    lara_sm.offset.scale = {1.5, 0.75, 1.5};

    for ent in oe.ew_get_ents("light") {
        if (!oe.has_component(ent, oe.Light)) { continue; }
        ent_l := oe.get_component(ent, oe.Light);
        if (ent_l.type == .DIRECTIONAL) {
            rlg.SetLightVec3(ent_l.id, .DIRECTION, {0, -1, 0});
            rlg.SetLightValue(ent_l.id, .ENERGY, 1);
            rlg.SetLightValue(ent_l.id, .ATTENUATION_QUADRATIC, 0.01);
        }
    }

    tester := fa.fixed_array(int, 16);
    for i in  0..<5 {
        fa.append(&tester, i);
    }

    fmt.println(tester);

    fa.insert(&tester, 2, 69);

    fmt.println(tester);

    // reset_track_allocator(&track_allocator);
    for (oe.w_tick()) {
        oe.ew_update();

        // update
        mem.tracking_allocator_clear(&track_allocator);

        if (oe.key_pressed(oe.Key.ESCAPE)) {
            is_mouse_locked = !is_mouse_locked;
        }

        oe.cm_set_fps(&camera, 0.1, is_mouse_locked);
        oe.cm_set_fps_controls(&camera, 10, is_mouse_locked, true);
        oe.cm_default_fps_matrix(&camera);
        oe.cm_update(&camera);

        if (oe.key_pressed(oe.Key.RIGHT_SHIFT)) {
            player_rb.velocity.y = 15;

            oe.detach_sound_filter(.LOWPASS);
            oe.sa_play(player_jump);
            oe.attach_sound_filter(.LOWPASS);
        }

        if (oe.key_down(oe.Key.LEFT)) {
            player_rb.velocity.x = -7.5;
        } else if (oe.key_down(oe.Key.RIGHT)) {
            player_rb.velocity.x = 7.5;
        } else if (oe.key_down(oe.Key.UP)) {
            player_rb.velocity.z = -7.5;
        } else if (oe.key_down(oe.Key.DOWN)) {
            player_rb.velocity.z = 7.5;
        } else {
            player_rb.velocity.xz = {};
        }

        if (oe.key_down(oe.Key.F2)) {
            ent := oe.aent_init();
            ent_tr := oe.get_component(ent, oe.Transform);
            ent_tr.position = camera.position;
            ent_rb := oe.add_component(ent, oe.rb_init(ent_tr^, 1.0, 0.5, false, oe.ShapeType.BOX));
            ent_rb.collision_mask = oe.coll_mask(..oe.range_slice(2, oe.COLLISION_MASK_SIZE));
        }

        if (oe.key_pressed(.F3)) do oe.lc_toggle(light_lc);

        prtcl := oe.particle_init(oe.circle_spawn(1, true), slf = 10, color = oe.RED);
        oe.particle_add_behaviour(prtcl, oe.gradient_beh(oe.RED, oe.YELLOW, 200));
        oe.ps_add_particle(ps_ps, prtcl, 0.1);

        oe.sm_apply_anim(animated_sm, &animated_ma, 0);

        lara_tr.rotation.y = -oe.look_at_vec2(lara_tr.position.xz, camera.position.xz) - 90;

        SPEED :: 10
        @static timer: f32 = oe.F32_MAX;
        if (oe.play_sequence(sprite_path, &timer, SPEED, oe.delta_time())) {
            animated_tr.position, animated_tr.rotation = oe.position_sequence(
                sprite_path, SPEED, timer
            );
        } else {
            if (oe.key_pressed(.ENTER)) {
                timer = 0;
                sprite_tr.position = {-5, 3, -10};
            }
        }

        // render
        oe.w_begin_render();
        rl.ClearBackground(rl.SKYBLUE);

        rl.BeginMode3D(camera.rl_matrix);
        oe.draw_skybox(skybox, rl.WHITE);
        oe.ew_render();

        coll, info := oe.rc_is_colliding_msc(camera.raycast, msc);
        if (coll) {
            rl.DrawLine3D(info.point, info.point + info.normal, oe.RED);

            // rl.DrawSphere(info.point, 0.25, oe.RED);
            oe.draw_sprite(info.point, oe.vec2_one(), oe.look_at(info.point, info.point + info.normal), troll, oe.WHITE);
            if (oe.mouse_pressed(.LEFT)) {
                oe.new_decal(info.point, info.normal, oe.vec2_one(), "troll");
            }
        }

        rl.EndMode3D();
        oe.w_end_render();
        if (oe.key_pressed(.F4)) do reset_track_allocator(&track_allocator);
    }

    // reset_track_allocator(&track_allocator);
    oe.ew_deinit();
    oe.w_close();
}

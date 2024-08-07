package main

import "core:fmt"
import str "core:strings"
import rl "vendor:raylib"
import oe "../oengine"
import "core:math"
import "core:math/linalg"
import rlg "../oengine/rllights"

main :: proc() {
    oe.w_create();
    oe.w_set_title("gejm");
    oe.w_set_target_fps(60);
    oe.window.debug_stats = true;

    oe.ew_init(oe.vec3_y() * 50);
    oe.load_registry("registry.json");

    camera := oe.cm_init(oe.vec3_zero());
    is_mouse_locked: bool = false;
    oe.ecs_world.camera = &camera;

    skybox := oe.get_asset_var("skybox", oe.SkyBox);
    oe.set_skybox_filtering(skybox);
    albedo := oe.get_asset_var("albedo", oe.Texture);
    troll := oe.get_asset_var("troll", oe.Texture);
    water_tex := oe.get_asset_var("water", oe.Texture);
    jump_sfx := oe.get_asset_var("huh", oe.Sound);

    floor := oe.ent_init();
    oe.ent_add_component(floor, oe.rb_init(floor.starting, 1.0, 0.5, true, oe.ShapeType.BOX));
    oe.ent_add_component(floor, oe.sm_init(oe.get_asset_var("orm", oe.Texture)));
    oe.ent_set_scale(floor, {50, 1, 50});
    oe.sm_set_tiling(oe.ent_get_component_var(floor, ^oe.SimpleMesh), 10);

    wall := oe.ent_init();
    oe.ent_add_component(wall, oe.rb_init(wall.starting, 1.0, 0.5, true, oe.ShapeType.BOX));
    oe.ent_add_component(wall, oe.sm_init(albedo));
    oe.ent_set_pos(wall, {10, 5, 0});
    oe.ent_set_scale(wall, {1, 10, 10});

    wall2 := oe.ent_init();
    oe.ent_add_component(wall2, oe.rb_init(wall2.starting, 1.0, 0.5, true, oe.ShapeType.BOX));
    oe.ent_add_component(wall2, oe.sm_init(albedo));
    oe.ent_set_pos(wall2, {-10, 5, 0});
    oe.ent_set_scale(wall2, {1, 10, 10});

    slope_def := oe.Slope {
        {0, 1},
        {0, 1},
    };
    slope := oe.ent_init();
    oe.ent_add_component(slope, oe.rb_init(slope.starting, 1.0, 0.5, slope_def));
    oe.ent_add_component(slope, oe.sm_init(
        oe.ent_get_component_var(slope, ^oe.RigidBody).shape_variant.(oe.Slope)));
    oe.sm_set_texture(oe.ent_get_component_var(slope, ^oe.SimpleMesh), albedo);
    oe.ent_set_pos(slope, {-2, 3, -10})
    oe.ent_set_scale(slope, {5, 5, 5});

    slope_def2 := oe.Slope {
        {1, 0},
        {1, 0},
    };
    slope2 := oe.ent_init();
    oe.ent_add_component(slope2, oe.rb_init(slope2.starting, 1.0, 0.5, slope_def2));
    oe.ent_add_component(slope2, oe.sm_init(
        oe.ent_get_component_var(slope2, ^oe.RigidBody).shape_variant.(oe.Slope)));
    oe.sm_set_texture(oe.ent_get_component_var(slope2, ^oe.SimpleMesh), albedo);
    oe.ent_set_pos(slope2, {-2, 3, -15});
    oe.ent_set_scale(slope2, {5, 5, 5});

    slope_def3 := oe.Slope {
        {0, 0},
        {1, 1},
    };
    slope3 := oe.ent_init();
    oe.ent_add_component(slope3, oe.rb_init(slope3.starting, 1.0, 0.5, slope_def3));
    oe.ent_add_component(slope3, oe.sm_init(
        oe.ent_get_component_var(slope3, ^oe.RigidBody).shape_variant.(oe.Slope)));
    oe.sm_set_texture(oe.ent_get_component_var(slope3, ^oe.SimpleMesh), albedo);
    oe.ent_set_pos(slope3, {-2, 3, 10});
    oe.ent_set_scale(slope3, {5, 5, 5});

    slope_def4 := oe.Slope {
        {1, 1},
        {0, 0},
    };
    slope4 := oe.ent_init();
    oe.ent_add_component(slope4, oe.rb_init(slope4.starting, 1.0, 0.5, slope_def4));
    oe.ent_add_component(slope4, oe.sm_init(
        oe.ent_get_component_var(slope4, ^oe.RigidBody).shape_variant.(oe.Slope)));
    oe.sm_set_texture(oe.ent_get_component_var(slope4, ^oe.SimpleMesh), albedo);
    oe.ent_set_pos(slope4, {3, 3, 10});
    oe.ent_set_scale(slope4, {5, 5, 5});

    player := oe.ent_init("player");
    oe.ent_add_component(player, oe.rb_init(player.starting, 1.0, 0.5, false, oe.ShapeType.BOX));
    oe.ent_add_component(player, oe.sm_init(oe.tex_flip_vert(troll)));
    oe.ent_get_component_var(player, ^oe.SimpleMesh).is_lit = false;
    oe.ent_set_pos_y(player, 5);

    light := oe.ent_init("light");
    oe.ent_add_component(light, oe.lc_init());
    oe.ent_set_pos_y(light, 5);

    water := oe.ent_init("water");
    oe.ent_set_pos_z(water, 37.5);
    oe.ent_set_scale(water, {25, 1, 25});
    oe.ent_add_component(water, oe.f_init(water_tex, water.transform));

    car := oe.ent_init("car");
    oe.ent_add_component(car, oe.rb_init(car.starting, 1.0, 0.5, false, oe.ShapeType.BOX));
    oe.ent_starting_transform(car, {
        position = {15, 5, 0},
        rotation = {},
        scale = {2, 0.5, 2},
    });

    for i in 0..<4 {
        wheel := oe.ent_init("wheel");
        oe.ent_add_component(wheel, oe.rb_init(wheel.starting, 1.0, 0.5, false, oe.ShapeType.BOX));

        if (i == 0) do oe.ent_set_pos(wheel, {car.transform.position.x - 1.5, car.transform.position.y, car.transform.position.z + 1.5});
        if (i == 1) do oe.ent_set_pos(wheel, {car.transform.position.x + 1.5, car.transform.position.y, car.transform.position.z + 1.5});
        if (i == 2) do oe.ent_set_pos(wheel, {car.transform.position.x - 1.5, car.transform.position.y, car.transform.position.z - 1.5});
        if (i == 3) do oe.ent_set_pos(wheel, {car.transform.position.x + 1.5, car.transform.position.y, car.transform.position.z - 1.5});

        wheel_joint := oe.fj_init(
            oe.ent_get_component_var(car, ^oe.RigidBody),
            oe.ent_get_component_var(wheel, ^oe.RigidBody),
            wheel.transform.position,
        );
    }

    ps := oe.ent_init("ParticleSystem");
    oe.ent_set_pos(ps, {5, 3, -10});
    oe.ent_add_component(ps, oe.ps_init());
    t: oe.Timer;

    msc := oe.msc_init();
    oe.msc_from_json(msc, "../assets/maps/test.json");

    for (oe.w_tick()) {
        // update
        oe.ew_update();

        if (oe.key_pressed(oe.Key.ESCAPE)) {
            is_mouse_locked = !is_mouse_locked;
        }

        oe.cm_set_fps(&camera, 0.1, is_mouse_locked);
        oe.cm_set_fps_controls(&camera, 10, is_mouse_locked, true);
        oe.cm_default_fps_matrix(&camera);
        oe.cm_update(&camera);

        if (oe.key_pressed(oe.Key.RIGHT_SHIFT)) {
            oe.ent_get_component_var(player, ^oe.RigidBody).velocity.y = 15;

            oe.detach_sound_filter(.LOWPASS);
            oe.play_sound(jump_sfx);
            oe.attach_sound_filter(.LOWPASS);
        }

        if (oe.key_down(oe.Key.LEFT)) {
            oe.ent_get_component_var(player, ^oe.RigidBody).velocity.x = -7.5;
        } else if (oe.key_down(oe.Key.RIGHT)) {
            oe.ent_get_component_var(player, ^oe.RigidBody).velocity.x = 7.5;
        } else if (oe.key_down(oe.Key.UP)) {
            oe.ent_get_component_var(player, ^oe.RigidBody).velocity.z = -7.5;
        } else if (oe.key_down(oe.Key.DOWN)) {
            oe.ent_get_component_var(player, ^oe.RigidBody).velocity.z = 7.5;
        } else {
            oe.ent_get_component_var(player, ^oe.RigidBody).velocity.xz = {};
        }

        if (oe.key_pressed(oe.Key.F2)) {
            ent := oe.ent_init();
            oe.ent_add_component(ent, oe.rb_init(ent.starting, 1.0, 0.5, false, oe.ShapeType.BOX));
            oe.ent_set_pos(ent, camera.position);
        }

        if (oe.ew_exists("parent")) {
            ent := oe.ew_get_entity("parent");

            if (oe.key_down(oe.Key.LEFT)) {
                oe.ent_set_pos_x(ent, ent.transform.position.x - 10 * rl.GetFrameTime());
            }

            if (oe.key_down(oe.Key.RIGHT)) {
                oe.ent_set_pos_x(ent, ent.transform.position.x + 10 * rl.GetFrameTime());
            }
        }

        if (oe.key_pressed(oe.Key.F1)) {
            ent := oe.ent_init("parent");
            oe.ent_add_component(ent, oe.sm_init(troll, oe.ShapeType(rl.GetRandomValue(0, 3))));
            oe.ent_starting_transform(ent, {
                oe.vec3_x() * f32(rl.GetRandomValue(-10, 10)),
                oe.vec3_zero(),
                oe.vec3_one(),
            });

            if (ent.tag != "parent") {
                oe.ent_set_parent(ent, oe.ew_get_entity("parent"));
            }
        }

        if (oe.key_pressed(.F3)) do rlg.ToggleLight(0);

        prtcl := oe.particle_init(oe.circle_spawn(1, true), slf = 10, color = oe.RED);
        oe.particle_add_behaviour(prtcl, oe.gradient_beh(oe.RED, oe.YELLOW, 200));
        oe.ps_add_particle(oe.ent_get_component_var(ps, ^oe.Particles), prtcl, 0.1);

        // render
        oe.w_begin_render();
        rl.ClearBackground(rl.SKYBLUE);

        rl.BeginMode3D(camera.rl_matrix);
        oe.draw_skybox(skybox, rl.WHITE);
        oe.ew_render();

        coll, info := oe.rc_is_colliding_msc(camera.raycast, msc);
        if (coll) {
            rl.DrawSphere(info.point, 0.5, oe.RED);
        }

        rl.EndMode3D();
        
        oe.w_end_render();
    }

    oe.ew_deinit();
    oe.w_close();
}

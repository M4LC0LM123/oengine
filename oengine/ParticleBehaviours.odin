package oengine

import "core:fmt"
import rl "vendor:raylib"

get_particle_data :: proc(data: rawptr, $T: typeid) -> ^T {
    return cast(^T)data;
}

GradientBehaviourData :: struct {
    clr_a, clr_b: Color,
    speed: f32,
}

gradient_beh :: proc(s_clr_a, s_clr_b: Color, s_speed: f32 = 100) -> ParticleBehaviour {
    pb_data := GradientBehaviourData {
        clr_a = s_clr_a,
        clr_b = s_clr_b,
        speed = s_speed,
    };

    return ParticleBehaviour {
        data = new_clone(pb_data),
        behave = proc(using self: ^ParticleBehaviour, p: ^Particle) {
            gh_data := get_particle_data(data, GradientBehaviourData);

            p.tint = {gh_data.clr_a.r, gh_data.clr_a.g, gh_data.clr_a.b, p.tint.a};

            if (gh_data.clr_a == gh_data.clr_b) do return;

            delta_r := i32(gh_data.clr_b.r) - i32(gh_data.clr_a.r);
            delta_g := i32(gh_data.clr_b.g) - i32(gh_data.clr_a.g);
            delta_b := i32(gh_data.clr_b.b) - i32(gh_data.clr_a.b);

            adjust := proc(speed: f32, comp: u8, delta: i32) -> u8 {
                step := i32(speed * rl.GetFrameTime());
                if delta < 0 {
                    return max(comp - u8(min(-delta, step)), 0);
                } else {
                    return min(comp + u8(min(delta, step)), 255);
                }
            };

            gh_data.clr_a.r = adjust(gh_data.speed, gh_data.clr_a.r, delta_r);
            gh_data.clr_a.g = adjust(gh_data.speed, gh_data.clr_a.g, delta_g);
            gh_data.clr_a.b = adjust(gh_data.speed, gh_data.clr_a.b, delta_b);
        }
    };
}

decay_beh :: proc(color: Color, s_speed: f32 = 100) -> ParticleBehaviour {
    return gradient_beh(color, BLANK, s_speed);
}

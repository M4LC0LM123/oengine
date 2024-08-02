package oengine

import "core:fmt"
import rl "vendor:raylib"

GradientBehaviourData :: struct {
    clr_a, clr_b: Color,
    speed: f32,
}

gradient_beh :: proc(s_clr_a, s_clr_b: Color, s_speed: f32 = 100) -> ParticleBehaviour {
    pb_data := new(GradientBehaviourData);
    pb_data.clr_a = s_clr_a;
    pb_data.clr_b = s_clr_b;
    pb_data.speed = s_speed;

    return ParticleBehaviour {
        data = pb_data,
        behave = proc(using self: ^ParticleBehaviour, p: ^Particle) {
            gh_data_ptr := cast(^GradientBehaviourData)data;
            gh_data := gh_data_ptr^;

            if (gh_data.clr_a.r > gh_data.clr_b.r) {
                gh_data.clr_a.r -= u8(gh_data.speed * rl.GetFrameTime());
            }
            if (gh_data.clr_a.g > gh_data.clr_b.g) {
                gh_data.clr_a.g -= u8(gh_data.speed * rl.GetFrameTime());
            }
            if (gh_data.clr_a.b > gh_data.clr_b.b) {
                gh_data.clr_a.b -= u8(gh_data.speed * rl.GetFrameTime());
            }

            if (gh_data.clr_a.r < gh_data.clr_b.r) {
                gh_data.clr_a.r += u8(gh_data.speed * rl.GetFrameTime());
            }
            if (gh_data.clr_a.g < gh_data.clr_b.g) {
                gh_data.clr_a.g += u8(gh_data.speed * rl.GetFrameTime());
            }
            if (gh_data.clr_a.b < gh_data.clr_b.b) {
                gh_data.clr_a.b += u8(gh_data.speed * rl.GetFrameTime());
            }

            p.tint = {gh_data.clr_a.r, gh_data.clr_a.g, gh_data.clr_a.b, p.tint.a};
        }
    };
}

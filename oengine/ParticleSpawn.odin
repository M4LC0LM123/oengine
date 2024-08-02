package oengine

import "core:math"
import "core:math/rand"

cube_spawn :: proc(w, h, d: f32) -> Vec3 {
    return Vec3 {
        rand_val((-w * 0.5), (w * 0.5)),
        rand_val((-h * 0.5), (h * 0.5)),
        rand_val((-d * 0.5), (d * 0.5))
    };
}

circle_spawn :: proc(r: f32, z_axis: bool = false) -> Vec3 {
    angle := rand.float32() * 2 * math.PI;
    rand_radius := math.sqrt(rand.float32()) * r;

    x := rand_radius * math.cos(angle);
    y := rand_radius * math.sin(angle);

    if (z_axis) do return Vec3 {x, y, 0};
    return Vec3 {x, 0, y};
}

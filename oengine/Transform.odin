package oengine

import rl "vendor:raylib"

Transform :: struct {
    position: Vec3,
    rotation: Vec3,
    scale: Vec3
}

transform_default :: proc() -> Transform {
    return Transform {
        position = vec3_zero(),
        rotation = vec3_zero(),
        scale = vec3_one(),
    };
}
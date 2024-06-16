package oengine

import rl "vendor:raylib"

Transform :: struct {
    position: rl.Vector3,
    rotation: rl.Vector3,
    scale: rl.Vector3
}

transform_default :: proc() -> Transform {
    return Transform {
        position = vec3_zero(),
        rotation = vec3_zero(),
        scale = vec3_one(),
    };
}
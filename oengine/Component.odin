package oengine

import rl "vendor:raylib"
import "core:fmt"

Component :: struct {
    variant: union {
        ^RigidBody,
        ^SimpleMesh,
        ^Light,
        ^Fluid,
    },
    
    update: proc(using self: ^Component, ent: ^Entity),
    render: proc(using self: ^Component),
    deinit: proc(using self: ^Component),
}

c_variant :: proc(using self: ^Component, $T: typeid) -> T {
    return variant.(T);
}

c_variant_is :: proc(using self: ^Component, $T: typeid) -> bool {
    #partial switch v in variant {
        case T:
            return true;
    }

    return false;
}

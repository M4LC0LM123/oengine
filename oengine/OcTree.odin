package oengine

import "core:fmt"
import rl "vendor:raylib"
import "fa"

MAX_CAPACITY :: 10 // max entity count in octree quad
MAX_LEVELS :: 6 // max subdivision level
MAX_CHILDREN :: 8

OcTree :: struct {
    _level: i32,
    _rbs: fa.FixedArray(^RigidBody, MAX_CAPACITY),
    _bounds: AABB,
    _children: [dynamic]OcTree,
}

oct_init :: proc(level: i32, bounds: AABB) -> OcTree {
    return OcTree {
        _level = level,
        _rbs = fa.fixed_array(^RigidBody, MAX_CAPACITY),
        _bounds = bounds,
        _children = make([dynamic]OcTree, MAX_CHILDREN),
    };
}

oct_subdivide :: proc(using self: ^OcTree) {
    subWidth: f32 = _bounds.width / 2.0;
    subHeight: f32 = _bounds.height / 2.0;
    subLength: f32 = _bounds.depth / 2.0;
    x: f32 = _bounds.x;
    y: f32 = _bounds.y;
    z: f32 = _bounds.z;

    append(&_children, oct_init(_level + 1, AABB { x, y, z, subWidth, subHeight, subLength }));
    append(&_children, oct_init(_level + 1, AABB { x + subWidth, y, z, subWidth, subHeight, subLength }));
    append(&_children, oct_init(_level + 1, AABB { x, y + subHeight, z, subWidth, subHeight, subLength }));
    append(&_children, oct_init(_level + 1, AABB { x + subWidth, y + subHeight, z, subWidth, subHeight, subLength }));
    append(&_children, oct_init(_level + 1, AABB { x, y, z + subLength, subWidth, subHeight, subLength }));
    append(&_children, oct_init(_level + 1, AABB { x + subWidth, y, z + subLength, subWidth, subHeight, subLength }));
    append(&_children, oct_init(_level + 1, AABB { x, y + subHeight, z + subLength, subWidth, subHeight, subLength }));
    append(&_children, oct_init(_level + 1, AABB { x + subWidth, y + subHeight, z + subLength, subWidth, subHeight, subLength }));
}

oct_insert :: proc(using self: ^OcTree, rb: ^RigidBody) {
    if (!aabb_collision(trans_to_aabb(rb.transform), _bounds)) do return;

    if (len(_children) == 0 && _rbs.len < MAX_CAPACITY) {
        fa.append(&_rbs, rb);
        return;
    }

    if (len(_children) == 0) {
        oct_subdivide(self);
    }

    for i in 0..<len(_children) {
        oct_insert(&_children[i], rb);
    }
}

oct_retrieve :: proc(using self: ^OcTree, area: AABB) -> fa.FixedArray(^RigidBody, MAX_CAPACITY) {
    found := fa.fixed_array(^RigidBody, MAX_CAPACITY);

    if (!aabb_collision(_bounds, area)) do return found;

    for i in 0..<_rbs.len {
        rb := _rbs.data[i];
        if (aabb_collision(trans_to_aabb(rb.transform), area)) do fa.append(&found, rb);
    }

    if (len(_children) != 0) {
        for i in 0..<len(_children) {
            child_rbs := oct_retrieve(&_children[i], area);
            
            for i in 0..<child_rbs.len {
                fa.append(&found, child_rbs.data[i]);
            }
        }
    }

    return found;
}

oct_clear :: proc(using self: ^OcTree) {
    fa.clear(&_rbs);

    for i in 0..<len(_children) {
        oct_clear(&_children[i]);
    }

    clear(&_children);
}

oct_bounds :: proc(using self: ^OcTree) -> AABB {
    return _bounds;
}

oct_set_bounds :: proc(using self: ^OcTree, bounds: AABB) {
    _bounds = bounds;
}

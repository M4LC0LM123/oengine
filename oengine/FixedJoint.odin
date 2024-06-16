package oengine

import "core:fmt"
import rl "vendor:raylib"

FixedJoint :: struct {
    parent, child: ^RigidBody,
    parent_starting: Transform,
    starting_pos: Vec3,
}

fj_init :: proc(s_parent, s_child: ^RigidBody, starting_p: Vec3) -> ^Joint {
    res := new(Joint);
    res.id = u32(len(ecs_world.physics.joints));
    res.variant = new(FixedJoint);

    using fj := res.variant.(^FixedJoint);
    parent = s_parent;
    child = s_child;

    parent_starting = parent.transform;
    starting_pos = starting_p;

    res.update = fj_update;

    append(&parent.joints, res.id);
    append(&child.joints, res.id);

    append(&ecs_world.physics.joints, res);
    return res;
}

fj_update :: proc(joint: ^Joint) {
    using self := joint.variant.(^FixedJoint);

    pDeltaPos := parent.transform.position - parent_starting.position;
    child.transform.position = starting_pos + pDeltaPos;

    pDeltaRot := parent.transform.rotation - parent_starting.rotation;
    child.transform.rotation = child.starting.rotation + pDeltaRot;
}
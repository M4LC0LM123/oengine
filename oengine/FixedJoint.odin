package oengine

import "core:fmt"
import rl "vendor:raylib"
import "fa"

/* 
EXAMPLE


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

*/

FixedJoint :: struct {
    parent, child: ^RigidBody,
    parent_starting: Transform,
    starting_pos: Vec3,
}

fj_init :: proc(s_parent, s_child: ^RigidBody, starting_p: Vec3) -> ^Joint {
    res := new(Joint);
    res.id = u32(ecs_world.physics.joints.len);
    res.variant = new(FixedJoint);

    using fj := res.variant.(^FixedJoint);
    parent = s_parent;
    child = s_child;

    parent_starting = parent.transform;
    starting_pos = starting_p;

    res.update = fj_update;

    append(&parent.joints, res.id);
    append(&child.joints, res.id);

    fa.append(&ecs_world.physics.joints, res);
    return res;
}

fj_update :: proc(joint: ^Joint) {
    using self := joint.variant.(^FixedJoint);

    pDeltaPos := parent.transform.position - parent_starting.position;
    child.transform.position = starting_pos + pDeltaPos;

    pDeltaRot := parent.transform.rotation - parent_starting.rotation;
    child.transform.rotation = child.starting.rotation + pDeltaRot;
}

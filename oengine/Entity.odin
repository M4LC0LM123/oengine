package oengine

import "core:fmt"
import ecs "ecs"
import rl "vendor:raylib"

AEntity :: struct {
    data: ^ecs.Entity,
    tag: string,
}

aent_init :: proc(tag: string = "Entity") -> AEntity {
    res := AEntity {
        data = ecs.entity_init(&ecs_world.ecs_ctx),
        tag = tag,
    };

    add_component(res, transform_default());

    return res;
}

add_component :: proc(ent: AEntity, component: $T) -> ^T {
    c := ecs.add_component(ent.data, component);
  
    if (type_of(component) == RigidBody) {
        append(&ecs_world.physics.bodies, cast(^RigidBody)c);
    }

    return c;
}

has_component :: proc(ent: AEntity, $T: typeid) -> bool {
    return ecs.has_component(ent.data, T);
}

get_component :: proc(ent: AEntity, $T: typeid) -> ^T {
    c := ecs.get_component(ent.data, T);
    return c;
}

remove_component :: proc(ent: AEntity, $T: typeid) {
    ecs.remove_component(ent.data, T);
}

aent_deinit :: proc(ent: AEntity) {
    ecs.ecs_remove(&ecs_world.ecs_ctx, ent.data);
}

Entity :: struct {
    tag: string,
    id: u32,
    transform: Transform,
    starting: Transform,

    _parent_starting: Transform,

    parent: ^Entity,

    components: [dynamic]^Component,

    update: proc(self: ^Entity),
    render: proc(self: ^Entity),
    deinit: proc(self: ^Entity),
}

ent_init :: proc {
    ent_init_plain,
    ent_init_tag,
}

ent_init_plain :: proc() -> ^Entity {
    using self := new(Entity);

    id = u32(len(ecs_world.ents));
    tag = str_add_u32("Entity", id);

    transform = {
        vec3_zero(),
        vec3_zero(),
        vec3_one(),
    };

    starting = transform;

    update = ent_update;
    render = ent_render;
    deinit = ent_deinit;

    ecs_world.ents[tag] = self;

    return self;   
}

ent_init_tag :: proc(buf_tag: string) -> ^Entity {
    using self := new(Entity);

    id = u32(len(ecs_world.ents));
    tag = buf_tag;

    transform = {
        vec3_zero(),
        vec3_zero(),
        vec3_one(),
    };

    starting = transform;

    if (tag in ecs_world.ents) {
        tag = str_add(tag, id);
    }

    update = ent_update;
    render = ent_render;
    deinit = ent_deinit;

    ecs_world.ents[tag] = self;

    return self;
}

ent_add_component :: proc(using self: ^Entity, component: ^Component) {
    append(&components, component);
}

ent_get_component :: proc(using self: ^Entity, $T: typeid) -> ^Component {
    for component in components {
        if (c_variant_is(component, T)) {
            return component;
        }
    }

    return nil;
}

ent_get_component_var :: proc(using self: ^Entity, $T: typeid) -> T {
    for component in components {
        if (c_variant_is(component, T)) {
            return c_variant(component, T);
        }
    }

    return nil;
}

ent_has_component :: proc(using self: ^Entity, $T: typeid) -> bool {
    for component in components {
        if (c_variant_is(component, T)) do return true;
    }

    return false;
}

ent_starting_transform :: proc(using self: ^Entity, s_transform: Transform) {
    transform = s_transform;
    starting = transform;

    if (!ent_has_component(self, ^RigidBody)) do return;

    rb_starting_transform(ent_get_component_var(self, ^RigidBody), transform);
}

ent_set_pos :: proc(using self: ^Entity, pos: Vec3) {
    transform.position = pos;

    if (!ent_has_component(self, ^RigidBody)) do return;

    ent_get_component_var(self, ^RigidBody).transform.position = transform.position;
}

ent_set_pos_x :: proc(using self: ^Entity, x: f32) {
    ent_set_pos(self, {x, transform.position.y, transform.position.z});
}

ent_set_pos_y :: proc(using self: ^Entity, y: f32) {
    ent_set_pos(self, {transform.position.x, y, transform.position.z});
}

ent_set_pos_z :: proc(using self: ^Entity, z: f32) {
    ent_set_pos(self, {transform.position.x, transform.position.y, z});
}

ent_set_rot :: proc(using self: ^Entity, rot: Vec3) {
    transform.rotation = rot;

    if (!ent_has_component(self, ^RigidBody)) do return;

    ent_get_component_var(self, ^RigidBody).transform.rotation = transform.rotation;
}

ent_set_rot_x :: proc(using self: ^Entity, x: f32) {
    ent_set_rot(self, {x, transform.rotation.y, transform.rotation.z});
}

ent_set_rot_y :: proc(using self: ^Entity, y: f32) {
    ent_set_rot(self, {transform.rotation.x, y, transform.rotation.z});
}

ent_set_rot_z :: proc(using self: ^Entity, z: f32) {
    ent_set_rot(self, {transform.rotation.x, transform.rotation.y, z});
}

ent_set_scale :: proc(using self: ^Entity, scale: Vec3) {
    transform.scale = scale;

    if (!ent_has_component(self, ^RigidBody)) do return;

    ent_get_component_var(self, ^RigidBody).transform.scale = transform.scale;
}

ent_set_scale_x :: proc(using self: ^Entity, x: f32) {
    ent_set_scale(self, {x, transform.scale.y, transform.scale.z});
}

ent_set_scale_y :: proc(using self: ^Entity, y: f32) {
    ent_set_scale(self, {transform.scale.x, y, transform.scale.z});
}

ent_set_scale_z :: proc(using self: ^Entity, z: f32) {
    ent_set_scale(self, {transform.scale.x, transform.scale.y, z});
}

ent_get_parent :: proc(using self: ^Entity) -> ^Entity {
    return parent;
}

ent_set_parent :: proc(using self: ^Entity, s_parent: ^Entity) {
    parent = s_parent;
    _parent_starting = parent.transform;
}

ent_add_child :: proc(using self: ^Entity, child: ^Entity) {
    ent_set_parent(child, self);
}

ent_get_child :: proc(using self: ^Entity, s_tag: string) -> ^Entity {
    child := ew_get_entity(s_tag);
    
    if (ent_get_parent(child).tag == tag) {
        return child;
    }

    dbg_log(str_add({"ent", tag, " doesn't contain a child ", s_tag}), .WARNING);
    return nil;
}

ent_update :: proc(using self: ^Entity) {
    for component in components {
        if (component.update == nil) do continue;

        component->update(self);
    }

    if (parent != nil) {
        pDeltaPos := parent.transform.position - _parent_starting.position;
        transform.position = starting.position + pDeltaPos;

        pDeltaRot := parent.transform.rotation - _parent_starting.rotation;
        transform.rotation = starting.rotation + pDeltaRot;

        pDeltaSc := parent.transform.scale - _parent_starting.scale;
        transform.scale = starting.scale + pDeltaSc;
    }
}

ent_render :: proc(using self: ^Entity) { 
    if (OE_DEBUG) {
        rl.rlPushMatrix();
        rl.rlRotatef(transform.rotation.x, 1, 0, 0);
        rl.rlRotatef(transform.rotation.y, 0, 1, 0);
        rl.rlRotatef(transform.rotation.z, 0, 0, 1);
        
        rl.DrawCubeWiresV(transform.position, transform.scale, OE_DEBUG_COLOR);

        rl.rlPopMatrix();
    }

    for component in components {
        if (component.render == nil) do continue;

        component->render();
    }
}

ent_deinit :: proc(using self: ^Entity) {
    for component in components {
        if (component.deinit == nil) do continue;
        
        component->deinit();
    }

    delete(components);
}

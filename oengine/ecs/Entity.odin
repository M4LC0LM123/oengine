package ecs

SystemFunc :: #type proc(ctx: ^Context, entity: ^Entity)

ECS_UPDATE :: 0
ECS_RENDER :: 1

Entity :: struct {
    id: u32,
    components: map[typeid]rawptr,
}

entity_init :: proc(ctx: ^Context) -> ^Entity {
    res := new(Entity);
    res.id = u32(len(ctx.entities));
    res.components = make(map[typeid]rawptr);
    append(&ctx.entities, res);
    return res;
}

// creates a pointer copy of the passed component
add_component :: proc(ent: ^Entity, component: $T) -> ^T {
    type := typeid_of(type_of(component));
    ent.components[type] = new_clone(component);
    return cast(^T)ent.components[type];
}

get_component :: proc(ent: ^Entity, $T: typeid) -> ^T {
    return cast(^T)ent.components[T];
}

has_component :: proc(ent: ^Entity, $T: typeid) -> bool {
    return ent.components[T] != nil;
}

remove_component :: proc(ent: ^Entity, $T: typeid) {
    ent.components[T] = nil;
}

add_components_2 :: proc(entity: ^Entity, a:$A, b:$B) -> (^A, ^B) {
    _a := add_component(entity, a);
    _b := add_component(entity, b);
    return _a, _b;
}

add_components_3 :: proc(entity: ^Entity, a:$A, b:$B, c:$C) -> (^A, ^B, ^C) {
    _a := add_component(entity, a);
    _b := add_component(entity, b);
    _c := add_component(entity, c);
    return _a, _b, _c;
}

add_components_4 :: proc(entity: ^Entity, a:$A, b:$B, c:$C, d:$D) -> (^A, ^B, ^C, ^D) {
    _a := add_component(entity, a);
    _b := add_component(entity, b);
    _c := add_component(entity, c);
    _d := add_component(entity, d);
    return _a, _b, _c, _d;
}

add_components_5 :: proc(entity: ^Entity, a:$A, b:$B, c:$C, d:$D, e:$E) -> (^A, ^B, ^C, ^D, ^E) {
    _a := add_component(entity, a);
    _b := add_component(entity, b);
    _c := add_component(entity, c);
    _d := add_component(entity, d);
    _e := add_component(entity, e);
    return _a, _b, _c, _d, _e;
}

add_components_6 :: proc(entity: ^Entity, a:$A, b:$B, c:$C, d:$D, e:$E, f:$F) -> (^A, ^B, ^C, ^D, ^E, ^F) {
    _a := add_component(entity, a);
    _b := add_component(entity, b);
    _c := add_component(entity, c);
    _d := add_component(entity, d);
    _e := add_component(entity, e);
    _f := add_component(entity, f);
    return _a, _b, _c, _d, _e, _f;
}

add_components_7 :: proc(entity: ^Entity, a:$A, b:$B, c:$C, d:$D, e:$E, f:$F, g:$G) -> (^A, ^B, ^C, ^D, ^E, ^F, ^G) {
    _a := add_component(entity, a);
    _b := add_component(entity, b);
    _c := add_component(entity, c);
    _d := add_component(entity, d);
    _e := add_component(entity, e);
    _f := add_component(entity, f);
    _g := add_component(entity, g);
    return _a, _b, _c, _d, _e, _f, _g;
}

add_components_8 :: proc(entity: ^Entity, a:$A, b:$B, c:$C, d:$D, e:$E, f:$F, g:$G, h:$H) -> (^A, ^B, ^C, ^D, ^E, ^F, ^G, ^H) {
    _a := add_component(entity, a);
    _b := add_component(entity, b);
    _c := add_component(entity, c);
    _d := add_component(entity, d);
    _e := add_component(entity, e);
    _f := add_component(entity, f);
    _g := add_component(entity, g);
    _h := add_component(entity, h);
    return _a, _b, _c, _d, _e, _f, _g, _h;
}

add_components :: proc {
    add_components_2, 
    add_components_3,
    add_components_4,
    add_components_5,
    add_components_6,
    add_components_7,
    add_components_8,
}

get_components_2 :: proc(entity: ^Entity, $A, $B: typeid) -> (^A, ^B) {
    a := get_component(entity, A);
    b := get_component(entity, B);
    return a, b;
}

get_components_3 :: proc(entity: ^Entity, $A, $B, $C: typeid) -> (^A, ^B, ^C) {
    a  := get_component(entity, A);
    b  := get_component(entity, B);
    c  := get_component(entity, C);
    return a, b, c;
}

get_components_4 :: proc(entity: ^Entity, $A, $B, $C, $D: typeid) -> (^A, ^B, ^C, ^D) {
    a := get_component(entity, A);
    b := get_component(entity, B);
    c := get_component(entity, C);
    d := get_component(entity, D);
    return a, b, c, d;
}

get_components_5 :: proc(entity: ^Entity, $A, $B, $C, $D, $E: typeid) -> (^A, ^B, ^C, ^D, ^E) {
    a := get_component(entity, A);
    b := get_component(entity, B);
    c := get_component(entity, C);
    d := get_component(entity, D);
    e := get_component(entity, E);
    return a, b, c, d, e;
}

get_components :: proc {
    get_components_2, 
    get_components_3,
    get_components_4,
    get_components_5,
}
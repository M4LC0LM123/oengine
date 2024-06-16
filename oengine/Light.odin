package oengine

import "core:fmt"

Light :: struct {
    transform: Transform,
    _handle: rlLight,
    type: LightType,
    color: Color,
    enabled: bool,
}

@(private = "file")
lc_init_all :: proc(using lc: ^Light, s_type: LightType = .POINT, s_color: Color = WHITE) {
    transform = transform_default();
    type = s_type;
    color = s_color;
    enabled = true;

    _handle = create_light(type, transform.position, vec3_zero(), color);
}

lc_init :: proc(s_type: LightType = .POINT, s_color: Color = WHITE) -> ^Component {
    using component := new(Component);

    component.variant = new(Light);
    lc_init_all(component.variant.(^Light), s_type, s_color);

    update = lc_update;
    
    return component;
}

lc_update :: proc(component: ^Component, ent: ^Entity) {
    using self := component.variant.(^Light);
    transform = ent.transform;

    _handle.enabled = enabled;
    _handle.position = transform.position;
    _handle.type = type;
    _handle.color = color;

    update_light(_handle);
}


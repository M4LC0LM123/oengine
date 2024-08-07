package oengine

import "core:fmt"
import rl "vendor:raylib"
import rlg "rllights"

Light :: struct {
    id: u32,
    transform: Transform,
    type: rlg.LightType,
    color: Color,
    enabled: bool,
}

@(private = "file")
lc_init_all :: proc(using lc: ^Light, s_type: rlg.LightType = .OMNI, s_color: Color = WHITE) {
    id = ecs_world.light_count;
    ecs_world.light_count += 1;
    transform = transform_default();
    type = s_type;
    color = s_color;
    enabled = true;

    rlg.UseLight(id, enabled);
    rlg.SetLightType(id, type);
    rlg.SetLightVec3(id, .POSITION, transform.position);
    rlg.SetLightColor(id, color);
}

lc_init :: proc(s_type: rlg.LightType = .OMNI, s_color: Color = WHITE) -> ^Component {
    using component := new(Component);

    component.variant = new(Light);
    lc_init_all(component.variant.(^Light), s_type, s_color);

    update = lc_update;
    
    return component;
}

lc_update :: proc(component: ^Component, ent: ^Entity) {
    using self := component.variant.(^Light);
    transform = ent.transform;

    rlg.SetLightVec3(id, .POSITION, transform.position);
    rlg.SetLightColor(id, color);
}


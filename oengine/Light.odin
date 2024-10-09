package oengine

import "core:fmt"
import rl "vendor:raylib"
import rlg "rllights"
import ecs "ecs"

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

lc_init :: proc(s_type: rlg.LightType = .OMNI, s_color: Color = WHITE) -> Light {
    lc: Light;

    lc_init_all(&lc, s_type, s_color);
    
    return lc;
}

lc_update :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    t, lc := ecs.get_components(ent, Transform, Light);
    if (is_nil(t, lc)) do return;
    using lc;

    transform = t^;

    rlg.SetLightVec3(id, .POSITION, transform.position);
    rlg.SetLightColor(id, color);
}


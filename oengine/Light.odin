package oengine

import "core:fmt"
import rl "vendor:raylib"
import rlg "rllights"
import ecs "ecs"
import "core:encoding/json"

Light :: struct {
    id: u32,
    transform: Transform,
    type: rlg.LightType,
    color: Color,
    enabled: bool,
}

@(private = "file")
lc_init_all :: proc(using lc: ^Light, s_type: rlg.LightType = .OMNI, s_color: Color = WHITE) {
    transform = transform_default();
    type = s_type;
    color = s_color;
    enabled = true;

    rlg.UseLight(id, enabled);
    rlg.SetLightType(id, type);
    rlg.SetLightVec3(id, .POSITION, transform.position);
    rlg.SetLightColor(id, color);
}

lc_toggle :: proc(using lc: ^Light) {
    rlg.ToggleLight(id);
}

lc_init :: proc(s_type: rlg.LightType = .OMNI, s_color: Color = WHITE) -> Light {
    lc: Light;
    lc.id = ecs_world.light_count;
    ecs_world.light_count += 1;

    lc_init_all(&lc, s_type, s_color);
    
    return lc;
}

lc_init_id :: proc(id: u32, s_type: rlg.LightType = .OMNI, s_color: Color = WHITE) -> Light {
    lc: Light;
    lc.id = id;
    ecs_world.light_count += 1;

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

lc_clone :: proc(l: Light) -> Light {
    res := lc_init(l.type, l.color);

    rlg.SetLightVec3(res.id, .DIRECTION, rlg.GetLightVec3(l.id, .DIRECTION));
    rlg.SetLightVec3(res.id, .SPECULAR, rlg.GetLightVec3(l.id, .SPECULAR));
    rlg.SetLightValue(res.id, .ENERGY, rlg.GetLightValue(l.id, .ENERGY));
    rlg.SetLightValue(res.id, .SIZE, rlg.GetLightValue(l.id, .SIZE));
    rlg.SetLightValue(res.id, .INNER_CUTOFF, rlg.GetLightValue(l.id, .INNER_CUTOFF));
    rlg.SetLightValue(res.id, .OUTER_CUTOFF, rlg.GetLightValue(l.id, .OUTER_CUTOFF));
    rlg.SetLightValue(
        res.id, 
        .ATTENUATION_CLQ, 
        rlg.GetLightValue(l.id, .ATTENUATION_CLQ)
    );
    rlg.SetLightValue(
        res.id, 
        .ATTENUATION_LINEAR, 
        rlg.GetLightValue(l.id, .ATTENUATION_LINEAR)
    );
    rlg.SetLightValue(
        res.id, 
        .ATTENUATION_CONSTANT, 
        rlg.GetLightValue(l.id, .ATTENUATION_CONSTANT)
    );
    rlg.SetLightValue(
        res.id, 
        .ATTENUATION_QUADRATIC, 
        rlg.GetLightValue(l.id, .ATTENUATION_QUADRATIC)
    );

    return res;
}

lc_parse :: proc(asset_json: json.Object) -> rawptr {

    id := ecs_world.light_count; 
    if (asset_json["id"] != nil) {
        id = u32(asset_json["id"].(json.Float));
    }

    type := rlg.LightType(asset_json["light_type"].(json.Float));

    color_arr := asset_json["color"].(json.Array);
    color := Color {
        u8(color_arr[0].(json.Float)), 
        u8(color_arr[1].(json.Float)), 
        u8(color_arr[2].(json.Float)), 
        u8(color_arr[3].(json.Float))
    };

    enabled := true;
    if (json_contains(asset_json, "enabled")) {
        enabled = asset_json["enabled"].(json.Boolean);
    }

    lc := lc_init_id(id, type, color);
    lc.enabled = enabled;
    return new_clone(lc);
}

lc_loader :: proc(ent: AEntity, tag: string) {
    using comp := get_component_data(tag, Light);
    add_component(ent, lc_clone(comp^));
}

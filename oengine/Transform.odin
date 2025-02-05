package oengine

import rl "vendor:raylib"
import ecs "ecs"
import "core:fmt"
import "core:encoding/json"

Transform :: struct {
    position: Vec3,
    rotation: Vec3,
    scale: Vec3
}

transform_default :: proc() -> Transform {
    return Transform {
        position = vec3_zero(),
        rotation = vec3_zero(),
        scale = vec3_one(),
    };
}

transform_render :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    t := ecs.get_component(ent, Transform);
    if (is_nil(t)) do return;

    if (OE_DEBUG) do draw_cube_wireframe(t.position, t.rotation, t.scale, GREEN);
}

transform_add :: proc(t1, t2: Transform) -> Transform {
    return {
        position = t1.position + t2.position,
        rotation = t1.rotation + t2.rotation,
        scale = t1.scale + t2.scale,
    };
}

transform_subtract :: proc(t1, t2: Transform) -> Transform {
    return {
        position = t1.position - t2.position,
        rotation = t1.rotation - t2.rotation,
        scale = t1.scale - t2.scale,
    };
}

transform_parse :: proc(asset_json: json.Object) -> rawptr {
    // _h handle
    pos_h := asset_json["position"].(json.Array);
    rot_h := asset_json["rotation"].(json.Array);
    sc_h := asset_json["scale"].(json.Array);

    t := Transform {
        position = json_vec3_to_vec3(pos_h),
        rotation = json_vec3_to_vec3(rot_h),
        scale = json_vec3_to_vec3(sc_h),
    };

    return new_clone(t);
}

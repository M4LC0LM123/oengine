package oengine

import "core:fmt"
import "core:math"
import rl "vendor:raylib"
import rlg "rllights"
import "core:encoding/json"
import "core:io"
import "core:os"
import strs "core:strings"
import "core:unicode/utf8"

ent_to_json :: proc(ent: ^Entity, path: string, mode: FileMode = FileMode.WRITE_RONLY | FileMode.CREATE) {
    file := file_handle(path, mode);

    res: string;
    if (mode == .WRITE_RONLY | .CREATE) do res = "{\n";

    EntityMarshal :: struct {
        tag, parent_tag: string,
        id: u32,
        transform, parent_transform: Transform,
    }

    parent_tag: string;
    parent_transform: Transform;
    if (ent.parent != nil) { 
        parent_tag = ent.parent.tag; 
        parent_transform = ent.parent.transform;
    }
    em := EntityMarshal {
        tag = ent.tag, parent_tag = parent_tag, id = ent.id,
        transform = ent.transform, parent_transform = parent_transform,
    };

    data, ok := json.marshal(em, {pretty = true});

    if (ok != nil) {
        fmt.printfln("An error occured marshalling data: %v", ok);
        return;
    }

    components: string;
    if (len(ent.components) > 0) {
        for c in ent.components {
            if (c_variant_is(c, ^RigidBody)) {
                res := rb_to_json_marshal(c_variant(c, ^RigidBody));
                components = str_add(components, res);
            }
        } 
    }

    name := str_add({"\"", em.tag, "\": {\n"});
    res = str_add({
        res, name, 
        string(data[1:len(data) - 2]), ",\n", 
        components, 
        "},\n"
    });

    if (mode == .WRITE_RONLY | .CREATE) do res = str_add(res, "\n}");

    file_write(file, res);
    file_close(file);
}

rb_to_json_marshal :: proc(rb: ^RigidBody, tabbed: bool = true) -> string {
    if (rb.shape == .HEIGHTMAP || rb.shape == .SLOPE) {
        dbg_log("Rigidbody marshalling isn't supported for heightmaps or slopes currently", .WARNING);
        return "";
    }

    RigidBodyMarshal :: struct {
        id: u32,
        transform: Transform,
        mass, restitution, friction: f32,
        shape: i32,
        is_static: bool,
        joints: [dynamic]u32,
    }

    rm := RigidBodyMarshal {
        id = rb.id, transform = rb.starting,
        mass = rb.mass, restitution = rb.restitution, friction = rb.friction,
        shape = i32(rb.shape), is_static = rb.is_static, joints = rb.joints,
    };

    data, ok := json.marshal(rm, {pretty = true});

    if (ok != nil) {
        fmt.printfln("An error occured marshalling data: %v", ok);
        return "";
    }

    s := "\"RigidBody\": {\n";
    ss := str_add({s, string(data[1:len(data) - 1]), "},\n"});
    if (!tabbed) do return ss;

    lines: [100]string;
    i: int;
    for c in ss {
        lines[i] = str_add(lines[i], utf8.runes_to_string({c}));
        if (c == '\n') do i += 1;
    }

    res: string;
    for line in lines {
        res = str_add({res, "\t", line});
    }

    return res;
}

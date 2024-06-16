package oengine

import "core:fmt"
import "core:math"
import rl "vendor:raylib"
import "core:encoding/json"
import "core:io"
import "core:os"

/*
EXAMPLE

msc := oe.msc_init();
oe.msc_append_tri(msc, {0, 0, 0}, {10, 0, 0}, {5, 10, 0}, {0, 0.5, 0});
oe.msc_append_quad(msc, {0, 0, 0}, {10, 0, 0}, {0, 10, 10}, {10, 10, 10}, {10, 0, 20});
oe.msc_append_quad(msc, {0, 0, 0}, {10, 0, 0}, {0, 0, 10}, {10, 0, 10}, {10, 10, 30});
oe.msc_append_quad(msc, {0, 0, 0}, {0, 10, 5}, {10, 0, 0}, {10, 10, 0}, {10, 10, 40});
oe.msc_append_quad(msc, {0, 0, 0}, {10, 0, 0}, {0, 0, 10}, {10, 0, 10}, {10, 10, 40});

oe.msc_to_json(msc, "../assets/maps/test.json");
oe.msc_from_json(msc, "../assets/maps/test.json");

*/

MSCObject :: struct {
    tris: [dynamic]TriangleCollider,
    _aabb: AABB
}

msc_init :: proc() -> ^MSCObject {
    using self := new(MSCObject);

    tris = make([dynamic]TriangleCollider);

    append(&ecs_world.physics.mscs, self);

    return self;
}

msc_append_tri :: proc(using self: ^MSCObject, a, b, c: Vec3, offs: Vec3 = {}, color: Color = BLACK) {
    t: TriangleCollider;
    t.pts = {a + offs, b + offs, c + offs};
    t.color = color;
    append(&tris, t);

    _aabb = tris_to_aabb(tris);
}

msc_append_quad :: proc(using self: ^MSCObject, a, b, c, d: rl.Vector3, offs: rl.Vector3 = {}, color : Color = BLACK) {
    t: TriangleCollider;
    t.pts = {b + offs, a + offs, c + offs};
    t.color = color;
    append(&tris, t);

    t2: TriangleCollider;
    t2.pts = {b + offs, c + offs, d + offs};
    t2.color = color;
    append(&tris, t2);

    _aabb = tris_to_aabb(tris);
}


// supports only .obj wavefront
// work in progress
msc_from_model :: proc(using self: ^MSCObject, model: Model, offs: Vec3 = {}) {
    for i in 0..<model.meshCount {
        mesh := model.meshes[i];

        vertices := mesh.vertices[:mesh.vertexCount]; 
        for j := 0; j < len(vertices); j += 9 {
            v1 := Vec3 { vertices[j], vertices[j + 1], vertices[j + 2]};
            v2 := Vec3 { vertices[j + 3], vertices[j + 4], vertices[j + 5]};
            v3 := Vec3 { vertices[j + 6], vertices[j + 7], vertices[j + 8]};

            // fmt.printf("%v, %v, %v\n", v1, v2, v3);

            msc_append_tri(self, v1, v2, v3, offs);
        } 
    }
}

msc_to_json :: proc(using self: ^MSCObject, path: string) {
    mode := FileMode.WRITE_RONLY | FileMode.CREATE;
    file := file_handle(path, mode);
    
    res: string = "{";

    i := 0;
    for t in tris {
        data, ok := json.marshal(t, {pretty = true});

        if (ok != nil) {
            fmt.printfln("An error occured marshalling data: %v", ok);
            return;
        }

        name := str_add({str_add("\"triangle", i), "\": {\n"});
        res = str_add({res, "\n", name, string(data[1:len(data) - 1]), "},\n"});
        i += 1;
    }

    res = str_add(res, "\n}");
    file_write(file, res);
    file_close(file);
}

msc_from_json :: proc(using self: ^MSCObject, path: string) {
    data, ok := os.read_entire_file_from_filename(path);
    if (!ok) {
        dbg_log("Failed to open file ", DebugType.WARNING);
        return;
    }
    defer delete(data);

    json_data, err := json.parse(data);
    if (err != json.Error.None) {
		dbg_log("Failed to parse the json file", DebugType.WARNING);
		dbg_log(str_add("Error: ", err), DebugType.WARNING);
		return;
	}
	defer json.destroy_value(json_data);

    msc := json_data.(json.Object);

    for tag, obj in msc {
        pts := obj.(json.Object)["pts"].(json.Array);
        tri: [3]Vec3;

        i := 0;
        for pt in pts {
            val := pt.(json.Array);
            tri[i] = Vec3 {
                f32(val[0].(json.Float)), 
                f32(val[1].(json.Float)),
                f32(val[2].(json.Float))
            };
            i += 1;
        }

        colors := obj.(json.Object)["color"].(json.Array);
        color := Color {
            u8(colors[0].(json.Float)),
            u8(colors[1].(json.Float)),
            u8(colors[2].(json.Float)),
            u8(colors[3].(json.Float)),
        };

        msc_append_tri(self, tri[0], tri[1], tri[2], color = color);
    }
}

msc_render :: proc(using self: ^MSCObject) {
    for tri in tris {
        t := tri.pts;
        rl.DrawTriangle3D(t[0], t[1], t[2], tri.color)
        rl.DrawLine3D(t[0], t[1], rl.RED)
        rl.DrawLine3D(t[0], t[2], rl.GREEN)
        rl.DrawLine3D(t[1], t[2], rl.BLUE)
    }

    if (PHYS_DEBUG) {
        draw_cube_wireframe(
            {_aabb.x, _aabb.y, _aabb.z}, {}, 
            {_aabb.width, _aabb.height, _aabb.depth},
            PHYS_DEBUG_COLOR
        ); 
    }
}

msc_deinit :: proc(using self: ^MSCObject) {
    for t in tris {
        deinit_texture(t.texture);
    }

    delete(tris);
}

package oengine

import "core:fmt"
import "core:math"
import rl "vendor:raylib"
import "core:encoding/json"
import "core:io"
import "core:os"
import strs "core:strings"

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

tri_count: i32;

MSCObject :: struct {
    tris: [dynamic]^TriangleCollider,
    _aabb: AABB
}

msc_init :: proc() -> ^MSCObject {
    using self := new(MSCObject);

    tris = make([dynamic]^TriangleCollider);

    append(&ecs_world.physics.mscs, self);

    return self;
}

msc_append_tri :: proc(using self: ^MSCObject, a, b, c: Vec3, offs: Vec3 = {}, color: Color = WHITE, texture_tag: string = "") {
    t := new(TriangleCollider);
    t.pts = {a + offs, b + offs, c + offs};
    t.color = color;
    t.texture_tag = texture_tag;
    t.mesh = gen_mesh_triangle(t.pts);
    append(&tris, t);
    tri_count += 1;

    _aabb = tris_to_aabb(tris);
}

msc_append_quad :: proc(using self: ^MSCObject, a, b, c, d: Vec3, offs: Vec3 = {}, color : Color = WHITE, texture_tag: string = "") {
    t := new(TriangleCollider);
    t.pts = {b + offs, a + offs, c + offs};
    t.color = color;
    t.texture_tag = texture_tag;
    t.mesh = gen_mesh_triangle(t.pts);
    append(&tris, t);

    t2 := new(TriangleCollider);
    t2.pts = {b + offs, c + offs, d + offs};
    t2.color = color;
    t2.texture_tag = texture_tag;
    t2.mesh = gen_mesh_triangle(t2.pts);
    append(&tris, t2);

    tri_count += 2;

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

msc_to_json :: proc(using self: ^MSCObject, path: string, mode: FileMode = FileMode.WRITE_RONLY) {
    file := file_handle(path, mode);
    
    res: string = "{";

    TriangleColliderMarshal :: struct {
        using pts: [3]Vec3,
        color: Color,
        texture_tag: string,
    }

    i := 0;
    for t in tris {
        tm := TriangleColliderMarshal {
            pts = t.pts,
            color = t.color,
            texture_tag = t.texture_tag
        };
        data, ok := json.marshal(tm, {pretty = true});

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

        tex_tag := obj.(json.Object)["texture_tag"].(json.String);

        if (!asset_exists(tex_tag)) {
            dbg_log(
                str_add({"Texture ", tex_tag, " doesn't exist in the asset manager"}), 
                DebugType.WARNING
            );
        }

        msc_append_tri(self, tri[0], tri[1], tri[2], color = color, texture_tag = strs.clone(tex_tag));
    }
}

msc_render :: proc(using self: ^MSCObject) {
    for tri in tris {
        t := tri.pts;

        v1 := t[0];
        v2 := t[1];
        v3 := t[2];
        color := tri.color;

        if (window.instance_name == EDITOR_INSTANCE) {
            uv1, uv2, uv3 := triangle_uvs(v1, v2, v3);

            if (ecs_world.LAE) do rl.BeginShaderMode(DEFAULT_LIGHT);

            rl.rlColor4ub(color.r, color.g, color.b, color.a);
            rl.rlBegin(rl.RL_TRIANGLES);

            if (asset_exists(tri.texture_tag)) {
                tex := get_asset_var(tri.texture_tag, Texture);
                rl.rlSetTexture(tex.id);
            }

            rl.rlTexCoord2f(uv1.x, uv1.y); rl.rlVertex3f(v1.x, v1.y, v1.z);
            rl.rlTexCoord2f(uv2.x, uv2.y); rl.rlVertex3f(v2.x, v2.y, v2.z);
            rl.rlTexCoord2f(uv3.x, uv3.y); rl.rlVertex3f(v3.x, v3.y, v3.z);

            rl.rlEnd();

            rl.rlSetTexture(0);

            if (ecs_world.LAE) do rl.EndShaderMode();
        } else {
            material := rl.LoadMaterialDefault();
            material.maps[rl.MaterialMapIndex.ALBEDO].color = color;
            if (asset_exists(tri.texture_tag)) {
                tex := get_asset_var(tri.texture_tag, Texture);
                material.maps[rl.MaterialMapIndex.ALBEDO].texture = tex;
            }
            rl.DrawMesh(tri.mesh, material, rl.Matrix(1));
        }

        if (!PHYS_DEBUG) do continue;

        rl.DrawLine3D(t[0], t[1], rl.YELLOW);
        rl.DrawLine3D(t[0], t[2], rl.YELLOW);
        rl.DrawLine3D(t[1], t[2], rl.YELLOW);
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
    delete(tris);
}

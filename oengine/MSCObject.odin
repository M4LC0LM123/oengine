package oengine

import "core:fmt"
import "core:math"
import rl "vendor:raylib"
import rlg "rllights"
import "core:encoding/json"
import "core:io"
import "core:os"
import strs "core:strings"
import "fa"

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

    fa.append(&ecs_world.physics.mscs, self);

    return self;
}

msc_append_tri :: proc(using self: ^MSCObject, a, b, c: Vec3, offs: Vec3 = {}, color: Color = WHITE, texture_tag: string = "", is_lit: bool = true, use_fog: bool = OE_FAE, rot: i32 = 0) {
    t := new(TriangleCollider);
    t.pts = {a + offs, b + offs, c + offs};
    t.color = color;
    t.texture_tag = texture_tag;
    t.rot = rot;
    t.mesh = gen_mesh_triangle(t.pts, t.rot);
    t.is_lit = is_lit;
    t.use_fog = use_fog;
    append(&tris, t);
    tri_count += 1;

    _aabb = tris_to_aabb(tris);
}

msc_append_quad :: proc(using self: ^MSCObject, a, b, c, d: Vec3, offs: Vec3 = {}, color : Color = WHITE, texture_tag: string = "", is_lit: bool = true, use_fog: bool = OE_FAE, rot: i32 = 0) {
    t := new(TriangleCollider);
    t.pts = {b + offs, a + offs, c + offs};
    t.color = color;
    t.texture_tag = texture_tag;
    t.rot = rot;
    t.mesh = gen_mesh_triangle(t.pts, t.rot);
    t.is_lit = is_lit;
    t.use_fog = use_fog;
    append(&tris, t);

    t2 := new(TriangleCollider);
    t2.pts = {b + offs, c + offs, d + offs};
    t2.color = color;
    t2.texture_tag = texture_tag;
    t2.rot = rot;
    t2.mesh = gen_mesh_triangle(t2.pts, t2.rot);
    t2.is_lit = is_lit;
    t2.use_fog = use_fog;
    append(&tris, t2);

    tri_count += 2;

    _aabb = tris_to_aabb(tris);
}

tri_recalc_uvs :: proc(t: ^TriangleCollider, #any_int uv_rot: i32 = 0) {
    t.rot = uv_rot;
    t.mesh = gen_mesh_triangle(t.pts, t.rot);
}

// supports only .obj wavefront and tested with trenchbroom models
// work in progress
msc_from_model :: proc(using self: ^MSCObject, model: Model, offs: Vec3 = {}) {
    for i in 0..<model.meshCount {
        mesh := model.meshes[i];

        materialIndex := model.meshMaterial[i];
        material := model.materials[materialIndex];
        tag := str_add("mtl", materialIndex);
        texture := material.maps[rl.MaterialMapIndex.ALBEDO].texture;
        reg_asset(tag, load_texture(texture));

        vertices := mesh.vertices;
        for j := 0; j < int(mesh.vertexCount); j += 3 {
            v0 := Vec3 { vertices[j * 3], vertices[j * 3 + 1], vertices[j * 3 + 2] };
            v1 := Vec3 { vertices[(j + 1) * 3], vertices[(j + 1) * 3 + 1], vertices[(j + 1) * 3 + 2] };
            v2 := Vec3 { vertices[(j + 2) * 3], vertices[(j + 2) * 3 + 1], vertices[(j + 2) * 3 + 2] };

            msc_append_tri(self, v0, v1, v2, offs, texture_tag = tag);
        } 
    }
}

msc_to_json :: proc(using self: ^MSCObject, path: string, mode: FileMode = FileMode.WRITE_RONLY | FileMode.CREATE) {
    file := file_handle(path, mode);
    
    res: string = "{";

    TriangleColliderMarshal :: struct {
        using pts: [3]Vec3,
        color: Color,
        texture_tag: string,
        is_lit: bool,
        use_fog: bool,
        rot: i32,
    }

    i := 0;
    for t in tris {
        tm := TriangleColliderMarshal {
            pts = t.pts,
            color = t.color,
            texture_tag = t.texture_tag,
            is_lit = t.is_lit,
            use_fog = t.use_fog,
            rot = t.rot,
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

    DataIDMarshall :: struct {
        tag: string,
        id: u32,
        transform: Transform,
    };

    j := 0;
    dids := get_reg_data_ids();
    for i in 0..<len(dids) {
        data_id := dids[i];
        mrshl := DataIDMarshall {data_id.tag, data_id.id, data_id.transform};
        data, ok := json.marshal(mrshl, {pretty = true});

        if (ok != nil) {
            fmt.printfln("An error occured marshalling data: %v", ok);
            return;
        }
        
        name := str_add({"\"", str_add("data_id", j), "\": {\n"});
        res = str_add({res, "\n", name, string(data[1:len(data) - 1]), "},\n"});
        j += 1;
    }
    delete(dids);

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
        if (strs.contains(tag, "triangle")) { msc_load_tri(self, obj); }
        else { msc_load_data_id(strs.clone(obj.(json.Object)["tag"].(json.String)), obj); }
    }
}

json_vec3_to_vec3 :: proc(v: json.Array) -> Vec3 {
    return Vec3 {
        f32(v[0].(json.Float)),
        f32(v[1].(json.Float)),
        f32(v[2].(json.Float))
    };
}

msc_load_data_id :: proc(tag: string, obj: json.Value) {
    id := obj.(json.Object)["id"].(json.Float);

    if (obj.(json.Object)["transform"] == nil) do return;

    transfrom_obj := obj.(json.Object)["transform"].(json.Object);
    transform := Transform {
        position = json_vec3_to_vec3(transfrom_obj["position"].(json.Array)),
        rotation = json_vec3_to_vec3(transfrom_obj["rotation"].(json.Array)),
        scale = json_vec3_to_vec3(transfrom_obj["scale"].(json.Array)),
    };

    reg_tag := str_add("data_id_", tag);
    if (asset_manager.registry[reg_tag] != nil) do reg_tag = str_add(reg_tag, rl.GetRandomValue(1000, 9999));

    reg_asset(reg_tag, DataID {reg_tag, tag, u32(id), transform});

    ent := aent_init(tag);
    ent_tr := get_component(ent, Transform);
    ent_tr^ = transform;

    if (obj.(json.Object)["components"] != nil) {
        comps_handle := obj.(json.Object)["components"].(json.Array);
        for i in comps_handle {
            tag := i.(json.Object)["tag"].(json.String);
            type := i.(json.Object)["type"].(json.String);
      
            loader := asset_manager.component_loaders[type];
            if (loader != nil) { loader(ent, tag); }
        }
    }

}

msc_load_tri :: proc(using self: ^MSCObject, obj: json.Value) {
    tri: [3]Vec3;
    if (obj.(json.Object)["pts"] != nil) {
        pts := obj.(json.Object)["pts"].(json.Array);

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
    }

    color: Color;
    if (obj.(json.Object)["color"] != nil) {
        colors := obj.(json.Object)["color"].(json.Array);
        color = {
            u8(colors[0].(json.Float)),
            u8(colors[1].(json.Float)),
            u8(colors[2].(json.Float)),
            u8(colors[3].(json.Float)),
        };
    }

    tex_tag := obj.(json.Object)["texture_tag"].(json.String);

    if (!asset_exists(tex_tag)) {
        dbg_log(
            str_add({"Texture ", tex_tag, " doesn't exist in the asset manager"}), 
            DebugType.WARNING
        );
    }

    is_lit := true;
    if (obj.(json.Object)["is_lit"] != nil) {
        is_lit = obj.(json.Object)["is_lit"].(json.Boolean);
    }

    use_fog := OE_FAE;
    if (obj.(json.Object)["use_fog"] != nil) {
        use_fog = obj.(json.Object)["use_fog"].(json.Boolean);
    }

    rot: i32;
    if (obj.(json.Object)["rot"] != nil) {
        rot = i32(obj.(json.Object)["rot"].(json.Float));
    }

    msc_append_tri(self, tri[0], tri[1], tri[2], color = color, texture_tag = strs.clone(tex_tag), is_lit = is_lit, use_fog = use_fog, rot = rot);
}

msc_render :: proc(using self: ^MSCObject) {
    for tri in tris {
        t := tri.pts;

        v1 := t[0];
        v2 := t[1];
        v3 := t[2];
        color := tri.color;

        if (window.instance_name == EDITOR_INSTANCE) {
            uv1, uv2, uv3 := triangle_uvs(v1, v2, v3, tri.rot);

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
        } else {
            material := DEFAULT_MATERIAL;
            material.maps[rl.MaterialMapIndex.ALBEDO].color = color;
            if (asset_exists(tri.texture_tag)) {
                tex := get_asset_var(tri.texture_tag, Texture);
                material.maps[rl.MaterialMapIndex.ALBEDO].texture = tex;
            }

            if (tri.is_lit) do rlg.DrawMesh(tri.mesh, material, rl.Matrix(1));
            else do rl.DrawMesh(tri.mesh, material, rl.Matrix(1));
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

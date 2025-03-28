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

oe.msc_init_atlas(msc, "../assets/atlas.png");
oe.atlas_texture(&msc.atlas, {0, 0, 256, 256}, "albedo");
oe.atlas_texture(&msc.atlas, {256, 0, 256, 256}, "water");
oe.atlas_texture(&msc.atlas, {256 * 2, 0, 256, 256}, "tile");
*/

tri_count: i32;

AtlasTexture :: struct {
    tag: string,
    uvs: [4]Vec2,
}

Atlas :: struct {
    using texture: Texture,
    subtextures: [dynamic]AtlasTexture, 
}

init_atlas :: proc() -> Atlas {
    return {
        subtextures = make([dynamic]AtlasTexture),
    };
}

load_atlas :: proc(path: string) -> Atlas {
    res := init_atlas();
    
    img_path := str_add(path, "/atlas.png");
    res.texture = load_texture(img_path);

    data_path := str_add(path, "/atlas.json");
    data, ok := os.read_entire_file_from_filename(data_path);
    if (!ok) {
        dbg_log("Failed to open file ", DebugType.WARNING);
        return {};
    }
    defer delete(data);

    json_data, err := json.parse(data);
    if (err != json.Error.None) {
		dbg_log("Failed to parse the json file", DebugType.WARNING);
		dbg_log(str_add("Error: ", err), DebugType.WARNING);
		return {};
	}
	defer json.destroy_value(json_data);

    json_obj := json_data.(json.Object);

    for k, v in json_obj {
        if (k == "path") { continue; }

        if (k[:len(k) - 1] == "texture") {
            tex_data := v.(json.Object);
            texture_tag := tex_data["tag"].(json.String);
            texture_uvs := tex_data["uvs"].(json.Array);
            uv0 := Vec2{
                f32(texture_uvs[0].(json.Array)[0].(json.Float)),
                f32(texture_uvs[0].(json.Array)[1].(json.Float)),
            };
            uv1 := Vec2{
                f32(texture_uvs[1].(json.Array)[0].(json.Float)),
                f32(texture_uvs[1].(json.Array)[1].(json.Float)),
            };
            uv2 := Vec2{
                f32(texture_uvs[2].(json.Array)[0].(json.Float)),
                f32(texture_uvs[2].(json.Array)[1].(json.Float)),
            };
            uv3 := Vec2{
                f32(texture_uvs[3].(json.Array)[0].(json.Float)),
                f32(texture_uvs[3].(json.Array)[1].(json.Float)),
            };

            uvs := [4]Vec2 {
                uv0, uv1, uv2, uv3
            };

            at := AtlasTexture {
                tag = strs.clone(texture_tag),
                uvs = uvs,
            };

            append(&res.subtextures, at);
        } 
    }

    return res;
}

atlas_texture :: proc(atlas: ^Atlas, rec: Rect, tag: string, flipped := false) {
    dims := Vec2{f32(atlas.width), f32(atlas.height)};
    uvs: [4]Vec2;
    uvs[0] = {rec.x, rec.y} / dims;
    uvs[1] = {rec.x + rec.width, rec.y} / dims;
    uvs[2] = {rec.x + rec.width, rec.y + rec.height} / dims;
    uvs[3] = {rec.x, rec.y + rec.height} / dims;

    if (flipped) {
        uvs[0] = {rec.x + rec.width, rec.y + rec.height} / dims;
        uvs[1] = {rec.x, rec.y + rec.height} / dims;
        uvs[2] = {rec.x, rec.y} / dims;
        uvs[3] = {rec.x + rec.width, rec.y} / dims;
    } else {
        uvs[0] = {rec.x, rec.y} / dims;
        uvs[1] = {rec.x + rec.width, rec.y} / dims;
        uvs[2] = {rec.x + rec.width, rec.y + rec.height} / dims;
        uvs[3] = {rec.x, rec.y + rec.height} / dims;
    }

    at := AtlasTexture {
        tag = tag,
        uvs = uvs,
    };

    append(&atlas.subtextures, at);
}

atlas_texture_rec :: proc(atlas: Atlas, at: AtlasTexture, flipped := false) -> Rect {
    dims := Vec2{ f32(atlas.width), f32(atlas.height) };
    if (!flipped) {
        x := at.uvs[0].x * dims.x;
        y := at.uvs[0].y * dims.y;
        return {
            x = x, y = y,
            width = (at.uvs[2].x - x) * dims.x,
            height = (at.uvs[2].y - y) * dims.y,
        };
    }

    x := at.uvs[2].x * dims.x;
    y := at.uvs[2].y * dims.y;
    return {
        x = x, y = y,
        width = (at.uvs[0].x - x) * dims.x,
        height = (at.uvs[0].y - y) * dims.y,
    };
}

save_atlas :: proc(atlas: Atlas, path: string) {
    file := file_handle(path, FileMode.WRITE_RONLY | FileMode.CREATE);
    res := "{";

    PathMarshall :: struct {path: string}
    path := PathMarshall{atlas.path};
    data, ok := json.marshal(path, {pretty = true});
    
    if (ok != nil) {
        fmt.printfln("An error occured marshalling data: %v", ok);
        return;
    }

    res = str_add({res, string(data[1:len(data) - 2]), ","});

    for i in 0..<len(atlas.subtextures) {
        _data, _ok := json.marshal(atlas.subtextures[i], {pretty = true});
        
        if (_ok != nil) {
            fmt.printfln("An error occured marshalling data: %v", ok);
            return;
        }

        res = str_add({res, str_add("\n\"texture", i), "\": {\n"});
        res = str_add({res, string(_data[1:len(_data) - 2]), "},\n"});
    }

    res = str_add(res, "\n}");
    file_write(file, res);
    file_close(file);
}

pack_atlas :: proc(atlas: Atlas, path: string) {
    create_dir(path);

    img := rl.LoadImageFromTexture(atlas.texture);
    img_path := str_add({path, "/atlas.png"});
    rl.ExportImage(img, strs.clone_to_cstring(img_path));

    data_path := str_add({path, "/atlas.json"});
    res := atlas;
    res.path = img_path;
    save_atlas(res, data_path);
}

MSCObject :: struct {
    tris: [dynamic]^TriangleCollider,
    _aabb: AABB,
    mesh: rl.Mesh,
    atlas: Atlas,
}

msc_init :: proc() -> ^MSCObject {
    using self := new(MSCObject);

    tris = make([dynamic]^TriangleCollider);

    fa.append(&ecs_world.physics.mscs, self);

    return self;
}

msc_init_atlas :: proc(using self: ^MSCObject, path: string) {
    atlas = init_atlas();
    atlas.texture = load_texture(path);
}

remove_msc :: proc(using self: ^MSCObject) {
    fa.remove(&ecs_world.physics.mscs, fa.get_id(ecs_world.physics.mscs, self));
    tri_count -= i32(len(tris));
}

msc_append_tri :: proc(
    using self: ^MSCObject, 
        a, b, c: Vec3, 
        offs: Vec3 = {}, 
        color: Color = WHITE, 
        texture_tag: string = "", 
        is_lit: bool = true, 
        use_fog: bool = OE_FAE, rot: i32 = 0, normal: Vec3 = {},
        flipped := false) {
    t := new(TriangleCollider);
    t.pts = {a + offs, b + offs, c + offs};
    t.normal = normal;
    t.color = color;
    t.texture_tag = texture_tag;
    t.rot = rot;
    t.is_lit = is_lit;
    t.use_fog = use_fog;
    t.flipped = flipped;

    if (flipped) {
        t.normal = -t.normal;
    }

    add := true;
    for i in 0..<len(tris) {
        _t := tris[i];
        if (_t.pts == t.pts) {
            add = false;
            break;
        }
    }

    if (add) { append(&tris, t); }
    tri_count += 1;

    _aabb = tris_to_aabb(tris);
}

msc_append_quad :: proc(
    using self: ^MSCObject, 
    a, b, c, d: Vec3, 
    offs: Vec3 = {}, color: Color = WHITE, 
    texture_tag: string = "", is_lit: bool = true, 
    use_fog: bool = OE_FAE, rot: i32 = 0,
    flipped: bool = false) {
    t := new(TriangleCollider);
    t.pts = {b + offs, a + offs, c + offs};
    t.normal = surface_normal(t.pts);
    t.color = color;
    t.texture_tag = texture_tag;
    t.rot = rot;
    t.is_lit = is_lit;
    t.use_fog = use_fog;
    t.flipped = flipped;

    if (flipped) {
        t.normal = -t.normal;
    }

    add := true;
    for i in 0..<len(tris) {
        _t := tris[i];
        if (_t.pts == t.pts) {
            add = false;
            break;
        }
    }

    if (add) { append(&tris, t); }

    t2 := new(TriangleCollider);
    t2.pts = {b + offs, c + offs, d + offs};
    t2.normal = surface_normal(t2.pts);
    t2.color = color;
    t2.texture_tag = texture_tag;
    t2.rot = rot;
    t2.is_lit = is_lit;
    t2.use_fog = use_fog;
    t2.flipped = flipped;

    if (flipped) {
        t2.normal = -t2.normal;
    }

    add2 := true;
    for i in 0..<len(tris) {
        _t := tris[i];
        if (_t.pts == t2.pts) {
            add2 = false;
            break;
        }
    }

    if (add2) { append(&tris, t2); }

    tri_count += 2;

    _aabb = tris_to_aabb(tris);
}

tri_recalc_uvs :: proc(t: ^TriangleCollider, #any_int uv_rot: i32 = 0) {
    t.rot = uv_rot;
}

msc_gen_mesh :: proc(using self: ^MSCObject) {
    mesh.triangleCount = i32(len(tris));
    mesh.vertexCount = mesh.triangleCount * 3;
    allocate_mesh(&mesh);

    for i in 0..<len(tris) {
        gen_tri(self, tris[i], i);
    }

    rl.UploadMesh(&mesh, false);
}

gen_tri :: proc(using self: ^MSCObject, t: ^TriangleCollider, #any_int index: i32) {
    verts := t.pts;

    at: AtlasTexture;
    for st in atlas.subtextures {
        if (st.tag == t.texture_tag) {
            at = st;
        }
    }

    uv1, uv2, uv3 := atlas_triangle_uvs(
        verts[0], verts[1], verts[2],
        at.uvs,
        0
    );

    v_offset := index * 9;
    uv_offset := index * 6;
    clr_offset := index * 12;

    normal := t.normal;

    mesh.vertices[v_offset + 0] = verts[0].x;
    mesh.vertices[v_offset + 1] = verts[0].y;
    mesh.vertices[v_offset + 2] = verts[0].z;
    mesh.normals[v_offset + 0] = normal.x;
    mesh.normals[v_offset + 1] = normal.y;
    mesh.normals[v_offset + 2] = normal.z;
    mesh.texcoords[uv_offset + 0] = uv1.x;
    mesh.texcoords[uv_offset + 1] = uv1.y;
    mesh.colors[clr_offset + 0] = t.color.r;
    mesh.colors[clr_offset + 1] = t.color.g;
    mesh.colors[clr_offset + 2] = t.color.b;
    mesh.colors[clr_offset + 3] = t.color.a;

    mesh.vertices[v_offset + 3] = verts[1].x;
    mesh.vertices[v_offset + 4] = verts[1].y;
    mesh.vertices[v_offset + 5] = verts[1].z;
    mesh.normals[v_offset + 3] = normal.x;
    mesh.normals[v_offset + 4] = normal.y;
    mesh.normals[v_offset + 5] = normal.z;
    mesh.texcoords[uv_offset + 2] = uv2.x;
    mesh.texcoords[uv_offset + 3] = uv2.y;
    mesh.colors[clr_offset + 4] = t.color.r;
    mesh.colors[clr_offset + 5] = t.color.g;
    mesh.colors[clr_offset + 6] = t.color.b;
    mesh.colors[clr_offset + 7] = t.color.a;

    mesh.vertices[v_offset + 6] = verts[2].x;
    mesh.vertices[v_offset + 7] = verts[2].y;
    mesh.vertices[v_offset + 8] = verts[2].z;
    mesh.normals[v_offset + 6] = normal.x;
    mesh.normals[v_offset + 7] = normal.y;
    mesh.normals[v_offset + 8] = normal.z;
    mesh.texcoords[uv_offset + 4] = uv3.x;
    mesh.texcoords[uv_offset + 5] = uv3.y;
    mesh.colors[clr_offset + 8] = t.color.r;
    mesh.colors[clr_offset + 9] = t.color.g;
    mesh.colors[clr_offset + 10] = t.color.b;
    mesh.colors[clr_offset + 11] = t.color.a;
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

            normal := Vec3 { 
                mesh.normals[j * 3], 
                mesh.normals[j * 3 + 1], 
                mesh.normals[j * 3 + 2]
            };

            msc_append_tri(self, v0, v1, v2, offs, texture_tag = tag, normal = normal);
        } 
    }
}

msc_to_json :: proc(
    using self: ^MSCObject, 
    path: string,
    save_dids: bool = true,
    mode: FileMode = FileMode.WRITE_RONLY | FileMode.CREATE) {
    file := file_handle(path, mode);
    
    res: string = "{";

    TriangleColliderMarshal :: struct {
        using pts: [3]Vec3,
        color: Color,
        texture_tag: string,
        is_lit: bool,
        use_fog: bool,
        rot: i32,
        flipped: bool,
        normal: Vec3,
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
            flipped = t.flipped,
            normal = t.normal,
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
        components: []ComponentMarshall, 
    };

    if (save_dids) {
        j := 0;
        dids := get_reg_data_ids();
        for i in 0..<len(dids) {
            data_id := dids[i];
            mrshl := DataIDMarshall {
                data_id.tag, 
                data_id.id, 
                data_id.transform,
                fa.slice(new_clone(data_id.comps)),
            };
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
    }

    res = str_add(res, "\n}");
    file_write(file, res);
    file_close(file);
}

load_data_ids :: proc(
    path: string, 
    mode: FileMode = FileMode.WRITE_RONLY | FileMode.CREATE
) {
    file := file_handle(path, mode);
    
    res: string = "{";

    DataIDMarshall :: struct {
        tag: string,
        id: u32,
        transform: Transform,
        components: []ComponentMarshall, 
    };

    j := 0;
    dids := get_reg_data_ids();
    for i in 0..<len(dids) {
        data_id := dids[i];
        mrshl := DataIDMarshall {
            data_id.tag, 
            data_id.id, 
            data_id.transform,
            fa.slice(new_clone(data_id.comps)),
        };
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

msc_from_json :: proc(using self: ^MSCObject, path: string, load_dids := true) {
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
        else { 
            if (load_dids) {
                msc_load_data_id(strs.clone(obj.(json.Object)["tag"].(json.String)), obj); 
            }
        }
    }
}

save_data_ids :: proc(
    path: string,
    mode: FileMode = FileMode.WRITE_RONLY | FileMode.CREATE) {
    file := file_handle(path, mode);
    
    res: string = "{";

    DataIDMarshall :: struct {
        tag: string,
        id: u32,
        transform: Transform,
        components: []ComponentMarshall, 
    };

    j := 0;
    dids := get_reg_data_ids();
    for i in 0..<len(dids) {
        data_id := dids[i];
        mrshl := DataIDMarshall {
            data_id.tag, 
            data_id.id, 
            data_id.transform,
            fa.slice(new_clone(data_id.comps)),
        };
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

save_map :: proc(
    name, path: string, mode: FileMode = .WRITE_RONLY | .CREATE) {
    dir := str_add({path, "/", name})
    create_dir(dir);

    for i in 0..<ecs_world.physics.mscs.len {
        msc := ecs_world.physics.mscs.data[i];
        if (len(msc.tris) == 0) { continue; }
        name := str_add("msc", i);
        res_path := str_add({dir, "/", name, ".json"});
        msc_to_json(ecs_world.physics.mscs.data[i], res_path, save_dids = false);
    }

    save_data_ids(str_add(dir, "/data_ids.json"));
}

load_map :: proc(path: string, atlas: Atlas) {
    list := get_files(path);

    for dir in list {
        msc := msc_init();
        msc_from_json(msc, dir);
        msc.atlas = atlas;
        msc_gen_mesh(msc);
    }
}

update_msc :: proc(old, new: ^MSCObject) {
    res := make([dynamic]^TriangleCollider);
    tri_count -= i32(len(old.tris));

    for i in 0..<len(old.tris) {
        tri_i := old.tris[i];
        append(&res, new_clone(tri_i^));
        tri_count += 1;
    }

    for i in 0..<len(new.tris) {
        tri_i := new.tris[i];
        add := true;
        for j in 0..<len(res) {
            tri_j := res[j];
            if (tri_i.pts == tri_j.pts) {
                add = false;
            }
        }

        if (add) {
            append(&res, new_clone(tri_i^));
            tri_count += 1;
        }
    }

    old.tris = res;
    old._aabb = tris_to_aabb(old.tris);
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

    comps_arr := fa.fixed_array(ComponentMarshall, 16);

    if (window.instance_name != EDITOR_INSTANCE) {
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
                fa.append(
                    &comps_arr, 
                    ComponentMarshall {
                        strs.clone(tag), 
                        strs.clone(type)
                    },
                );
            }
        }
    } else {
        if (obj.(json.Object)["components"] != nil) {
            comps_handle := obj.(json.Object)["components"].(json.Array);
            for i in comps_handle {
                tag := i.(json.Object)["tag"].(json.String);
                type := i.(json.Object)["type"].(json.String);
          
                fa.append(
                    &comps_arr, 
                    ComponentMarshall {
                        strs.clone(tag), 
                        strs.clone(type)
                    },
                );
            }
        }
    }

    reg_asset(
        reg_tag, 
        DataID {
            reg_tag, 
            tag, 
            u32(id), 
            transform,
            comps_arr,
        }
    );
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

    flipped: bool;
    if (obj.(json.Object)["flipped"] != nil) {
        flipped = obj.(json.Object)["flipped"].(json.Boolean);
    }

    normal: Vec3;
    set_normal := false;
    if (obj.(json.Object)["normal"] != nil) {
        normal = json_vec3_to_vec3(obj.(json.Object)["normal"].(json.Array));
        set_normal = true;
    }

    if (set_normal) {
        msc_append_tri(
            self, tri[0], tri[1], tri[2], 
            color = color, texture_tag = strs.clone(tex_tag), 
            is_lit = is_lit, use_fog = use_fog, 
            rot = rot, normal = normal, 
            flipped = flipped
        );
    } else {
        msc_append_tri(
            self, tri[0], tri[1], tri[2], 
            color = color, texture_tag = strs.clone(tex_tag), 
            is_lit = is_lit, use_fog = use_fog, 
            rot = rot, normal = surface_normal(tri), 
            flipped = flipped
        );
    }
}

msc_render :: proc(using self: ^MSCObject) {
    m := DEFAULT_MATERIAL;
    m.maps[rl.MaterialMapIndex.ALBEDO].texture = atlas;

    if (window.instance_name == EDITOR_INSTANCE) {
        msc_old_render(self);
    } else {
        rlg.DrawMesh(mesh, m, rl.Matrix(1));
    }

    if (PHYS_DEBUG) {
        for tri in tris {
            t := tri.pts;

            rl.DrawLine3D(t[0], t[1], rl.YELLOW);
            rl.DrawLine3D(t[0], t[2], rl.YELLOW);
            rl.DrawLine3D(t[1], t[2], rl.YELLOW);

            normal := tri.normal;
            rl.DrawLine3D(t[0], t[0] + normal, rl.RED);
            rl.DrawLine3D(t[1], t[1] + normal, rl.RED);
            rl.DrawLine3D(t[2], t[2] + normal, rl.RED);

            centroid := (t[0] + t[1] + t[2]) / 3;
            rl.DrawLine3D(centroid, centroid + normal, RED);
        }

        draw_cube_wireframe(
            {_aabb.x, _aabb.y, _aabb.z}, {}, 
            {_aabb.width, _aabb.height, _aabb.depth},
            PHYS_DEBUG_COLOR
        ); 
    }
}

msc_old_render :: proc(using self: ^MSCObject) {
    for tri in tris {
        t := tri.pts;

        v1 := t[0];
        v2 := t[1];
        v3 := t[2];
        color := tri.color;

        // uv1, uv2, uv3 := triangle_uvs(v1, v2, v3, tri.rot);

        at: AtlasTexture;
        for st in atlas.subtextures {
            if (st.tag == tri.texture_tag) {
                at = st;
            }
        }

        verts := tri.pts;
        uv1, uv2, uv3 := atlas_triangle_uvs(
            verts[0], verts[1], verts[2],
            at.uvs,
            0
        );
        
        // fmt.println(uv1, uv2, uv3, tri.texture_tag, at);

        rl.rlColor4ub(color.r, color.g, color.b, color.a);
        rl.rlBegin(rl.RL_TRIANGLES);

        // if (asset_exists(tri.texture_tag)) {
        //     tex := get_asset_var(tri.texture_tag, Texture);
        //     rl.rlSetTexture(tex.id);
        // }
        rl.rlSetTexture(atlas.texture.id);

        rl.rlTexCoord2f(uv1.x, uv1.y); rl.rlVertex3f(v1.x, v1.y, v1.z);
        rl.rlTexCoord2f(uv2.x, uv2.y); rl.rlVertex3f(v2.x, v2.y, v2.z);
        rl.rlTexCoord2f(uv3.x, uv3.y); rl.rlVertex3f(v3.x, v3.y, v3.z);

        rl.rlEnd();

        rl.rlSetTexture(0);
    }
}

msc_deinit :: proc(using self: ^MSCObject) {
    delete(tris);
}

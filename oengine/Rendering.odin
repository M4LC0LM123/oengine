package oengine

import rl "vendor:raylib"
import rlg "rllights"
import "core:fmt"
import "core:math"
import strs "core:strings"

DEF_RINGS :: 16
DEF_SLICES :: 16

SkyBox :: [6]Texture;
CubeMap :: [6]Texture;

CubeMapSide :: enum {
    FRONT,
    BACK,
    LEFT,
    RIGHT,
    TOP,
    BOTTOM,
    ALL,
}

world_fog: struct {
    visibility: f32,
    density, gradient: f32,
    color: Color,
}

@(private)
fog_update :: proc(target: Vec3) {
    using world_fog;
    distance := vec3_length(target);
    visibility = math.exp(-math.pow((distance * density), gradient));
    visibility = clamp(visibility, 0, 1);
}

deinit_cubemap :: proc(cm: CubeMap) {
    for i in 0..<6 {
        deinit_texture(cm[i]);
    }
}

mix_color :: proc(color1, color2: Color, v: f32) -> Color {
   c1 := clr_to_arr(color1, f32) / 255;
   c2 := clr_to_arr(color2, f32) / 255;

    return Color {
        u8((c1.r * (1 - v) + c2.r * v) * 255),
        u8((c1.g * (1 - v) + c2.g * v) * 255),
        u8((c1.b * (1 - v) + c2.b * v) * 255),
        255
    };
}

tile_texture :: proc(texture: Texture, tx: i32) -> Texture {
    width := f32(texture.width) / f32(tx);
    height := f32(texture.height) / f32(tx);

    target := rl.LoadRenderTexture(texture.width, texture.height);

    rl.BeginTextureMode(target);
    rl.ClearBackground(rl.WHITE);

    for i in 0..<tx {
        for j in 0..<tx {
            x := f32(j) * width;
            y := f32(i) * height;
            rl.DrawTextureEx(texture, {x, y}, 0, 1 / f32(tx), rl.WHITE);
        }
    }

    rl.EndTextureMode();

    return load_texture(target.texture);
}

draw_grid2D :: proc(slices, spacing: i32, color: Color) {
    rl.rlPushMatrix();
            
    rl.rlTranslatef(f32(-slices * spacing) * 0.5, f32(-slices * spacing) * 0.5, 0);
    
    for i: i32 = 0; i <= slices; i += 1 {
        y := i * spacing;
        rl.DrawLine(0, y, slices * spacing, y, color);
        
        x := i * spacing;
        rl.DrawLine(x, 0, x, slices * spacing, color);
    }

    rl.DrawCircleV(vec2_one() * f32(slices) * 0.5 * f32(spacing), 5, RED);
    
    rl.rlPopMatrix();
}

draw_textured_plane :: proc(texture: Texture, pos: Vec3, scale: Vec2, rot: f32, color: Color) {
    x := pos.x;
    y := pos.y;
    z := pos.z;
    width := scale.x;
    depth := scale.y;

    rl.rlSetTexture(texture.id);

    rl.rlPushMatrix();
    rl.rlTranslatef(x, y, z);
    rl.rlRotatef(rot, 0.0, 1.0, 0.0);
    rl.rlTranslatef(-x, -y, -z);

    rl.rlBegin(rl.RL_QUADS);
    rl.rlColor4ub(color.r, color.g, color.b, color.a);
    // Top Face
    rl.rlNormal3f(0.0, 1.0, 0.0); // Normal Pointing Up
    rl.rlTexCoord2f(0.0, 1.0);
    rl.rlVertex3f(x - width / 2, y, z - depth / 2); // Top Left Of The Texture and Quad
    rl.rlTexCoord2f(0.0, 0.0);
    rl.rlVertex3f(x - width / 2, y, z + depth / 2); // Bottom Left Of The Texture and Quad
    rl.rlTexCoord2f(1.0, 0.0);
    rl.rlVertex3f(x + width / 2, y, z + depth / 2); // Bottom Right Of The Texture and Quad
    rl.rlTexCoord2f(1.0, 1.0);
    rl.rlVertex3f(x + width / 2, y, z - depth / 2); // Top Right Of The Texture and Quad
    // Bottom Face
    rl.rlNormal3f(0.0, -1.0, 0.0); // Normal Pointing Down
    rl.rlTexCoord2f(1.0, 1.0);
    rl.rlVertex3f(x - width / 2, y, z - depth / 2); // Top Right Of The Texture and Quad
    rl.rlTexCoord2f(0.0, 1.0);
    rl.rlVertex3f(x + width / 2, y, z - depth / 2); // Top Left Of The Texture and Quad
    rl.rlTexCoord2f(0.0, 0.0);
    rl.rlVertex3f(x + width / 2, y, z + depth / 2); // Bottom Left Of The Texture and Quad
    rl.rlTexCoord2f(1.0, 0.0);
    rl.rlVertex3f(x - width / 2, y, z + depth / 2); // Bottom Right Of The Texture and Quad
    rl.rlEnd();
    rl.rlPopMatrix();

    rl.rlSetTexture(0);
}

draw_cube_wireframe :: proc(pos, rot, scale: Vec3, color: Color) {
    rl.rlPushMatrix();
    rl.rlRotatef(rot.x, 1, 0, 0);
    rl.rlRotatef(rot.y, 0, 1, 0);
    rl.rlRotatef(rot.z, 0, 0, 1);
        
    rl.DrawCubeWiresV(pos, scale, color);

    rl.rlPopMatrix();
}

draw_sphere_wireframe :: proc(pos, rot: Vec3, radius: f32, color: Color) {
    rl.rlPushMatrix();
    rl.rlRotatef(rot.x, 1, 0, 0);
    rl.rlRotatef(rot.y, 0, 1, 0);
    rl.rlRotatef(rot.z, 0, 0, 1);
        
    rl.DrawSphereWires(pos, radius, DEF_RINGS, DEF_SLICES, color);

    rl.rlPopMatrix();
}

draw_capsule_wireframe :: proc(pos, rot: Vec3, radius, height: f32, color: Color) {
    rl.rlPushMatrix();
    rl.rlRotatef(rot.x, 1, 0, 0);
    rl.rlRotatef(rot.y, 0, 1, 0);
    rl.rlRotatef(rot.z, 0, 0, 1);
        
    rl.DrawCapsuleWires(
        {pos.x, pos.y - height * 0.5, pos.z},
        {pos.x, pos.y + height * 0.5, pos.z},
        radius, DEF_SLICES, DEF_RINGS, color,
    );

    rl.rlPopMatrix();
}

draw_skybox :: proc(textures: [6]Texture, tint: Color, scale: i32 = 200) {
    fix: f32 = 0.5;
    rl.rlPushMatrix();
    rl.rlTranslatef(ecs_world.camera.position.x, ecs_world.camera.position.y, ecs_world.camera.position.z);
    draw_cube_texture_rl(textures[0].data, {0, 0, f32(scale) * 0.5}, f32(scale), -f32(scale), 0, tint); // front
    draw_cube_texture_rl(textures[1].data, {0, 0, -f32(scale) * 0.5}, f32(scale), -f32(scale), 0, tint); // back
    draw_cube_texture_rl(textures[2].data, {-f32(scale) * 0.5, 0, 0}, 0, -f32(scale), f32(scale), tint); // left
    draw_cube_texture_rl(textures[3].data, {f32(scale) * 0.5, 0, 0}, 0, -f32(scale), f32(scale), tint); // right
    draw_cube_texture_rl(textures[4].data, {0, f32(scale) * 0.5, 0}, -f32(scale), 0, -f32(scale), tint); // top
    draw_cube_texture_rl(textures[5].data, {0, -f32(scale) * 0.5, 0}, -f32(scale), 0, f32(scale), tint); // bottom
    rl.rlPopMatrix();
}

set_skybox_filtering :: proc(skybox: [6]Texture) {
    for i: i32 = 0; i < 6; i += 1 {
        rl.rlTextureParameters(skybox[i].id, rl.RL_TEXTURE_MAG_FILTER,
                            rl.RL_TEXTURE_FILTER_LINEAR);
        rl.rlTextureParameters(skybox[i].id, rl.RL_TEXTURE_WRAP_S,
                            rl.RL_TEXTURE_WRAP_CLAMP);
        rl.rlTextureParameters(skybox[i].id, rl.RL_TEXTURE_WRAP_T,
                            rl.RL_TEXTURE_WRAP_CLAMP);
    }
}

mesh_loaders := [?]proc() -> Model {
    load_mesh_cube,
    load_mesh_sphere,
    load_mesh_capsule,
    load_mesh_cylinder,
}

load_mesh_cube :: proc() -> Model {
    return load_model(rl.LoadModelFromMesh(rl.GenMeshCube(1, 1, 1)));
}

load_mesh_sphere :: proc() -> Model {
    return load_model(rl.LoadModelFromMesh(rl.GenMeshSphere(0.5, DEF_RINGS, DEF_SLICES)));
}

load_mesh_cylinder :: proc() -> Model {
    model := rl.LoadModelFromMesh(rl.GenMeshCylinder(0.5, 1, DEF_SLICES));

    if (sys_os() == .Linux) do return load_model(model);

    model.transform = mat4_to_rl_mat(mat4_translate(rl_mat_to_mat4(model.transform), -vec3_y() * 0.5));
    return load_model(model);
}

load_mesh_capsule :: proc() -> Model {
    if (!OE_USE_MESHES) {
        dbg_log("Loaded cube mesh, OE_USE_MESHES disabled");
        dbg_log("Use \"-define:USE_MESHSES=true\" to enable it");
        return load_mesh_cube();
    }

    return load_model(rl.LoadModel(strs.clone_to_cstring(str_add({OE_MESHES_PATH, "capsule.obj"}))));
}

allocate_mesh :: proc(mesh: ^rl.Mesh) {
    mesh.vertices = raw_data(make([]f32, mesh.vertexCount * 3));
    mesh.texcoords = raw_data(make([]f32, mesh.vertexCount * 2));
    mesh.normals = raw_data(make([]f32, mesh.vertexCount * 3));
}

gen_mesh_triangle :: proc(verts: [3]Vec3) -> rl.Mesh {
    mesh: rl.Mesh;
    mesh.triangleCount = 1;
    mesh.vertexCount = mesh.triangleCount * 3;
    allocate_mesh(&mesh);
    uv1, uv2, uv3 := triangle_uvs(verts[0], verts[1], verts[2]);

    // Vertex at (0, 0, 0)
    mesh.vertices[0] = verts[0].x;
    mesh.vertices[1] = verts[0].y;
    mesh.vertices[2] = verts[0].z;
    mesh.normals[0] = 0;
    mesh.normals[1] = 1;
    mesh.normals[2] = 0;
    mesh.texcoords[0] = uv1.x;
    mesh.texcoords[1] = uv1.y;

    // Vertex at (1, 0, 2)
    mesh.vertices[3] = verts[1].x;
    mesh.vertices[4] = verts[1].y;
    mesh.vertices[5] = verts[1].z;
    mesh.normals[3] = 0;
    mesh.normals[4] = 1;
    mesh.normals[5] = 0;
    mesh.texcoords[2] = uv2.x;
    mesh.texcoords[3] = uv2.y;

    // Vertex at (2, 0, 0)
    mesh.vertices[6] = verts[2].x;
    mesh.vertices[7] = verts[2].y;
    mesh.vertices[8] = verts[2].z;
    mesh.normals[6] = 0;
    mesh.normals[7] = 1;
    mesh.normals[8] = 0;
    mesh.texcoords[4] = uv3.x;
    mesh.texcoords[5] = uv3.y;

    rl.UploadMesh(&mesh, false);
    return mesh;
}

draw_model :: proc(model: Model, transform: Transform, color: Color, is_lit: bool = false) {
    rl.rlPushMatrix();
    rl.rlTranslatef(transform.position.x, transform.position.y, transform.position.z);
    rl.rlRotatef(transform.rotation.x, 1, 0, 0);
    rl.rlRotatef(transform.rotation.y, 0, 1, 0);
    rl.rlRotatef(transform.rotation.z, 0, 0, 1);
    rl.rlScalef(transform.scale.x, transform.scale.y, transform.scale.z);
    
    if(is_lit) do rlg.DrawModel(model, {}, 1, color);
    else do rl.DrawModel(model, {}, 1, color);

    rl.rlPopMatrix();
}

shape_transform_renders := [?]proc(Texture, Transform, Color) {
    draw_cube_texture,
    draw_sphere_texture,
};

draw_sphere_texture :: proc(texture: Texture, transform: Transform, color: Color) {
    sphere_shape := rl.LoadModelFromMesh(rl.GenMeshSphere(0.5, DEF_RINGS, DEF_SLICES));
    sphere_shape.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = texture.data;

    rl.rlPushMatrix();
    rl.rlTranslatef(transform.position.x, transform.position.y, transform.position.z);
    rl.rlRotatef(transform.rotation.x, 1, 0, 0);
    rl.rlRotatef(transform.rotation.y, 0, 1, 0);
    rl.rlRotatef(transform.rotation.z, 0, 0, 1);
    rl.rlScalef(transform.scale.x, transform.scale.y, transform.scale.z);
    
    rl.DrawModel(sphere_shape, {}, 1, color);

    rl.rlPopMatrix();
}

cube_map_identity :: proc(tex: Texture) -> CubeMap {
    return CubeMap {
        tex, tex, tex,
        tex, tex, tex,
    };
}

draw_cube_map :: proc(cube_map: CubeMap, transform: Transform, color: Color) {
    rl.rlPushMatrix();
    rl.rlTranslatef(transform.position.x, transform.position.y, transform.position.z);
    rl.rlRotatef(transform.rotation.x, 1, 0, 0);
    rl.rlRotatef(transform.rotation.y, 0, 1, 0);
    rl.rlRotatef(transform.rotation.z, 0, 0, 1);
    rl.rlScalef(transform.scale.x, transform.scale.y, transform.scale.z);

    rl.rlColor4ub(color.r, color.g, color.b, color.a);

    // front
    rl.rlSetTexture(cube_map[0].id);
    rl.rlBegin(rl.RL_QUADS);
    rl.rlNormal3f(0.0, 0.0, 1.0);
    rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(-0.5, -0.5, 0.5);  
    rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(0.5, -0.5, 0.5); 
    rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(0.5, 0.5, 0.5); 
    rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(-0.5, 0.5, 0.5); 
    rl.rlEnd();

    // back
    rl.rlSetTexture(cube_map[1].id);
    rl.rlBegin(rl.RL_QUADS);
    rl.rlNormal3f(0.0, 0.0, -1.0);
    rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(-0.5, -0.5, -0.5);
    rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(-0.5, 0.5, -0.5);
    rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(0.5, 0.5, -0.5);
    rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(0.5, -0.5, -0.5);
    rl.rlEnd();

    // right
    rl.rlSetTexture(cube_map[2].id);
    rl.rlBegin(rl.RL_QUADS);
    rl.rlNormal3f(1.0, 0.0, 0.0);
    rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(0.5, -0.5, -0.5);
    rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(0.5, 0.5, -0.5);
    rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(0.5, 0.5, 0.5);
    rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(0.5, -0.5, 0.5);
    rl.rlEnd();

    // left
    rl.rlSetTexture(cube_map[3].id);
    rl.rlBegin(rl.RL_QUADS);
    rl.rlNormal3f( -1.0, 0.0, 0.0);
    rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(-0.5, -0.5, -0.5);
    rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(-0.5, -0.5, 0.5);
    rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(-0.5, 0.5, 0.5);
    rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(-0.5, 0.5, -0.5);
    rl.rlEnd();

    // top
    rl.rlSetTexture(cube_map[4].id);
    rl.rlBegin(rl.RL_QUADS);
    rl.rlNormal3f(0.0, 1.0, 0.0);
    rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(-0.5, 0.5, -0.5);
    rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(-0.5, 0.5, 0.5);
    rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(0.5, 0.5, 0.5);
    rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(0.5, 0.5, -0.5);
    rl.rlEnd();

    // bottom
    rl.rlSetTexture(cube_map[5].id);
    rl.rlBegin(rl.RL_QUADS);
    rl.rlNormal3f(0.0, -1.0, 0.0);
    rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(-0.5, -0.5, -0.5);
    rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(0.5, -0.5, -0.5);
    rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(0.5, -0.5, 0.5);
    rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(-0.5, -0.5, 0.5);
    rl.rlEnd();

    rl.rlPopMatrix();

    rl.rlSetTexture(0);

}

draw_cube_texture :: proc(texture: Texture, transform: Transform, color: Color) {
    rl.rlSetTexture(texture.id);

    rl.rlPushMatrix();
    rl.rlTranslatef(transform.position.x, transform.position.y, transform.position.z);
    rl.rlRotatef(transform.rotation.x, 1, 0, 0);
    rl.rlRotatef(transform.rotation.y, 0, 1, 0);
    rl.rlRotatef(transform.rotation.z, 0, 0, 1);
    rl.rlScalef(transform.scale.x, transform.scale.y, transform.scale.z);

    rl.rlBegin(rl.RL_QUADS);
    rl.rlColor4ub(color.r, color.g, color.b, color.a);

    // front
    rl.rlNormal3f(0.0, 0.0, 1.0);
    rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(-0.5, -0.5, 0.5);  
    rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(0.5, -0.5, 0.5); 
    rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(0.5, 0.5, 0.5); 
    rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(-0.5, 0.5, 0.5); 

    // back
    rl.rlNormal3f(0.0, 0.0, -1.0);
    rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(-0.5, -0.5, -0.5);
    rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(-0.5, 0.5, -0.5);
    rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(0.5, 0.5, -0.5);
    rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(0.5, -0.5, -0.5);

    // top
    rl.rlNormal3f(0.0, 1.0, 0.0);
    rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(-0.5, 0.5, -0.5);
    rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(-0.5, 0.5, 0.5);
    rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(0.5, 0.5, 0.5);
    rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(0.5, 0.5, -0.5);

    // bottom
    rl.rlNormal3f(0.0, -1.0, 0.0);
    rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(-0.5, -0.5, -0.5);
    rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(0.5, -0.5, -0.5);
    rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(0.5, -0.5, 0.5);
    rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(-0.5, -0.5, 0.5);

    // right
    rl.rlNormal3f(1.0, 0.0, 0.0);
    rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(0.5, -0.5, -0.5);
    rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(0.5, 0.5, -0.5);
    rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(0.5, 0.5, 0.5);
    rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(0.5, -0.5, 0.5);

    // right
    rl.rlNormal3f( -1.0, 0.0, 0.0);
    rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(-0.5, -0.5, -0.5);
    rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(-0.5, -0.5, 0.5);
    rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(-0.5, 0.5, 0.5);
    rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(-0.5, 0.5, -0.5);

    rl.rlEnd();

    rl.rlPopMatrix();

    rl.rlSetTexture(0);
}

draw_cube_texture_rl :: proc(texture: rl.Texture, position: Vec3, width, height, length: f32, color: Color) {
    x := position.x;
    y := position.y;
    z := position.z;

    // Set desired texture to be enabled while drawing following vertex data
    rl.rlSetTexture(texture.id);

    // Vertex data transformation can be defined with the commented lines,
    // but in this example we calculate the transformed vertex data directly when calling rlVertex3f()
    //rlPushMatrix();
        // NOTE: Transformation is applied in inverse order (scale -> rotate -> translate)
        //rlTranslatef(2.0f, 0.0f, 0.0f);
        //rlRotatef(45, 0, 1, 0);
        //rlScalef(2.0f, 2.0f, 2.0f);

        rl.rlBegin(rl.RL_QUADS);
            rl.rlColor4ub(color.r, color.g, color.b, color.a);
            // Front Face
            rl.rlNormal3f(0.0, 0.0, 1.0);       // Normal Pointing Towards Viewer
            rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(x - width/2, y - height/2, z + length/2);  // Bottom Left Of The Texture and Quad
            rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(x + width/2, y - height/2, z + length/2);  // Bottom Right Of The Texture and Quad
            rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(x + width/2, y + height/2, z + length/2);  // Top Right Of The Texture and Quad
            rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(x - width/2, y + height/2, z + length/2);  // Top Left Of The Texture and Quad
            // Back Face
            rl.rlNormal3f(0.0, 0.0, - 1.0);     // Normal Pointing Away From Viewer
            rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(x - width/2, y - height/2, z - length/2);  // Bottom Right Of The Texture and Quad
            rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(x - width/2, y + height/2, z - length/2);  // Top Right Of The Texture and Quad
            rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(x + width/2, y + height/2, z - length/2);  // Top Left Of The Texture and Quad
            rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(x + width/2, y - height/2, z - length/2);  // Bottom Left Of The Texture and Quad
            // Top Face
            rl.rlNormal3f(0.0, 1.0, 0.0);       // Normal Pointing Up
            rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(x - width/2, y + height/2, z - length/2);  // Top Left Of The Texture and Quad
            rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(x - width/2, y + height/2, z + length/2);  // Bottom Left Of The Texture and Quad
            rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(x + width/2, y + height/2, z + length/2);  // Bottom Right Of The Texture and Quad
            rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(x + width/2, y + height/2, z - length/2);  // Top Right Of The Texture and Quad
            // Bottom Face
            rl.rlNormal3f(0.0, - 1.0, 0.0);     // Normal Pointing Down
            rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(x - width/2, y - height/2, z - length/2);  // Top Right Of The Texture and Quad
            rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(x + width/2, y - height/2, z - length/2);  // Top Left Of The Texture and Quad
            rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(x + width/2, y - height/2, z + length/2);  // Bottom Left Of The Texture and Quad
            rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(x - width/2, y - height/2, z + length/2);  // Bottom Right Of The Texture and Quad
            // Right face
            rl.rlNormal3f(1.0, 0.0, 0.0);       // Normal Pointing Right
            rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(x + width/2, y - height/2, z - length/2);  // Bottom Right Of The Texture and Quad
            rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(x + width/2, y + height/2, z - length/2);  // Top Right Of The Texture and Quad
            rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(x + width/2, y + height/2, z + length/2);  // Top Left Of The Texture and Quad
            rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(x + width/2, y - height/2, z + length/2);  // Bottom Left Of The Texture and Quad
            // Left Face
            rl.rlNormal3f( - 1.0, 0.0, 0.0);    // Normal Pointing Left
            rl.rlTexCoord2f(0.0, 0.0); rl.rlVertex3f(x - width/2, y - height/2, z - length/2);  // Bottom Left Of The Texture and Quad
            rl.rlTexCoord2f(1.0, 0.0); rl.rlVertex3f(x - width/2, y - height/2, z + length/2);  // Bottom Right Of The Texture and Quad
            rl.rlTexCoord2f(1.0, 1.0); rl.rlVertex3f(x - width/2, y + height/2, z + length/2);  // Top Right Of The Texture and Quad
            rl.rlTexCoord2f(0.0, 1.0); rl.rlVertex3f(x - width/2, y + height/2, z - length/2);  // Top Left Of The Texture and Quad
        rl.rlEnd();
    //rlPopMatrix();

    rl.rlSetTexture(0);
}

draw_heightmap_wireframe :: proc(heightmap: HeightMap, pos, rot, scale: Vec3, color: Color) {
    rl.rlPushMatrix();
    rl.rlTranslatef(pos.x, pos.y, pos.z);
    rl.rlRotatef(rot.x, 1, 0, 0);
    rl.rlRotatef(rot.y, 0, 1, 0);
    rl.rlRotatef(rot.z, 0, 0, 1);
    rl.rlScalef(scale.x, scale.y, scale.z);

    rl.rlBegin(rl.RL_LINES);
    for z := 0; z < len(heightmap); z += 1 {
        for x := 0; x < len(heightmap[z]); x += 1 {
            rl.rlVertex3f(f32(x) * HEIGHTMAP_SCALE, heightmap[z][x] * HEIGHTMAP_SCALE, f32(z) * HEIGHTMAP_SCALE);
            rl.DrawSphereWires({f32(x), heightmap[z][x] * HEIGHTMAP_SCALE, f32(z)} * HEIGHTMAP_SCALE, 0.1, DEF_RINGS, DEF_SLICES, color);
        }
    }
    rl.rlEnd();

    rl.rlPopMatrix();
}

draw_slope :: proc(slope: Slope, pos, rot, scale: Vec3, tex: Texture, color: Color) {
    rl.rlPushMatrix();
    rl.rlTranslatef(pos.x, pos.y, pos.z);
    rl.rlRotatef(rot.x, 1, 0, 0);
    rl.rlRotatef(rot.y, 0, 1, 0);
    rl.rlRotatef(rot.z, 0, 0, 1);
    rl.rlScalef(scale.x, scale.y, scale.z);

    res := slope;
    normal := Vec3 {-1, 1, 0};

    if (slope_negative(slope)) {
        normal.x = 1;
    }

    if (slope[0][0] == slope[1][0]) {
        res = rotate_slope(slope);
        rl.rlRotatef(90, 0, 1, 0);

        normal = Vec3 {0, 1, -1};
        if (slope_negative(slope)) {
            normal.z = 1;
        }

    }
   
    // quad
    rl.rlSetTexture(tex.id);
    rl.rlBegin(rl.RL_QUADS);
    rl.rlColor4ub(color.r, color.g, color.b, color.a);


    rl.rlNormal3f(normal.x, normal.y, normal.z);
    rl.rlTexCoord2f(0, 0); rl.rlVertex3f(-0.5, res[0][0] - 0.5, 0.5);
    rl.rlTexCoord2f(1, 0); rl.rlVertex3f(0.5, res[1][0] - 0.5, 0.5);
    rl.rlTexCoord2f(1, 1); rl.rlVertex3f(0.5, res[1][1] - 0.5, -0.5);
    rl.rlTexCoord2f(0, 1); rl.rlVertex3f(-0.5, res[0][1] - 0.5, -0.5);

    rl.rlEnd();

    // sides (left then right)
    rl.rlBegin(rl.RL_TRIANGLES);
    rl.rlSetTexture(tex.id);

    if (slope_negative(slope)) {
        rl.rlNormal3f(-1, 0, 0);
        rl.rlTexCoord2f(0, 1); rl.rlVertex3f(-0.5, res[0][1] - 0.5, -0.5);
        rl.rlTexCoord2f(1, 0); rl.rlVertex3f(0.5, res[1][0] - 0.5, -0.5);
        rl.rlTexCoord2f(0, 0); rl.rlVertex3f(-0.5, -0.5, -0.5);

        rl.rlNormal3f(1, 0, 0);
        rl.rlTexCoord2f(0, 1); rl.rlVertex3f(0.5, res[1][0] - 0.5, 0.5);
        rl.rlTexCoord2f(1, 0); rl.rlVertex3f(-0.5, res[0][1] - 0.5, 0.5);
        rl.rlTexCoord2f(0, 0); rl.rlVertex3f(-0.5, -0.5, 0.5);
    } else {
        rl.rlNormal3f(-1, 0, 0);
        rl.rlTexCoord2f(0, 0); rl.rlVertex3f(0.5, -0.5, -0.5);
        rl.rlTexCoord2f(1, 0); rl.rlVertex3f(-0.5, res[0][1] - 0.5, -0.5);
        rl.rlTexCoord2f(0, 1); rl.rlVertex3f(0.5, res[1][0] - 0.5, -0.5);

        rl.rlNormal3f(1, 0, 0);
        rl.rlTexCoord2f(0, 1); rl.rlVertex3f(0.5, res[1][0] - 0.5, 0.5);
        rl.rlTexCoord2f(1, 0); rl.rlVertex3f(-0.5, res[0][1] - 0.5, 0.5);
        rl.rlTexCoord2f(0, 0); rl.rlVertex3f(0.5, -0.5, 0.5);
    }

    rl.rlEnd();

    rl.rlSetTexture(0);

    rl.rlPopMatrix();
}

draw_slope_wireframe :: proc(slope: Slope, pos, rot, scale: Vec3, color: Color) {
    rl.rlPushMatrix();
    rl.rlTranslatef(pos.x, pos.y, pos.z);
    rl.rlRotatef(rot.x, 1, 0, 0);
    rl.rlRotatef(rot.y, 0, 1, 0);
    rl.rlRotatef(rot.z, 0, 0, 1);
    rl.rlScalef(scale.x, scale.y, scale.z);

    rl.DrawPoint3D({}, color);

    rl.rlColor4ub(color.r, color.g, color.b, color.a);
    rl.rlBegin(rl.RL_LINES);

    res := slope;

    if (slope[0][0] == slope[1][0]) {
        res = rotate_slope(slope);
        rl.rlRotatef(90, 0, 1, 0);
    }

    rl.rlVertex3f(-0.5, res[0][0] - 0.5, 0.5);
    rl.rlVertex3f(-0.5, res[0][1] - 0.5, -0.5);

    rl.rlVertex3f(-0.5, res[0][1] - 0.5, -0.5);
    rl.rlVertex3f(0.5, res[1][0] - 0.5, -0.5);

    rl.rlVertex3f(0.5, res[1][0] - 0.5, -0.5);
    rl.rlVertex3f(0.5, res[1][1] - 0.5, 0.5);

    rl.rlVertex3f(0.5, res[1][1] - 0.5, 0.5);
    rl.rlVertex3f(-0.5, res[0][0] - 0.5, 0.5);

    rl.rlVertex3f(-0.5, res[0][0] - 0.5, 0.5);
    rl.rlVertex3f(0.5, res[1][0] - 0.5, -0.5);

    rl.rlEnd();

    rl.rlPopMatrix();
}

@(private = "file")
rotate_slope :: proc(slope: Slope) -> Slope {
    l := len(slope) - 1;

    res: Slope;

    for x := 0; x < len(slope) / 2; x += 1 {
        for y := x; y < l - x; y += 1 {
            res[l - x][x] = slope[l - x][l - y];
            res[l - x][l - y] = slope[y][l - x];
            res[y][l - x] = slope[x][y];
            res[x][y] = slope[l - y][x];
        }
    }

    return res;
}


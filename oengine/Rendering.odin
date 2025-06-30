package oengine

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import strs "core:strings"
import "core:math/linalg"

DEF_RINGS :: 16
DEF_SLICES :: 16

DECAL_PERMANENT :: -1

SkyBox :: [6]Texture;
CubeMap :: [6]Texture;

DEFAULT_MATERIAL: rl.Material;

CubeMapSide :: enum {
    FRONT,
    BACK,
    LEFT,
    RIGHT,
    TOP,
    BOTTOM,
    ALL,
}

tag_image: Texture;

world_fog: struct {
    visibility: f32,
    density, gradient: f32,
    color: Color,
}

Decal :: struct {
    position, normal: Vec3,
    size: Vec2,
    color: Color,
    texture_tag: string,
    _rot: Vec3,
    life_time: f32,
}

new_decal :: proc(pos, normal: Vec3, size: Vec2, texture_tag: string, color: Color = WHITE, life_time: f32 = 5) {
    d := new(Decal);
    d.position = pos;
    d.normal = normal;
    d.size = size;
    d.color = color;
    d.texture_tag = texture_tag;
    d._rot = look_at(d.position, d.position + d.normal);
    d.life_time = life_time;

    append(&ecs_world.decals, d);
}

decal_render :: proc(using d: ^Decal, id: i32) {
    draw_sprite(
        position - d.normal * 0.1, 
        size,
        d._rot,
        get_asset_var(texture_tag, Texture), 
        color
    );

    draw_sprite(
        position + d.normal * 0.1, 
        size,
        d._rot,
        get_asset_var(texture_tag, Texture), 
        color
    );

    if (life_time != DECAL_PERMANENT) {
        life_time -= delta_time();
        if (life_time <= 0) {
            append(&ecs_world.removed_decals, id);
        }
    }
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

tile_texture_xy :: proc(texture: Texture, tx, ty: i32) -> Texture {
    width := f32(texture.width) / f32(tx);
    height := f32(texture.height) / f32(ty);

    target := rl.LoadRenderTexture(texture.width, texture.height);

    rl.BeginTextureMode(target);
    rl.ClearBackground(rl.WHITE);

    for i in 0..<tx {
        for j in 0..<ty {
            x := f32(i) * width;
            y := f32(j) * height;

            rl.DrawTexturePro(
                texture,
                {0, 0, f32(texture.width), f32(texture.height)},
                {x, y, width, height},
                {}, 0, rl.WHITE
            );
        }
    }

    rl.EndTextureMode();

    return load_texture(target.texture);
}

draw_aabb_wires :: proc(aabb: AABB, color: Color) {
    rl.DrawCubeWires({aabb.x, aabb.y, aabb.z}, aabb.width, aabb.height, aabb.depth, color);
}

draw_quad :: proc(pts: [4]Vec3, tex: Texture, clr: Color) {
    rl.rlPushMatrix();

    rl.rlColor4ub(clr.r, clr.g, clr.b, clr.a);
    rl.rlBegin(rl.RL_QUADS);
    rl.rlSetTexture(tex.id);

    rl.rlTexCoord2f(0, 0); rl.rlVertex3f(pts[0].x, pts[0].y, pts[0].z);
    rl.rlTexCoord2f(0, 1); rl.rlVertex3f(pts[1].x, pts[1].y, pts[1].z);
    rl.rlTexCoord2f(1, 1); rl.rlVertex3f(pts[2].x, pts[2].y, pts[2].z);
    rl.rlTexCoord2f(1, 0); rl.rlVertex3f(pts[3].x, pts[3].y, pts[3].z);

    rl.rlEnd();
    rl.rlSetTexture(0);

    rl.rlPopMatrix();
}

draw_sprite :: proc(pos: Vec3, size: Vec2, rot: Vec3, tex: Texture, clr: Color) {
    rl.rlPushMatrix();

    rl.rlTranslatef(pos.x, pos.y, pos.z);
    rl.rlRotatef(rot.x, 1, 0, 0);
    rl.rlRotatef(rot.y, 0, 1, 0);
    rl.rlRotatef(rot.z, 0, 0, 1);
    rl.rlScalef(size.x, size.y, 1);

    rl.rlColor4ub(clr.r, clr.g, clr.b, clr.a);
    rl.rlBegin(rl.RL_QUADS);
    rl.rlSetTexture(tex.id);

    rl.rlTexCoord2f(0, 0); rl.rlVertex3f(-0.5, 0.5, 0);
    rl.rlTexCoord2f(0, 1); rl.rlVertex3f(-0.5, -0.5, 0);
    rl.rlTexCoord2f(1, 1); rl.rlVertex3f(0.5, -0.5, 0);
    rl.rlTexCoord2f(1, 0); rl.rlVertex3f(0.5, 0.5, 0);

    rl.rlEnd();
    rl.rlSetTexture(0);

    rl.rlPopMatrix();
}

draw_debug_axis :: proc(size: f32 = 1) {
    rl.DrawLine3D({}, vec3_x() * size, BLUE);
    rl.DrawLine3D({}, vec3_y() * size, RED);
    rl.DrawLine3D({}, vec3_z() * size, GREEN);
}

draw_data_id :: proc(using self: DataID) {
    draw_cube_wireframe(transform.position, transform.rotation, transform.scale, WHITE);
    rl.DrawBillboard(ecs_world.camera.rl_matrix, tag_image, transform.position, 0.5, YELLOW);
}

draw_text_codepoint_3d :: proc(font: rl.Font, codepoint: char, pos: Vec3, size: f32, backface: bool, tint: Color) {
    index := rl.GetGlyphIndex(font, codepoint);
    scale := size / f32(font.baseSize);
    position := pos;

    position.x += f32(font.glyphs[index].offsetX - font.glyphPadding) / f32(font.baseSize) * scale;
    position.z += f32(font.glyphs[index].offsetY - font.glyphPadding) / f32(font.baseSize) * scale;

    srcRec := rl.Rectangle {
        font.recs[index].x - f32(font.glyphPadding), font.recs[index].y - f32(font.glyphPadding),
        font.recs[index].width + 2.0 * f32(font.glyphPadding), font.recs[index].height + 2.0 * f32(font.glyphPadding)
    };

    width := f32(font.recs[index].width + 2.0 * f32(font.glyphPadding)) / f32(font.baseSize) * scale;
    height := f32(font.recs[index].height + 2.0 * f32(font.glyphPadding)) / f32(font.baseSize) * scale;

    if (font.texture.id <= 0) do return;

    x: f32;
    y: f32;
    z: f32;

    tx := srcRec.x / f32(font.texture.width);
    ty := srcRec.y / f32(font.texture.height);
    tw := (srcRec.x + srcRec.width) / f32(font.texture.width);
    th := (srcRec.y + srcRec.height) / f32(font.texture.height);

    rl.rlCheckRenderBatchLimit(4 + 4 * i32(backface));
    rl.rlSetTexture(font.texture.id);

    rl.rlPushMatrix();
    rl.rlTranslatef(position.x, position.y, position.z);
    rl.rlRotatef(90, 1, 0, 0);

    rl.rlBegin(rl.RL_QUADS);
    rl.rlColor4ub(tint.r, tint.g, tint.b, tint.a);

    // Front Face
    rl.rlNormal3f(0.0, 1.0, 0.0);                                   // Normal Pointing Up
    rl.rlTexCoord2f(tx, ty); rl.rlVertex3f(x,         y, z);              // Top Left Of The Texture and Quad
    rl.rlTexCoord2f(tx, th); rl.rlVertex3f(x,         y, z + height);     // Bottom Left Of The Texture and Quad
    rl.rlTexCoord2f(tw, th); rl.rlVertex3f(x + width, y, z + height);     // Bottom Right Of The Texture and Quad
    rl.rlTexCoord2f(tw, ty); rl.rlVertex3f(x + width, y, z);              // Top Right Of The Texture and Quad

    if (backface)
    {
        // Back Face
        rl.rlNormal3f(0.0, -1.0, 0.0);                              // Normal Pointing Down
        rl.rlTexCoord2f(tx, ty); rl.rlVertex3f(x,         y, z);          // Top Right Of The Texture and Quad
        rl.rlTexCoord2f(tw, ty); rl.rlVertex3f(x + width, y, z);          // Top Left Of The Texture and Quad
        rl.rlTexCoord2f(tw, th); rl.rlVertex3f(x + width, y, z + height); // Bottom Left Of The Texture and Quad
        rl.rlTexCoord2f(tx, th); rl.rlVertex3f(x,         y, z + height); // Bottom Right Of The Texture and Quad
    }

    rl.rlEnd();
    rl.rlPopMatrix();

    rl.rlSetTexture(0);
}

measure_text_3d :: proc(font: rl.Font, text: string, size, spacing, line_spacing: f32) -> Vec3 {
    ctext := strs.clone_to_cstring(text);
    len := rl.TextLength(ctext);
    temp_len: i32;
    len_counter: i32;

    temp_text_width: f32;

    scale := size / f32(font.baseSize);
    text_height := scale;
    text_width: f32;

    letter: char;
    index: i32;

    for i := 0; i < int(len); i += 1 {
        len_counter += 1;

        next: i32;
        r := string([]u8{text[i]});
        letter = rl.GetCodepoint(strs.clone_to_cstring(r), &next);
        index = rl.GetGlyphIndex(font, letter);

        if (letter == 0x3f) do next = 1;
        i += int(next) - 1;

        if (letter != '\n') {
            if (font.glyphs[index].advanceX != 0) do text_width += (f32(font.glyphs[index].advanceX) + spacing) / f32(font.baseSize) * scale;
            else do text_width += f32(font.recs[index].width + f32(font.glyphs[index].offsetX)) / f32(font.baseSize) * scale;
        } else {
            if (temp_text_width < text_width) do temp_text_width = text_width;
            len_counter = 0;
            text_width = 0.0;
            text_height += scale + spacing / f32(font.baseSize) *scale;
        }

        if (temp_len < len_counter) do temp_len = len_counter;
    }

    if (temp_text_width < text_width) do temp_text_width = text_width;

    vec: Vec3;
    vec.x = temp_text_width + f32(f32(temp_len - 1) * spacing / f32(font.baseSize) * scale); // Adds chars spacing to measure
    vec.y = 0.25;
    vec.z = text_height;

    return vec;
}

draw_text_3d :: proc(font: rl.Font, text: string, position: Vec3, size: f32, color: Color, spacing: f32 = 0.5, line_spacing: f32 = 0, rotate: bool = true, backface: bool = false) {
    ctext := strs.clone_to_cstring(text);

    scale := size / f32(font.baseSize);
    text_dimensions := measure_text_3d(font, text, size, spacing, line_spacing);

    adjusted_position: Vec3 = position;
    adjusted_position.x -= text_dimensions.x / 2.0; // Center horizontally
    adjusted_position.z -= text_dimensions.z / 2.0; // Center vertically (Z-axis since it's 3D)

    text_offset_x: f32 = 0;
    text_offset_y: f32 = 0;

    rl.rlPushMatrix();
    if (rotate) {
        rot := Rad2Deg * math.atan2_f32(position.z - ecs_world.camera.position.z, ecs_world.camera.position.x - position.x) + 90;
        rl.rlRotatef(rot, 0, 1, 0);
    }

    length := rl.TextLength(strs.clone_to_cstring(text));
    for i := 0; i < int(length); {
        codepoint_byte_count: i32;
        r := string([]u8{text[i]});
        codepoint := rl.GetCodepoint(strs.clone_to_cstring(r), &codepoint_byte_count);
        index := rl.GetGlyphIndex(font, codepoint);

        if (codepoint == 0x3f) do codepoint_byte_count = 1;

        if (codepoint == '\n') {
            text_offset_x = 0;
            text_offset_y += scale + line_spacing / f32(font.baseSize) * scale;
        } else {
            if ((codepoint != ' ') && (codepoint != '\t')) {
                draw_text_codepoint_3d(
                    font, codepoint,
                    {adjusted_position.x + text_offset_x, adjusted_position.y, adjusted_position.z + text_offset_y},
                    size, backface, color
                );
            }

            if (font.glyphs[index].advanceX == 0) {
                text_offset_x += f32(font.recs[index].width + spacing) / f32(font.baseSize) * scale;
            } else {
                text_offset_x += (f32(font.glyphs[index].advanceX) + spacing) / f32(font.baseSize) * scale;
            }
        }

        i += int(codepoint_byte_count);
    }

    rl.rlPopMatrix();
}

draw_grid3D :: proc(slices, spacing: i32, color: Color) {
    halfSlices := slices / 2;

    rl.rlBegin(rl.RL_LINES);
        for i := -halfSlices; i <= halfSlices; i += 1 {
            if (i == 0) {
                rl.rlColor4ub(color.r, color.g, color.b, color.a);
            } else {
                rl.rlColor4ub(color.r - 50, color.g - 50, color.b - 50, color.a);
            }

            rl.rlVertex3f(f32(i*spacing), 0.0, f32(-halfSlices*spacing));
            rl.rlVertex3f(f32(i*spacing), 0.0, f32(halfSlices*spacing));

            rl.rlVertex3f(f32(-halfSlices*spacing), 0.0, f32(i*spacing));
            rl.rlVertex3f(f32(halfSlices*spacing), 0.0, f32(i*spacing));
        }
    rl.rlEnd();
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

draw_grid2D_inf :: proc(camera_pos: Vec2, slices, spacing: i32, color: Color) {
    screen_w := f32(w_render_width());
    screen_h := f32(w_render_height());

    half_w := screen_w * 0.5;
    half_h := screen_h * 0.5;

    // Calculate visible world-space bounds with slight padding
    pad := f32(spacing)
    min_x := camera_pos.x - half_w - pad;
    max_x := camera_pos.x + half_w + pad;
    min_y := camera_pos.y - half_h - pad;
    max_y := camera_pos.y + half_h + pad;

    // Snap to nearest lower grid point
    start_x := i32(math.floor(min_x / f32(spacing))) * spacing;
    start_y := i32(math.floor(min_y / f32(spacing))) * spacing;
    end_x   := i32(math.ceil(max_x / f32(spacing))) * spacing;
    end_y   := i32(math.ceil(max_y / f32(spacing))) * spacing;

    rl.rlPushMatrix();
    rl.rlTranslatef(-camera_pos.x + half_w, -camera_pos.y + half_h, 0); // Center camera in screen

    // Vertical lines
    for x := start_x; x <= end_x; x += spacing {
        rl.DrawLine(x, start_y, x, end_y, color);
    }

    // Horizontal lines
    for y := start_y; y <= end_y; y += spacing {
        rl.DrawLine(start_x, y, end_x, y, color);
    }

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
    rl.rlTranslatef(pos.x, pos.y, pos.z);
    rl.rlRotatef(rot.x, 1, 0, 0);
    rl.rlRotatef(rot.y, 0, 1, 0);
    rl.rlRotatef(rot.z, 0, 0, 1);

    rl.DrawCubeWiresV({}, scale, color);

    rl.rlPopMatrix();
}

draw_sphere_wireframe :: proc(pos, rot: Vec3, radius: f32, color: Color) {
    rl.rlPushMatrix();
    rl.rlTranslatef(pos.x, pos.y, pos.z);
    rl.rlRotatef(rot.x, 1, 0, 0);
    rl.rlRotatef(rot.y, 0, 1, 0);
    rl.rlRotatef(rot.z, 0, 0, 1);

    rl.DrawSphereWires({}, radius, DEF_RINGS, DEF_SLICES, color);

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
    rl.rlEnableBackfaceCulling();
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
    mesh.colors = raw_data(make([]u8, mesh.vertexCount * 4));
}

gen_mesh_triangle :: proc(verts: [3]Vec3, #any_int uv_rot: i32 = 0) -> rl.Mesh {
    mesh: rl.Mesh;
    mesh.triangleCount = 1;
    mesh.vertexCount = mesh.triangleCount * 3;
    allocate_mesh(&mesh);
    uv1, uv2, uv3 := triangle_uvs(verts[0], verts[1], verts[2], uv_rot);

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

draw_model :: proc(
    model: Model, 
    transform: Transform, 
    color: Color,
    is_lit: bool = false,
    offset: Transform = {{}, {}, {1, 1, 1}},
) {
    rotation := transform.rotation + offset.rotation;
    rotation_axis: Vec3;
    angle: f32;
    if (rotation.x != 0) { 
        angle = rotation.x;
        rotation_axis.x = 1;
    }
    if (rotation.y != 0) { 
        angle = rotation.y;
        rotation_axis.y = 1;
    }
    if (rotation.z != 0) { 
        angle = rotation.z;
        rotation_axis.z = 1;
    }
    if (rotation_axis.x + rotation_axis.y + rotation_axis.z > 1) {
        rotation_axis = {};
    } 

    if (is_lit) { 
        rl.BeginShaderMode(ecs_world.ray_ctx.shader);
        rl.DrawModelEx(
            model, 
            transform.position + offset.position, 
            rotation_axis, angle, 
            transform.scale * offset.scale, color
        ); 
        rl.EndShaderMode();
    }
    else { 
        rl.DrawModelEx(
            model, 
            transform.position + offset.position, 
            rotation_axis, angle, 
            transform.scale * offset.scale, color
        );
    }
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

draw_cube_map :: proc(
    cube_map: CubeMap, transform: Transform, color: Color, lit := false) {
    if (lit) {
        rl.BeginShaderMode(ecs_world.ray_ctx.shader);
        rl.rlEnableShader(ecs_world.ray_ctx.shader.id);
    }

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

    if (lit) {
        rl.rlDisableShader();
        rl.EndShaderMode();
    }
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

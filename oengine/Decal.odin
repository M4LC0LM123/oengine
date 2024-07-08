package oengine

import rl "vendor:raylib"

Decal :: struct {
    vertices: [4]Vec3,
    texture: Texture,
    color: Color,
}

decal_init :: proc(texure: Texture, color: Color, w, h: f32, t: ^TriangleCollider) -> ^Decal {
    using res := new(Decal);

    res.texture = texture;
    res.vertices = square_from_tri(t.pts);
    res.color = color;

    return res;
}

decal_render :: proc(using self: ^Decal) {
    rl.rlBegin(rl.RL_QUADS);
    rl.rlColor4ub(color.r, color.g, color.b, color.a);
    rl.rlSetTexture(texture.id);

    for i in 0..<4 {
        rl.rlVertex3f(vertices[i].x, vertices[i].y, vertices[i].z);
    }

    rl.rlEnd();
    rl.rlSetTexture(0);
}

decal_deinit :: proc(using self: ^Decal) {
    deinit_texture(texture);
}

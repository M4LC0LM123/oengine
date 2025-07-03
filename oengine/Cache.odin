package oengine

import rl "vendor:raylib"

cache: struct {
    tiling: struct {
        textures: map[Vec2i]Texture,
        cubemaps: map[Vec3]Texture,
        meshes: map[Texture]rl.Mesh
    },
}

cache_init :: proc() {
    using cache;
    tiling.textures = make(map[Vec2i]Texture);
    tiling.cubemaps = make(map[Vec3]Texture);
    tiling.meshes = make(map[Texture]rl.Mesh);
}

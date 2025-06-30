package main

import rl "vendor:raylib"
import oe "../../oengine"

editor_data: struct {
    hovered_data_id: string,
    active_data_id: string,
    csg_textures: map[oe.Vec3]oe.Texture,
};

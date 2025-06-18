package oengine

import rl "vendor:raylib"
import str "core:strings"

Texture :: struct {
    using data: rl.Texture,
    path: string,
}

load_texture :: proc {
    load_texture_path,
    load_texture_data,
    load_texture_pro,
}

load_texture_path :: proc(s_path: string) -> Texture {
    return {
        data = rl.LoadTexture(str.clone_to_cstring(s_path)),
        path = s_path,
    };
}

load_texture_data :: proc(s_data: rl.Texture) -> Texture {
    return {
        data = s_data,
        path = DATA_PATH,
    };
}

load_texture_pro :: proc(s_path: string, s_data: rl.Texture) -> Texture {
    return {
        data = s_data,
        path = s_path,
    };
}

deinit_texture :: proc(texture: Texture) {
    rl.UnloadTexture(texture.data);
}

tex_flip_vert :: proc(texture: Texture) -> Texture {
    img := rl.LoadImageFromTexture(texture.data);
    rl.ImageFlipVertical(&img);

    return load_texture(texture.path, rl.LoadTextureFromImage(img));
}

tex_flip_horz :: proc(texture: Texture) -> Texture {
    img := rl.LoadImageFromTexture(texture.data);
    rl.ImageFlipHorizontal(&img);

    return load_texture(texture.path, rl.LoadTextureFromImage(img));
}

Image :: struct {
    data: rl.Image,
    path: string,
}

load_image :: proc {
    load_image_path,
    load_image_data,
    load_image_pro,
}

load_image_path :: proc(s_path: string) -> Image {
    return {
        data = rl.LoadImage(str.clone_to_cstring(s_path)),
        path = s_path,
    };
}

load_image_data :: proc(s_data: rl.Image) -> Image {
    return {
        data = s_data,
        path = DATA_PATH,
    };
}

load_image_pro :: proc(s_path: string, s_data: rl.Image) -> Image {
    return {
        data = s_data,
        path = s_path,
    };
}

deinit_image :: proc(texture: Image) {
    rl.UnloadImage(texture.data);
}

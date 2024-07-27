package oengine

import rl "vendor:raylib"
import str "core:strings"

Sound :: struct {
    using data: rl.Sound,
    path: string,
    volume: f32,
}

load_sound :: proc {
    load_sound_path,
    load_sound_data,
    load_sound_pro,
}

load_sound_path :: proc(s_path: string) -> Sound {
    return {
        data = rl.LoadSound(str.clone_to_cstring(s_path)),
        path = s_path,
        volume = 1.0,
    };
}

load_sound_data :: proc(s_data: rl.Sound) -> Sound {
    return {
        data = s_data,
        path = DATA_PATH,
        volume = 1.0,
    };
}

load_sound_pro :: proc(s_path: string, s_data: rl.Sound) -> Sound {
    return {
        data = s_data,
        path = s_path,
        volume = 1.0,
    };
}

play_sound :: proc(using self: Sound) {
    rl.PlaySound(self);
}

// 0.0 - 1.0
set_sound_vol :: proc(using self: ^Sound, s_volume: f32) {
    volume = s_volume;
    rl.SetSoundVolume(self, volume);
}

deinit_sound :: proc(sound: Sound) {
    rl.UnloadSound(sound);
}

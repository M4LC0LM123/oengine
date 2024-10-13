package oengine

import "ecs"
import "core:fmt"
import rl "vendor:raylib"

MAX_SOUND_DISTANCE :: 10

SpatialAudio :: struct {
    sound: Sound,
    position, _target: Vec3,
    strength: f32,
    can_play: bool,
}

sa_init :: proc(position: Vec3, s_sound: Sound) -> SpatialAudio {
    return SpatialAudio {
        sound = s_sound,
        position = position,
        strength = 1,
        can_play = true
    };
}

sa_play :: proc(using self: ^SpatialAudio) {
    if (!rl.IsSoundPlaying(sound) && can_play) {
        play_sound(sound);
    }
}

sa_update :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    t, sa := ecs.get_components(ent, Transform, SpatialAudio);
    if (is_nil(t, sa)) do return;
    using sa;

    if (ecs_world.camera != nil) { 
        _target = ecs_world.camera.position; 
    }

    dist := vec3_dist(_target, position);
    strength = 1.0 / (dist / MAX_SOUND_DISTANCE + 1.0);
    strength = clamp(strength, 0.0, 1.0); 

    rl.SetSoundVolume(sound, strength);
}

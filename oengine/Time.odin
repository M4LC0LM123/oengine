package oengine

import rl "vendor:raylib"

Timer :: struct {
    last_action: f32, // time since last action
}

interval :: proc(t: ^Timer, seconds: f32) -> bool {
    t.last_action += rl.GetFrameTime();
    
    if (t.last_action >= seconds) {
        t.last_action = 0;
        return true;
    }

    return false;
}


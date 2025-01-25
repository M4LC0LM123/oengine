package oengine

import rl "vendor:raylib"
import str "core:strings"

Model :: struct {
    using data: rl.Model,
    path: string,
}

load_model :: proc {
    load_model_path,
    load_model_data,
    load_model_pro,
}

load_model_path :: proc(s_path: string) -> Model {
    return {
        data = rl.LoadModel(str.clone_to_cstring(s_path)),
        path = s_path,
    };
}

load_model_data :: proc(s_data: rl.Model) -> Model {
    return {
        data = s_data,
        path = DATA_PATH,
    };
}

load_model_pro :: proc(s_path: string, s_data: rl.Model) -> Model {
    return {
        data = s_data,
        path = s_path,
    };
}

// models can have animation so you have to clone it for using it with seperate 
// components if you dont want the animation to affect all of them
model_clone :: proc(m: Model) -> Model {
    return load_model(str.clone(m.path));
}

deinit_model :: proc(Model: Model) {
    rl.UnloadModel(Model.data);
}

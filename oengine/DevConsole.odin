package oengine

import rl "vendor:raylib"

dev_console: struct {
    _rec: rl.Rectangle,
    active: bool,
    _toggle_key: Key,
    command: string,
    output: [dynamic]string,
};

console_init :: proc() {
    using dev_console;
    _toggle_key = .GRAVE;
    output = make([dynamic]string);
}

console_update :: proc() {
    using dev_console;
    _rec = {0, 0, f32(w_render_width()), f32(w_render_height() / 2)};
    if (key_pressed(_toggle_key)) {
        active = !active;
    }

    if (active) {
        if (key_pressed(.ENTER)) {
            if (command != STR_EMPTY) { 
                append(&output, command); 
                gui.text_boxes["CommandTextBox"].text = "";
            }
        }
    }
}

console_render :: proc() {
    using dev_console;
    if (active) {
        rl.DrawRectangleRec(_rec, {0, 0, 0, 125});

        rl.BeginScissorMode(
            i32(_rec.x), i32(_rec.y), i32(_rec.width), i32(_rec.height - 4)
        );

        for i in 0..<len(output) {
            line := output[i];
            gui_text(line, 18, 10, 10 + f32(i) * 20, standalone = true);
        }

        rl.EndScissorMode();

        command = gui_text_box(
            "CommandTextBox", 0, 
            _rec.height - 40, 
            _rec.width - 40, 40, decorated = false, standalone = true
        );

        if (gui_button(
            ">", _rec.width - 40, _rec.height - 40, 
            40, 40, standalone = true, decorated = false)) {
            if (command != STR_EMPTY) { 
                append(&output, command); 
                gui.text_boxes["CommandTextBox"].text = "";
            }
        }
    }
}

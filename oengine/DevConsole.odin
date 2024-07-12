package oengine

import rl "vendor:raylib"
import strs "core:strings"
import "core:fmt"

DC_TEXTBOX_SIZE :: 30

dev_console: struct {
    _rec: rl.Rectangle,
    active: bool,
    _toggle_key: Key,
    command: string,
    output: [dynamic]string,
    commands: map[string]ConsoleCommand,
}

console_init :: proc() {
    using dev_console;
    _toggle_key = .GRAVE;
    output = make([dynamic]string);
    commands = make(map[string]ConsoleCommand);

    console_register(new_command("print", "Print text to console", print_command));
}

console_register :: proc(s_command: ConsoleCommand) {
    using dev_console;    
    commands[s_command.name] = s_command;
}

console_exec :: proc(command: string) {
    using dev_console;
    
    parts := strs.split(command, " ");
    name := strs.to_lower(parts[0]);
    args := len(parts) > 1 ? parts[1:] : {};

    commands[name].action(args);

    // append(&output, strs.clone(command)); 
    gui.text_boxes["CommandTextBox"].text = "";
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
                console_exec(command);
            }
        }

        if (key_pressed(.UP)) {
            gui.text_boxes["CommandTextBox"].text = output[len(output) - 1];
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
            _rec.height - DC_TEXTBOX_SIZE, 
            _rec.width - DC_TEXTBOX_SIZE, DC_TEXTBOX_SIZE, decorated = false, standalone = true
        );

        if (gui_button(
            ">", _rec.width - DC_TEXTBOX_SIZE, _rec.height - DC_TEXTBOX_SIZE, 
            DC_TEXTBOX_SIZE, DC_TEXTBOX_SIZE, standalone = true, decorated = false)) {
            if (command != STR_EMPTY) { 
                console_exec(command);
            }
        }
    }
}

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
    prev_input: string,
}

console_init :: proc() {
    using dev_console;
    _toggle_key = .GRAVE;
    output = make([dynamic]string);
    commands = make(map[string]ConsoleCommand);

    console_register(new_command("listcmds", "List all available commands", list_cmds));
    console_register(new_command("help", "List all available commands", list_cmds));
    console_register(new_command("print", "Print text to console", print_command));
    console_register(new_command("dbg_info", "Shows debug information", debug_info));
    console_register(new_command("set_fps", "Sets the target fps", set_fps));
    console_register(new_command("exit", "Exits the app", exit_cmd));
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

    if (commands[name].action != nil) {
        commands[name].action(args);
    } else {
        console_print(str_add({"Command: ", name, " doesn't exist"}));
    }

    prev_input = gui.text_boxes["CommandTextBox"].text;
    gui.text_boxes["CommandTextBox"].text = "";
}

console_print :: proc(str: string) {
    using dev_console;
    append(&output, strs.clone(str));
}

console_update :: proc() {
    using dev_console;
    _rec = {0, 0, f32(w_render_width()), f32(w_render_height() / 2)};
    if (key_pressed(_toggle_key)) {
        active = !active;

        if (gui.text_boxes["CommandTextBox"] != nil) {
            gui.text_boxes["CommandTextBox"].active = !gui.text_boxes["CommandTextBox"].active;
        }
    }

    if (active) {
        if (key_pressed(.ENTER)) {
            if (command != STR_EMPTY) {
                console_exec(command);
            }
        }

        if (key_pressed(.UP)) {
            gui.text_boxes["CommandTextBox"].text = prev_input;
        }
    }
}

console_render :: proc() {
    using dev_console;
    
    @static offset: f32;

    if (active) {
        rl.DrawRectangleRec(_rec, {0, 0, 0, 125});

        rl.BeginScissorMode(
            i32(_rec.x), i32(_rec.y), i32(_rec.width), i32(_rec.height - 40)
        );

        for i in 0..<len(output) {
            line := output[i];
            y := (10 + f32(i) * 20) - offset;

            if (y + 18 >= _rec.height - 40) {
                offset += 18;
            }

            gui_text(line, 18, 10, y, standalone = true);
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

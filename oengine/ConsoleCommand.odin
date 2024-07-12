package oengine

import strs "core:strings"

CommandAction :: proc(args: []string);

ConsoleCommand :: struct {
    name: string,
    description: string,
    action: CommandAction,
}

new_command :: proc(name, description: string, action: CommandAction) -> ConsoleCommand {
    return ConsoleCommand {
        name = name,
        description = description,
        action = action,
    };
}

print_command :: proc(args: []string) {
    res: string;

    for i in 0..<len(args) {
        res = str_add(res, args[i]);
    }

    append(&dev_console.output, strs.clone(res));
};

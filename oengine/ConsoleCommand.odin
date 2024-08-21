package oengine

import strs "core:strings"
import sc "core:strconv"
import "core:os"

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

    console_print(res);
};

list_cmds :: proc(args: []string) {
    using dev_console;

    for i, v in commands {
        console_print(str_add({v.name, " - ", v.description}));
    }
}

debug_info :: proc(args: []string) {
    using dev_console;
    if (len(args) < 1) {
        console_print("Incorrect usage!");
        return;
    }

    b, ok := sc.parse_bool(args[0]);
    if (ok) {
        window.debug_stats = b;
        console_print(str_add({"Set debug info to: ", args[0]}));
    }
}

dbg_info_pos :: proc(args: []string) {
    using dev_console;
    if (len(args) < 1) {
        console_print("Incorrect usage!");
        return;
    }

    b, ok := sc.parse_int(args[0]);
    if (ok) {
        if (b >= DBG_INFO_POS_COUNT) {
            console_print(str_add({str_add("", b), " >= DBG_INFO_POS_COUNT: ", str_add("", i32(DBG_INFO_POS_COUNT))}));
            return;
        }

        window._dbg_stats_pos = i32(b);
        console_print(str_add({"Set debug info pos to: ", args[0]}));
    }
}

set_fps :: proc(args: []string) {
    using dev_console;
    if (len(args) < 1) {
        console_print("Incorrect usage!");
        return;
    }

    v, ok := sc.parse_int(args[0]);
    if (ok) {
        w_set_target_fps(i32(v));
        console_print(str_add({"Set target fps to: ", args[0]}));
    }
}

exit_cmd :: proc(args: []string) {
    using dev_console;
    console_print("Exiting...");

    ew_deinit();
    w_close();

    os.exit(0); 
}

clear_cmd :: proc(args: []string) {
    clear(&dev_console.output);
    dev_console.offset = 0;
}

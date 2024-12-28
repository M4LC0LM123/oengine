package oengine

import strs "core:strings"
import sc "core:strconv"
import "core:unicode/utf8"
import "core:os"
import "core:fmt"
import "fa"

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

    for ii in 0..<commands.len {
        i, v := fa.map_pair(commands, ii);
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

ent_eval :: proc(args: []string) {
    using dev_console;
    if (len(args) < 1) {
        console_print("Incorrect usage!");
        return;
    }

    ent: AEntity;
    if (is_digit(args[0])) {
        id, _ := sc.parse_int(args[0]);

        ent = ew_get_ent(u32(id));
    } else {
        ent = ew_get_ent(args[0]);
    }

    if (len(args) == 2) {
        for ii in 0..<ent.components.len {
            k, i := fa.map_pair(ent.components, ii);
            type := fmt.aprint(k);

            if (type == args[1]) {
                console_print(fmt.aprint(get_component(ent, type_of(k))^));
                break;
            }
        }
    }

    console_print(str_add("id: ", ent.id));
    console_print(str_add("tag: ", ent.tag));
    console_print(str_add("components: ", ent.components.len));
}

list_ents :: proc(args: []string) {
    using dev_console;

    for i in 0..<ecs_world.ecs_ctx.entities.len {
        ent := ew_get_ent(i);
        console_print(ent.tag);
    }
}

get_cam_pos :: proc(args: []string) {
    console_print(str_add("camera position: ", ecs_world.camera.position));
}

add_car_cmd :: proc(args: []string) {
    using dev_console;
    add_car(ecs_world.camera.position);

    console_print(str_add("Added car at: ", ecs_world.camera.position));
}

clear_cmd :: proc(args: []string) {
    fa.clear(&dev_console.output);
    dev_console.offset = 0;
}

package object_data

import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:reflect"

types := [?]string {
    "i32",
    "f32",
    "string",
    "bool",
    "object",
};

Object :: map[string]ODType

ODType :: union {
    i32,
    f32,
    string,
    bool,
    Object,
}

ObjectPair :: struct {
    obj: ^Object,
    name: string,
}

parse :: proc(data: string) -> Object {
    result: Object = make(Object);

    object_stack := make([dynamic]ObjectPair);
    append(&object_stack, ObjectPair{&result, "root"});

    _data, ok := strings.remove_all(data, "\r");
    lines := strings.split(_data, "\n");
    for line in lines {
        if (line == "") { continue; }

        if (strings.has_prefix(strings.trim_space(line), "object ")) {
            split := strings.split(strings.trim_space(line), " ");
            obj_name := split[1];
            _new := new(Object);

            append(&object_stack, ObjectPair{_new, obj_name});
            continue;
        }

        if (strings.contains(line, "}")) {
            child := object_stack[len(object_stack) - 1];
            parent := object_stack[len(object_stack) - 2];

            parent.obj^[child.name] = child.obj^;

            pop(&object_stack);
            continue;
        }

        split := split_line(line);
    
        offset := 0;
        for i in split {
            if (i == "") {
                offset += 1;
            }
        }

        type := split[offset];
        field_name := split[offset + 1];
        value := split[offset + 3];

        if (type == "i32") {
            val, _ := strconv.parse_int(value);
            object_stack[len(object_stack) - 1].obj[field_name] = i32(val);
        }
        if (type == "f32") {
            val, _ := strconv.parse_f32(value);
            object_stack[len(object_stack) - 1].obj[field_name] = val;
        }
        if (type == "string") {
            val, _ := strings.remove_all(value, "\"");
            object_stack[len(object_stack) - 1].obj[field_name] = val;
        }
        if (type == "bool") {
            val, _ := strconv.parse_bool(value);
            object_stack[len(object_stack) - 1].obj[field_name] = val;
        }

    }

    delete(object_stack);

    return result;
}

marshall :: proc(value: any) -> []string {
    fmt.println(value);
    return nil;
}

split_line :: proc(line: string) -> []string {
    in_string := false;
    length := 1;
    for i in 0..<len(line) {
        c := rune(line[i]);
        if (c == '\"') { 
            in_string = !in_string;
            continue;
        }

        if (c == ' ' && !in_string) {
            length += 1;
        }
    }

    assert(!in_string, "[ERROR] quotes not closed on string definition");

    res := make([]string, length);
    res_i := 0;
    prev_i := -1;
    for i in 0..<len(line) {
        c := rune(line[i]);
        if (c == '\"') { 
            in_string = !in_string;
            continue;
        }

        if (c == ' ' && !in_string) {
            res[res_i] = line[prev_i + 1:i];
            res_i += 1;
            prev_i = i;
        }
    }

    res[res_i] = line[prev_i + 1:];

    return res;
}

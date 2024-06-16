package oengine

// loading trenchbroom .map

import "core:fmt"
import strs "core:strings"
import c "core:c/libc"

Brush :: [6]string;

load_tb_map :: proc(path: string) {
    text := file_to_string_arr(path);

    for i in 0..<len(text) {
        line := text[i];

        if (i < len(text) - 1) {
            if (line == "{" && text[i + 1] == "\"classname\" \"worldspawn\"") do continue;
        }

        brush: Brush;
        start, end := 0, 0;

        if (line == "{") {
            start = i + 1;

            for j in start..<len(text) - 1 {
                if (text[j] == "}") { 
                    end = j; 
                    break;
                }
            }
        }

        for j in start..<end {
            brush[j - start] = text[j];
        }

        if (brush == "") do continue;

        // print_brush(brush);
        fmt.println(brush_to_transform(brush));
        fmt.println();
    }
}

brush_to_transform :: proc(brush: Brush) -> Transform {
    transform: Transform;
    min_x, min_y, min_z: f32 = 0, 0, 0;
    max_x, max_y, max_z: f32 = 0, 0, 0;

    for i in 0..<6 {
        line := brush[i];
        fmt.println(oe_match(line, "( %v %v %v ) ( %v %v %v ) ( %v %v %v )"));

        if (transform.position.x < min_x) do min_x = transform.position.x;
        if (transform.position.y < min_y) do min_y = transform.position.y;
        if (transform.position.z < min_z) do min_z = transform.position.z;

        if (transform.position.x > max_x) do max_x = transform.position.x;
        if (transform.position.y > max_y) do max_y = transform.position.y;
        if (transform.position.z > max_z) do max_z = transform.position.z;
    }

    transform.scale.x = max_x - min_x;
    transform.scale.y = max_y - min_y;
    transform.scale.z = max_z - min_z;

    transform.position.x = (min_x + max_x) / 2;
    transform.position.y = (min_y + max_y) / 2;
    transform.position.z = (min_z + max_z) / 2;

    return transform;
}

print_brush :: proc(brush: Brush) {
    for t in brush {
        fmt.println(t);
    }
}

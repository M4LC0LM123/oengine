package main

import "core:fmt"
import "core:os"
import "core:time"
import od "../../object_data"

main :: proc() {
    text, _ := os.read_entire_file("test.od");
    start := time.now();
    data := od.parse(string(text));
    fmt.println(time.since(start));
    fmt.println(data);

    color: struct {
        r, g, b: i32,
        flags: struct {
            blend: bool,
            transparent: bool,
        },
        channels: struct {
            alpha: f32,
            name: string,
        },
        nested: struct {
            nest: struct {
                bird: bool,
            },
        },
    };

    color.r = data["rgb"].(od.Object)["r"].(i32);
    color.g = data["rgb"].(od.Object)["g"].(i32);
    color.b = data["rgb"].(od.Object)["b"].(i32);

    fmt.println(color);

    player := data["player"].(od.Object);

    fmt.println(od.marshal(color, type_of(color), "color"));
}

package main

import "core:fmt"
import ecs "../src"

ctx: ecs.Context;

Name :: distinct string
TestVal :: distinct u32

test_system :: proc(ctx: ^ecs.Context, ent: ecs.Entity) {
    val, err := ecs.get_component(ctx, ent, TestVal);

    if (err == .NO_ERROR) {
        val^ += 1;
    }
}

main :: proc() {
    ctx = ecs.init_ecs()
    defer ecs.deinit_ecs(&ctx)

    ecs.register_system(&ctx, {TestVal}, test_system);

    player := ecs.create_entity(&ctx)
    defer ecs.destroy_entity(&ctx, player)

    name_component, err := ecs.add_component(&ctx, player, Name("IDeGas"))
    fmt.println(name_component^) 

    remove_err := ecs.remove_component(&ctx, player, Name)

    val_component, err2 := ecs.add_component(&ctx, player, TestVal(0));

    enemy := ecs.create_entity(&ctx);
    defer ecs.destroy_entity(&ctx, enemy);

    val_enemy, err3 := ecs.add_component(&ctx, enemy, TestVal(69));

    for i in 0..<100 {
        ecs.run_systems(&ctx);
        fmt.println(val_component^, val_enemy^);
    }
}

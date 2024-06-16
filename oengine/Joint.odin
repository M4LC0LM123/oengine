package oengine

Joint :: struct {
    id: u32,
    variant: union {
        i32, // default
        ^FixedJoint,
    },

    update: proc(joint: ^Joint),
}
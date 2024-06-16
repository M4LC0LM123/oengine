package oengine

ShapeType :: enum {
    BOX = 0,
    SPHERE,
    CAPSULE,
    CYLINDER,

    // dont use in mesh gen
    MODEL       = 10,
    SPRITE      = 11,
    CUBEMAP     = 12,
    HEIGHTMAP   = 13,
    SLOPE       = 14,
}

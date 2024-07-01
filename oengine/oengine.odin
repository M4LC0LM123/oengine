package oengine

import rl "vendor:raylib"

OE_DEBUG :: true
PHYS_DEBUG :: true

OE_DEBUG_COLOR :: rl.GREEN
PHYS_DEBUG_COLOR :: rl.BLUE

OE_USE_MESHES :: #config(USE_MESHES, true)
OE_MESHES_PATH :: #config(MESHES_PATH, "../resources/meshes/")
OE_FONTS_PATH :: #config(FONTS_PATH, "../resources/fonts/")
OE_USE_LIGHTS :: #config(USE_LIGHTS, true)

DATA_PATH :: "set from data!"

QUOTES :: "\""

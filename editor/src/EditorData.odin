package main

import rl "vendor:raylib"
import oe "../../oengine"

editor_data: struct {
    hovered_data_id: ^oe.DataID,
    active_data_id: ^oe.DataID,
};

#+feature dynamic-literals
package oengine

GridCellSize :: 5.0

hash_cell :: proc(x, y, z: int) -> int {
    // Large primes to reduce collisions
    return (73856093 * x) ~ (19349663 * y) ~ (83492791 * z);
}

SpatialHashGrid :: struct {
    _map: map[int][dynamic]int,
}

insert_body :: proc(grid: ^SpatialHashGrid, body: RigidBody) {
    aabb := aabb_to_bounding_box(trans_to_aabb(body.transform));

    min_cell_x := int(aabb.min.x / GridCellSize);
    min_cell_y := int(aabb.min.y / GridCellSize);
    min_cell_z := int(aabb.min.z / GridCellSize);

    max_cell_x := int(aabb.max.x / GridCellSize);
    max_cell_y := int(aabb.max.y / GridCellSize);
    max_cell_z := int(aabb.max.z / GridCellSize);

    for x in min_cell_x ..=max_cell_x + 1 {
        for y in min_cell_y ..=max_cell_y + 1 {
            for z in min_cell_z ..=max_cell_z + 1 {
                h := hash_cell(x, y, z);
                if h in grid._map {
                    append(&grid._map[h], int(body.id));
                } else {
                    grid._map[h] = {int(body.id)};
                }
            }
        }
    }
}

clear_grid :: proc(grid: ^SpatialHashGrid) {
    clear(&grid._map);
}

generate_candidates :: proc(grid: ^SpatialHashGrid) -> [dynamic][2]int {
    pairs := make([dynamic][2]int);
    for k, bodies in grid._map {
        for i in 0..<len(bodies) {
            for j := i + 1; j < len(bodies); j += 1 {
                pair := [2]int {bodies[i], bodies[j]};
                append(&pairs, pair);
            }
        }
    }

    return pairs;
}

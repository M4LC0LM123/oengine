package oengine

import "core:fmt"
import rl "vendor:raylib"
import "fa"

MIN_TRIS :: 8
MAX_DEPTH :: 6

OctreeNode :: struct {
    aabb: AABB,
    children:  [8]^OctreeNode,
    triangles: [dynamic]^TriangleCollider,
    is_leaf: bool,
}

build_octree :: proc(tris: [dynamic]^TriangleCollider, aabb: AABB, depth: i32) -> ^OctreeNode {
    node := new(OctreeNode);
    node.aabb = aabb;

    if (depth >= MAX_DEPTH || len(tris) <= MIN_TRIS) {
        node.triangles = tris;
        node.is_leaf = true;
        return node;
    }

    child_boxes := split_aabb_8(aabb);
    children_tris := make([][dynamic]^TriangleCollider, 8);

    for tri in tris {
        tri_aabb := compute_aabb(tri.pts[0], tri.pts[1], tri.pts[2]);
        for j in 0..<8 {
            if (aabb_collision(tri_aabb, child_boxes[j])) {
                append(&children_tris[j], tri);
            }
        }
    }

    for i in 0..<8 {
        if (len(children_tris[i]) > 0) {
            node.children[i] = build_octree(children_tris[i], child_boxes[i], depth + 1);
        }
    }

    return node;
}

query_octree :: proc(node: ^OctreeNode, rb: ^RigidBody) {
    aabb := trans_to_aabb(rb.transform);
    if (!aabb_collision(node.aabb, aabb)) { return; }

    if (node.is_leaf) {
        for tri in node.triangles {
            resolve_tri_collision(rb, tri);
        }
        return;
    }

    for i in 0..<len(node.children) {
        child := node.children[i];
        if (child != nil) {
            query_octree(child, rb);
        }
    }
}

render_octree :: proc(node: ^OctreeNode, depth: i32) {
    if node == nil {
        return;
    }

    color := Color {255 - u8(depth) * 20, 255 - u8(depth) * 20, 255, 255};

    draw_aabb_wires(node.aabb, color);

    for i in 0..<8 {
        render_octree(node.children[i], depth + 1);
    }
}

free_octree :: proc(node: ^OctreeNode) {
    if (node == nil) { return; }

    for i in 0..<8 {
        if node.children[i] != nil {
            free_octree(node.children[i]);
            node.children[i] = nil;
        }
    }

    if (node.is_leaf && node.triangles != nil) {
        node.triangles = nil;
    }

    free(node);
}

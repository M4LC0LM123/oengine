package oengine

import str "core:strings"
import rl "vendor:raylib"
import "core:math"
import "core:fmt"

STR_EMPTY :: ""

Vec3 :: rl.Vector3
Vec2 :: rl.Vector2
Vec4 :: rl.Vector4
Vec2i :: [2]i32

Deg2Rad :: math.PI / 180.0
Rad2Deg :: 180.0 / math.PI

Color :: rl.Color
char :: rune

clr_to_arr :: proc(color: Color, $T: typeid) -> [4]T {
    return [4]T {
        T(color.r), T(color.g),
        T(color.b), T(color.a),
    };
}

Mat4 :: struct {
    m0, m4, m8, m12:  f32, // Matrix first row (4 components)
	m1, m5, m9, m13:  f32, // Matrix second row (4 components)
	m2, m6, m10, m14: f32, // Matrix third row (4 components)
	m3, m7, m11, m15: f32, // Matrix fourth row (4 components)
}

vec2_x :: proc() -> rl.Vector2 {
    return {1, 0};
}

vec2_y :: proc() -> rl.Vector2 {
    return {0, 1};
}

vec2_z :: proc() -> rl.Vector2 {
    return {0, 0};
}

vec2_zero :: proc() -> rl.Vector2 {
    return {};
}

vec2_one :: proc() -> rl.Vector2 {
    return {1, 1};
}

vec3_x :: proc() -> rl.Vector3 {
    return {1, 0, 0};
}

vec3_y :: proc() -> rl.Vector3 {
    return {0, 1, 0};
}

vec3_z :: proc() -> rl.Vector3 {
    return {0, 0, 1};
}

vec3_zero :: proc() -> rl.Vector3 {
    return {};
}

vec3_one :: proc() -> rl.Vector3 {
    return {1, 1, 1};
}

vec3_length :: proc(v: rl.Vector3) -> f32 {
    return f32(math.sqrt(v.x*v.x + v.y*v.y * v.z*v.z));
}

vec3_normalize :: proc(v: rl.Vector3) -> rl.Vector3 {
    length := vec3_length(v);
    
    return rl.Vector3 {
        v.x / length,
        v.y / length,
        v.z / length
    };
}

vec3_transform :: proc(v: rl.Vector3, m: Mat4) -> rl.Vector3 {
    result := vec3_zero();

    result.x = v.x * m.m0 + v.y * m.m1 + v.z * m.m2 + m.m3;
    result.y = v.x * m.m4 + v.y * m.m5 + v.z * m.m6 + m.m7;
    result.z = v.x * m.m8 + v.y * m.m9 + v.z * m.m10 + m.m11;

    return result;
}

vec3_dot :: proc(v1, v2: rl.Vector3) -> f32 {
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

vec3_cross :: proc(v1, v2: Vec3) -> Vec3 {
    return { v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y * v2.x };
}

vec3_lerp :: proc(v, target: Vec3, t: f32) -> Vec3 {
    res := Vec3{};
    res.x = v.x + (target.x - v.x) * t;
    res.y = v.y + (target.y - v.y) * t;
    res.z = v.z + (target.z - v.z) * t;
    return res;
}

vec3_to_arr :: proc(v: Vec3) -> [3]f32 {
    return {v.x, v.y, v.z};
}

vec2_to_arr :: proc(v: Vec2) -> [2]f32 {
    return {v.x, v.y};
}

mat4_translate :: proc(mat: Mat4, translation: Vec3) -> Mat4 {
    res := mat;

    res.m12 += translation.x;
    res.m13 += translation.y;
    res.m14 += translation.z;

    return res;
}

mat4_from_yaw_pitch_roll :: proc(yaw, pitch, roll: f32) -> Mat4 {
    // Calculate sin and cos values
    sinYaw := math.sin(yaw);
    cosYaw := math.cos(yaw);
    sinPitch := math.sin(pitch);
    cosPitch := math.cos(pitch);
    sinRoll := math.sin(roll);
    cosRoll := math.cos(roll);

    // Define the matrix elements
    res: Mat4;
    res.m0 = cosYaw * cosPitch;
    res.m4 = cosYaw * sinPitch * sinRoll - sinYaw * cosRoll;
    res.m8 = cosYaw * sinPitch * cosRoll + sinYaw * sinRoll;
    res.m12 = 0;
    res.m1 = sinYaw * cosPitch;
    res.m5 = sinYaw * sinPitch * sinRoll + cosYaw * cosRoll;
    res.m9 = sinYaw * sinPitch * cosRoll - cosYaw * sinRoll;
    res.m13 = 0;
    res.m2 = -sinPitch;
    res.m6 = cosPitch * sinRoll;
    res.m10 = cosPitch * cosRoll;
    res.m14 = 0;
    res.m3 = 0;
    res.m7 = 0;
    res.m11 = 0;
    res.m15 = 1;

    return res;
}

mat4_rotate_ZYX :: proc(z, y, x: f32) -> Mat4 {
    // Calculate sin and cos values
    sinZ := math.sin(z);
    cosZ := math.cos(z);
    sinY := math.sin(y);
    cosY := math.cos(y);
    sinX := math.sin(x);
    cosX := math.cos(x);

    // Define the matrix elements
    res: Mat4;
    res.m0 = cosZ * cosY;
    res.m4 = cosZ * sinY * sinX - sinZ * cosX;
    res.m8 = cosZ * sinY * cosX + sinZ * sinX;
    res.m12 = 0;
    res.m1 = sinZ * cosY;
    res.m5 = sinZ * sinY * sinX + cosZ * cosX;
    res.m9 = sinZ * sinY * cosX - cosZ * sinX;
    res.m13 = 0;
    res.m2 = -sinY;
    res.m6 = cosY * sinX;
    res.m10 = cosY * cosX;
    res.m14 = 0;
    res.m3 = 0;
    res.m7 = 0;
    res.m11 = 0;
    res.m15 = 1;

    return res;
}

mat4_rotate_XYZ :: proc(x, y, z: f32) -> Mat4 {
    // Calculate sin and cos values
    sinX := math.sin(x);
    cosX := math.cos(x);
    sinY := math.sin(y);
    cosY := math.cos(y);
    sinZ := math.sin(z);
    cosZ := math.cos(z);

    // Define the matrix elements
    res: Mat4;
    res.m0 = cosY * cosZ;
    res.m4 = -cosY * sinZ;
    res.m8 = sinY;
    res.m12 = 0;
    res.m1 = sinX * sinY * cosZ + cosX * sinZ;
    res.m5 = -sinX * sinY * sinZ + cosX * cosZ;
    res.m9 = -sinX * cosY;
    res.m13 = 0;
    res.m2 = -cosX * sinY * cosZ + sinX * sinZ;
    res.m6 = cosX * sinY * sinZ + sinX * cosZ;
    res.m10 = cosX * cosY;
    res.m14 = 0;
    res.m3 = 0;
    res.m7 = 0;
    res.m11 = 0;
    res.m15 = 1;

    return res;
}

mat4_to_rl_mat :: proc(mat: Mat4) -> rl.Matrix {
    using mat;
    return rl.Matrix {
        m0, m4, m8, m12,
        m1, m5, m9, m13,
        m2, m6, m10, m14,
        m3, m7, m11, m15,
    };
}

rl_mat_to_mat4 :: proc(mat: rl.Matrix) -> Mat4 {
    return Mat4 {
        m0  = mat[0, 0],
        m4  = mat[0, 1],
        m8  = mat[0, 2],
        m12 = mat[0, 3],
        m1  = mat[1, 0],
        m5  = mat[1, 1],
        m9  = mat[1, 2],
        m13 = mat[1, 3],
        m2  = mat[2, 0],
        m6  = mat[2, 1],
        m10 = mat[2, 2],
        m14 = mat[2, 3],
        m3  = mat[3, 0],
        m7  = mat[3, 1],
        m11 = mat[3, 2],
        m15 = mat[3, 3],
    }
}

load_heightmap :: proc(tex: Texture) -> HeightMap {
    image := rl.LoadImageFromTexture(tex.data);
    heights: [MAX_HEIGHTMAP_SIZE_S]f32;

    image_data := rl.LoadImageColors(image);

    for y in 0..< image.height {
        for x in 0..< image.width {
            index := y * image.width + x;

            grayscale_val := f32(image_data[index].r) / 255.0;

            heights[index] = grayscale_val;
        }
    }

    res: HeightMap;

    for y in 0..< image.height {
        for x in 0..< image.width {
            res[y][x] = heights[y * image.width + x];
        }
    }

    return res;
}

OSType :: enum {
    Unknown,
    Windows,
    Darwin,
    Linux,
    Essence,
    FreeBSD,
    Haiku,
    OpenBSD,
    WASI,
    JS,
    Freestanding,
}

OSTypeStr := [?]string {
    "Unknown",
    "Windows",
    "Darwin",
    "Linux",
    "Essence",
    "FreeBSD",
    "Haiku",
    "OpenBSD",
    "WASI",
    "JS",
    "Freestanding",
}

sys_os :: proc() -> OSType {
    return OSType(ODIN_OS);
}

str_add :: proc {
    str_add_strs,
    str_add_str,
    str_add_f64,
    str_add_f32,
    str_add_int,
    str_add_uint,
    str_add_u32,
}

str_add_strs :: proc(bufs: []string) -> string {
    return str.concatenate(bufs);
}

str_add_str :: proc(buf: string, buf2: string) -> string {
    return str.concatenate({buf, buf2});
}

str_add_f64 :: proc(buf: string, n: f64, fmt: byte = 'f') -> string {
    b: ^str.Builder = new(str.Builder);
    defer free(b);
    str.builder_init(b);

    str.builder_reset(b);
    str.write_f64(b, n, fmt);

    return str.concatenate({buf, str.to_string(b^)});
}

str_add_f32 :: proc(buf: string, n: f32, fmt: byte = 'f') -> string {
    b: ^str.Builder = new(str.Builder);
    defer free(b);
    str.builder_init(b);

    str.builder_reset(b);
    str.write_f32(b, n, fmt);

    return str.concatenate({buf, str.to_string(b^)});
}

str_add_int :: proc(buf: string, #any_int n: int) -> string {
    b: ^str.Builder = new(str.Builder);
    defer free(b);
    str.builder_init(b);

    str.builder_reset(b);
    str.write_int(b, n);

    return str.concatenate({buf, str.to_string(b^)});
}

str_add_uint :: proc(buf: string, n: uint) -> string {
    b: ^str.Builder = new(str.Builder);
    defer free(b);
    str.builder_init(b);

    str.builder_reset(b);
    str.write_uint(b, n);

    return str.concatenate({buf, str.to_string(b^)});
}

str_add_u32 :: proc(buf: string, n: u32) -> string {
    b: ^str.Builder = new(str.Builder);
    defer free(b);
    str.builder_init(b);

    str.builder_reset(b);
    str.write_uint(b, uint(n));

    return str.concatenate({buf, str.to_string(b^)});
}

str_add_char :: proc(buf: string, n: char) -> string {
    b: ^str.Builder = new(str.Builder);
    defer free(b);
    str.builder_init(b);

    str.builder_reset(b);
    str.write_rune(b, n);

    return str.concatenate({buf, str.to_string(b^)});
}
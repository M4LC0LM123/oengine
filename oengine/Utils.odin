package oengine

import str "core:strings"
import rl "vendor:raylib"
import "core:math"
import "core:fmt"
import "core:math/linalg"
import "core:math/rand"

STR_EMPTY :: ""

Vec3 :: linalg.Vector3f32
Vec2 :: linalg.Vector2f32
Vec4 :: linalg.Vector4f32
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

vec2_x :: proc() -> Vec2 {
    return {1, 0};
}

vec2_y :: proc() -> Vec2 {
    return {0, 1};
}

vec2_z :: proc() -> Vec2 {
    return {0, 0};
}

vec2_zero :: proc() -> Vec2 {
    return {};
}

vec2_one :: proc() -> Vec2 {
    return {1, 1};
}

vec3_x :: proc() -> Vec3 {
    return {1, 0, 0};
}

vec3_y :: proc() -> Vec3 {
    return {0, 1, 0};
}

vec3_z :: proc() -> Vec3 {
    return {0, 0, 1};
}

vec3_zero :: proc() -> Vec3 {
    return {};
}

vec3_one :: proc() -> Vec3 {
    return {1, 1, 1};
}

vec3_length :: proc(v: Vec3) -> f32 {
    return f32(math.sqrt(v.x*v.x + v.y*v.y * v.z*v.z));
}

vec3_normalize :: proc(v: Vec3) -> Vec3 {
    length := vec3_length(v);
    
    return Vec3 {
        v.x / length,
        v.y / length,
        v.z / length
    };
}

vec3_transform :: proc(v: Vec3, m: Mat4) -> Vec3 {
    result := vec3_zero();

    result.x = v.x * m.m0 + v.y * m.m1 + v.z * m.m2 + m.m3;
    result.y = v.x * m.m4 + v.y * m.m5 + v.z * m.m6 + m.m7;
    result.z = v.x * m.m8 + v.y * m.m9 + v.z * m.m10 + m.m11;

    return result;
}

vec3_dot :: proc(v1, v2: Vec3) -> f32 {
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

mat4_identity :: proc() -> Mat4 {
    return Mat4 { 1.0, 0.0, 0.0, 0.0,
                  0.0, 1.0, 0.0, 0.0,
                  0.0, 0.0, 1.0, 0.0,
                  0.0, 0.0, 0.0, 1.0 };
}

mat4_look_at :: proc(eye, target, up: Vec3) -> Mat4 {
    result: Mat4;

    length: f32;
    ilength: f32;

    vz := Vec3 { eye.x - target.x, eye.y - target.y, eye.z - target.z };

    v := vz;
    length = math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
    if (length == 0.0) do length = 1.0;
    ilength = 1.0 / length;
    vz.x *= ilength;
    vz.y *= ilength;
    vz.z *= ilength;

    vx := Vec3 { up.y*vz.z - up.z*vz.y, up.z*vz.x - up.x*vz.z, up.x*vz.y - up.y*vz.x };

    v = vx;
    length = math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
    if (length == 0.0) do length = 1.0;
    ilength = 1.0 / length;
    vx.x *= ilength;
    vx.y *= ilength;
    vx.z *= ilength;

    vy := Vec3 { vz.y*vx.z - vz.z*vx.y, vz.z*vx.x - vz.x*vx.z, vz.x*vx.y - vz.y*vx.x };

    result.m0 = vx.x;
    result.m1 = vy.x;
    result.m2 = vz.x;
    result.m3 = 0.0;
    result.m4 = vx.y;
    result.m5 = vy.y;
    result.m6 = vz.y;
    result.m7 = 0.0;
    result.m8 = vx.z;
    result.m9 = vy.z;
    result.m10 = vz.z;
    result.m11 = 0.0;
    result.m12 = -(vx.x*eye.x + vx.y*eye.y + vx.z*eye.z);   // Vector3DotProduct(vx, eye)
    result.m13 = -(vy.x*eye.x + vy.y*eye.y + vy.z*eye.z);   // Vector3DotProduct(vy, eye)
    result.m14 = -(vz.x*eye.x + vz.y*eye.y + vz.z*eye.z);   // Vector3DotProduct(vz, eye)
    result.m15 = 1.0;

    return result;
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

mat4_to_arr :: proc(mat: Mat4) -> [4*4]f32 {
    using mat;
    return [4*4]f32 {
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

mat4_perspective :: proc(fovY, aspect, nearPlane, farPlane: f32) -> Mat4 {
    result: Mat4;

    top := nearPlane * math.tan(fovY * 0.5);
    bottom := -top;
    right := top * aspect;
    left := -right;

    rl := f32(right - left);
    tb := f32(top - bottom);
    fn := f32(farPlane - nearPlane);

    result.m0 = (f32(nearPlane) * 2.0) / rl;
    result.m5 = (f32(nearPlane) * 2.0) / tb;
    result.m8 = (f32(right) + f32(left)) / rl;
    result.m9 = (f32(top) + f32(bottom)) / tb;
    result.m10 = -(f32(farPlane) + f32(nearPlane)) / fn;
    result.m11 = -1.0;
    result.m14 = -(f32(farPlane) * f32(nearPlane) * 2.0) / fn;

    return result;
}

rand_val :: proc(min, max: f32) -> f32 {
    return rand.float32_range(min, max);
}

transform_to_rl_bb :: proc(transform: Transform) -> rl.BoundingBox {
    return rl.BoundingBox {
        min = transform.position - transform.scale * 0.5,
        max = transform.position + transform.scale * 0.5
    };
}

contains :: proc(element, array: rawptr, arr_len: int, $T: typeid) -> bool {
    elem := cast(^T)element;
    arr := cast([^]T)array;
    // fmt.println(elem^, arr[0:arr_len]);

    for i in arr[0:arr_len] {
        if i == elem^ {
            return true;
        }
    }

    return false;
}

arr_id :: proc(element, array: rawptr, arr_len: int, $T: typeid) -> int {
    elem := cast(^T)element;
    arr := cast([^]T)array;
    // fmt.println(elem^, arr[0:arr_len]);

    for i in 0..<len(arr[0:arr_len]) {
        if arr[0:arr_len][i] == elem^ {
            return i;
        }
    }

    return 0;
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

package fa

FixedArray :: struct($T: typeid, $V: i32) {
    data: [V]T,
    len, cap: i32,
    empty: T,
}

fixed_array :: proc {
    fixed_array_simple,
    fixed_array_custom,
}

fixed_array_simple :: proc($T: typeid, $V: i32) -> FixedArray(T, V) {
    res: FixedArray(T, V);
    res.cap = V;
    return res;
}

fixed_array_custom :: proc($T: typeid, $V: i32, empty: T) -> FixedArray(T, V) {
    res: FixedArray(T, V);
    
    for i in 0..<V {
        res.data[i] = empty;
    }

    res.cap = V;
    res.empty = empty;
    return res;
}

append_arr :: proc(arr: ^$T/FixedArray, elem: $E) {
    arr.data[arr.len] = elem;

    if (arr.len == arr.cap) do return;

    arr.len += 1;
}

remove_arr :: proc(arr: ^$T/FixedArray, #any_int id: i32) {
    for i in id..<arr.cap - 1 {
        arr.data[i] = arr.data[i + 1];
    }

    arr.data[arr.cap - 1] = arr.empty;

    arr.len -= 1;
}

clear_arr :: proc(arr: ^$T/FixedArray) {
    for i in 0..<arr.cap {
        arr.data[i] = arr.empty;
    }
    arr.len = 0;
}

range_arr :: proc(arr: $T/FixedArray) -> int {
    return int(arr.len);
}

get_id :: proc(arr: $T/FixedArray, elem: $E) -> i32 {
    for i in 0..<arr.len {
        if (arr.data[i] == elem) do return i;
    }

    return -1;
}

contains :: proc(arr: $T/FixedArray, elem: $E) -> bool {
    id := get_id(arr, elem);
    if (id == -1) do return false;

    return true;
}

slice :: proc(arr: ^FixedArray($T, $V)) -> []T {
    return arr.data[:arr.len];
}

range :: range_arr
append :: append_arr
remove :: remove_arr
clear :: clear_arr

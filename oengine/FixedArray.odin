package oengine

FixedArray :: struct($T: typeid) {
    data: []T,
    _i, len, cap: i32,
    empty: T,
}

fixed_array :: proc {
    fixed_array_simple,
    fixed_array_custom,
}

fixed_array_simple :: proc($T: typeid, #any_int size: i32) -> FixedArray(T) {
    res: FixedArray(T);
    res.data = make([]T, size);
    res.cap = size;
    return res;
}

fixed_array_custom :: proc($T: typeid, #any_int size: i32, empty: T) -> FixedArray(T) {
    res: FixedArray(T);
    res.data = make([]T, size);
    
    for i in 0..<size {
        res.data[i] = empty;
    }

    res.cap = size;
    res.empty = empty;
    return res;
}

append_arr :: proc(arr: ^$T/FixedArray, elem: $E) {
    arr.data[arr._i] = elem;
    arr._i += 1;
    arr.len = arr._i + 1;
}

remove_arr :: proc(arr: ^$T/FixedArray, #any_int id: i32) {
    for i in id..<arr.cap - 1 {
        arr.data[i] = arr.data[i + 1];
    }

    arr.data[arr.cap - 1] = arr.empty;

    arr._i -= 1;
    arr.len = arr._i + 1;
}

clear_arr :: proc(arr: ^$T/FixedArray) {
    for i in 0..<arr.cap {
        arr.data[i] = arr.empty;
    }
}

range_arr :: proc(arr: $T/FixedArray) -> int {
    return int(arr._i);
}

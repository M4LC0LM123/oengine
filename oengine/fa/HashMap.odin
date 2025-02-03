package fa

KeyValuePair :: struct($K, $T: typeid) {
    key: K,
    value: T,
}

HashMap :: struct($K, $T: typeid, $V: i32) {
    data: [V]KeyValuePair(K, T),
    len, cap: i32,
    v_empty: T,
    k_empty: K,
}

hash_map :: proc {
    hash_map_simple,
    hash_map_custom,
}

hash_map_simple :: proc($K, $T: typeid, $V: i32) -> HashMap(K, T, V) {
    res: HashMap(K, T, V);
    res.cap = V;
    return res;
}

hash_map_custom :: proc($K, $T: typeid, $V: i32, 
    v_empty: T, k_empty: K) -> HashMap(K, T, V) {
    res: HashMap(K, T, V);

    for i in 0..<V {
        res.data[i] = {k_empty, v_empty};
    }

    res.cap = V;
    res.v_empty = v_empty;
    res.k_empty = k_empty;
    return res;
}

hmap_set :: proc(_map: ^$T/HashMap, k: $K, v: $E) {
    _map.data[_map.len] = {k, v};

    if (_map.len == _map.cap) do return;

    _map.len += 1;
}

hmap_pair :: proc(_map: HashMap($K, $T, $V), #any_int id: i32) -> (K, T) {
    return _map.data[id].key, _map.data[id].value;
}

hmap_value :: proc(_map: HashMap($K, $T, $V), k: K) -> T {
    id := map_index(_map, k);

    if (id == -1) {
        return _map.v_empty;
    }

    return _map.data[id].value;
}

hmap_remove :: proc(_map: ^$T/HashMap, k: $K) {
    for i in map_index(_map^, k)..<_map.cap - 1 {
        _map.data[i] = _map.data[i + 1];
    }

    _map.data[_map.cap - 1] = {_map.k_empty, _map.v_empty};

    _map.len -= 1;
}

hmap_index :: proc(_map: $T/HashMap, k: $K) -> i32 {
    for i in 0..<_map.len {
        if (_map.data[i].key == k) {
            return i;
        }
    }
    return -1;
}

hmap_clear :: proc(_map: ^$T/HashMap) {
    for i in 0..<_map.cap {
        _map.data[i] = {_map.k_empty, _map.v_empty};
    }
    _map.len = 0;
}

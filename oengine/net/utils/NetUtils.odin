package NetUtils

import enet "vendor:ENet"

read_byte :: proc(packet: ^enet.Packet, offset: ^int) -> u8 {
    value := packet.data[offset^];
    offset^ += 1;
    return value;
}

read_i16 :: proc(packet: ^enet.Packet, offset: ^int) -> i16 {
    byte1 := read_byte(packet, offset);
    byte2 := read_byte(packet, offset);

    result := i16(byte2) << 8 | i16(byte1);
    return result;
}

read_i32 :: proc(packet: ^enet.Packet, offset: ^int) -> i32 {
    byte1 := read_byte(packet, offset);
    byte2 := read_byte(packet, offset);
    byte3 := read_byte(packet, offset);
    byte4 := read_byte(packet, offset);

    result := i32(byte4) << 24 | i32(byte3) << 16 | i32(byte2) << 8 | i32(byte1);
    return result;
}

read_i64 :: proc(packet: ^enet.Packet, offset: ^int) -> i64 {
    combined: i64;

    for i in 0..<8 {
        byte := read_byte(packet, offset);
        combined |= i64(byte) << (i * 8);
    }

    return combined;
}

read_f16 :: proc(packet: ^enet.Packet, offset: ^int) -> f16 {
    byte1 := read_byte(packet, offset);
    byte2 := read_byte(packet, offset);

    combined := u16(byte2) << 8 | u16(byte1);
    return transmute(f16)combined;
}

read_f32 :: proc(packet: ^enet.Packet, offset: ^int) -> f32 {
    byte1 := read_byte(packet, offset);
    byte2 := read_byte(packet, offset);
    byte3 := read_byte(packet, offset);
    byte4 := read_byte(packet, offset);

    combined := u32(byte4) << 24 | u32(byte3) << 16 | u32(byte2) << 8 | u32(byte1);

    return transmute(f32)combined;
}

read_f64 :: proc(packet: ^enet.Packet, offset: ^int) -> f64 {
    combined: u64;

    for i in 0..<8 {
        byte := read_byte(packet, offset);
        combined |= u64(byte) << (i * 8);
    }

    return transmute(f64)byte;
}

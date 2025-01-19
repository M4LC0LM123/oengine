package client

import "core:fmt"
import enet "vendor:Enet"
import "core:strings"
import rl "vendor:raylib"

MAX_PLAYERS :: 10
WIDTH :: 800
HEIGHT :: 600

PLAYER_SIZE :: 10

LocalPlayerId := -1
address: enet.Address
server: ^enet.Peer
client: ^enet.Host

// time data for the network tick
LastInputSend: f64 = -100
InputUpdateInterval: f64 = 1.0 / 20.0
LastNow: f64 = 0
WantDisconnect: bool = false

// player data structure
PlayerInfo :: struct {
    Active   : bool,       // is this player active and valid
    Position : rl.Vector2,  // last known position
    Direction: rl.Vector2,  // movement direction
    UpdateTime : f64,     // last update time
    ExtrapolatedPosition : rl.Vector2, // extrapolated position
}

Players: [MAX_PLAYERS]PlayerInfo

ReadByte :: proc(packet: ^enet.Packet, offset: ^int) -> u8 {
    value := packet.data[offset^];
    offset^ += 1;
    return value;
}

ReadShort :: proc(packet: ^enet.Packet, offset: ^int) -> i16 {
    byte1 := ReadByte(packet, offset)
    byte2 := ReadByte(packet, offset)

    result := i16(byte2) << 8 | i16(byte1)
    return result
}

store_i16 :: proc(buffer: ^[9]u8, offset: i32, value: i16) {
    buffer[offset]     = (u8)(value & 0xFF);        // First byte
    buffer[offset + 1] = (u8)((value >> 8) & 0xFF);   // Second byte
}

Command :: enum u8 {
    ACCEPT = 0,
    ADD,
    REMOVE,
    UPDATE,
    INPUT
}

// Connect to server
Connect :: proc(serverAddress: string) {
    if WantDisconnect {
        return
    }

    enet.initialize()

    // create a client to connect to the server
    client = enet.host_create(nil, 1, 1, 0, 0)

    // set address and port
    enet.address_set_host(&address, strings.clone_to_cstring(serverAddress))
    address.port = 4545

    // start connection process
    server = enet.host_connect(client, &address, 1, 0)
}

// utility functions to read data from the packet
ReadPosition :: proc(packet: ^enet.Packet, offset: ^int) -> rl.Vector2 {
    x := ReadShort(packet, offset)
    y := ReadShort(packet, offset)
    return rl.Vector2{auto_cast x, auto_cast y}
}

// handle server commands
HandleAddPlayer :: proc(packet: ^enet.Packet, offset: ^int) {
    remotePlayer := ReadByte(packet, offset)
    if remotePlayer >= MAX_PLAYERS || remotePlayer == auto_cast LocalPlayerId {
        return
    }

    // set the player as active and update position
    Players[remotePlayer].Active = true
    Players[remotePlayer].Position = ReadPosition(packet, offset)
    Players[remotePlayer].Direction = ReadPosition(packet, offset)
    Players[remotePlayer].UpdateTime = LastNow
}

HandleRemovePlayer :: proc(packet: ^enet.Packet, offset: ^int) {
    remotePlayer := ReadByte(packet, offset)
    if remotePlayer >= MAX_PLAYERS || remotePlayer == auto_cast LocalPlayerId {
        return
    }

    // mark the player as inactive
    Players[remotePlayer].Active = false
}

HandleUpdatePlayer :: proc(packet: ^enet.Packet, offset: ^int) {
    remotePlayer := ReadByte(packet, offset)
    if remotePlayer >= MAX_PLAYERS || remotePlayer == auto_cast LocalPlayerId || !Players[remotePlayer].Active {
        return
    }

    // update position and direction
    Players[remotePlayer].Position = ReadPosition(packet, offset)
    Players[remotePlayer].Direction = ReadPosition(packet, offset)
    Players[remotePlayer].UpdateTime = LastNow
}

// update game state
Update :: proc(now: f64, deltaT: f32) {
    LastNow = now
    if server == nil {
        return
    }

    if !WantDisconnect && LocalPlayerId >= 0 && now - LastInputSend > InputUpdateInterval {
        buffer: [9]u8  // 9 bytes: 1 byte command, 2 bytes for position X and Y
        buffer[0] = u8(Command.INPUT)

        // prepare data for sending
        store_i16(&buffer, 1, auto_cast Players[LocalPlayerId].Position.x)
        store_i16(&buffer, 3, auto_cast Players[LocalPlayerId].Position.y)
        store_i16(&buffer, 5, auto_cast Players[LocalPlayerId].Direction.x)
        store_i16(&buffer, 7, auto_cast Players[LocalPlayerId].Direction.y)

        // create packet and send it
        packet := enet.packet_create(raw_data(buffer[:]), 9, {.RELIABLE})
        enet.peer_send(server, 0, packet)

        LastInputSend = now
    }

    event := enet.Event{}
    if enet.host_service(client, &event, 0) > 0 {
        #partial switch event.type {
            case .RECEIVE: 
                offset := 0
                command := auto_cast ReadByte(event.packet, &offset)

                if LocalPlayerId == -1 {
                    if command == auto_cast Command.ACCEPT {
                        LocalPlayerId = auto_cast ReadByte(event.packet, &offset)
                        if LocalPlayerId < 0 || LocalPlayerId > MAX_PLAYERS {
                            LocalPlayerId = -1
                            break
                        }

                        LastInputSend = -InputUpdateInterval
                        Players[LocalPlayerId].Active = true
                        Players[LocalPlayerId].Position = rl.Vector2{100, 100}
                    }
                } else {
                    switch command {
                        case auto_cast Command.ADD:
                            HandleAddPlayer(event.packet, &offset)
                        case auto_cast Command.REMOVE:
                            HandleRemovePlayer(event.packet, &offset)
                        case auto_cast Command.UPDATE:
                            HandleUpdatePlayer(event.packet, &offset)
                    }
                }
                enet.packet_destroy(event.packet)

            case .DISCONNECT: 
                enet.host_destroy(client)
                enet.deinitialize()

                server = nil
                LocalPlayerId = -1
                WantDisconnect = false
        }
    }

    for i in 0..<MAX_PLAYERS {
        if i == LocalPlayerId || !Players[i].Active {
            continue
        }
        delta := LastNow - Players[i].UpdateTime
        Players[i].ExtrapolatedPosition = Players[i].Position + Players[i].Direction * f32(delta)
    }
}

// disconnect from the server
Disconnect :: proc() {
    if server != nil {
        WantDisconnect = true
        enet.peer_disconnect(server, 0)
    }
}

// check if the client is connected
Connected :: proc() -> bool {
    return server != nil
}

// get local player ID
GetLocalPlayerId :: proc() -> i32 {
    return auto_cast LocalPlayerId
}

// update the local player position
UpdateLocalPlayer :: proc(movementDelta: rl.Vector2, deltaT: f32) {
    if LocalPlayerId < 0 {
        return
    }

    Players[LocalPlayerId].Position = Players[LocalPlayerId].Position + movementDelta * deltaT

    // ensure player is within bounds
    if Players[LocalPlayerId].Position.x < 0 {
        Players[LocalPlayerId].Position.x = 0
    }
    if Players[LocalPlayerId].Position.y < 0 {
        Players[LocalPlayerId].Position.y = 0
    }

    Players[LocalPlayerId].Direction = movementDelta
}

// get position of a particular player
GetPlayerPos :: proc(id: i32, pos: ^rl.Vector2) -> bool {
    if id < 0 || id >= MAX_PLAYERS || !Players[id].Active {
        return false
    }

    if id == auto_cast LocalPlayerId {
        pos^ = Players[id].Position
    } else {
        pos^ = Players[id].ExtrapolatedPosition
    }
    return true
}

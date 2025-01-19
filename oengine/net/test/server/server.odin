package server

import "core:fmt"
import enet "vendor:Enet"

MAX_PLAYERS :: 10

Command :: enum u8 {
    ACCEPT = 0,
    ADD,
    REMOVE,
    UPDATE,
    INPUT
}

// the info we are tracking about each player in the game
PlayerInfo :: struct {
    Active        : bool,   // is this player slot active
    ValidPosition : bool,   // have they sent us a valid position yet?
    Peer          : ^enet.Peer,  // the network connection they use
    X             : i16,    // last known location in X
    Y             : i16,    // last known location in Y
    DX            : i16,    // velocity in X
    DY            : i16,    // velocity in Y
}

Players: [MAX_PLAYERS]PlayerInfo;

// finds the player slot that goes with the player connection
// the peer has the void* ENetPeer::data that can be used to store arbitrary application data
// but that involves managing structure pointers so it is kept out of this example
GetPlayerId :: proc(peer : ^enet.Peer) -> int {
    for i in 0..<MAX_PLAYERS-1 {
        if Players[i].Active && Players[i].Peer == peer {
            return i
        }
    }
    return -1
}

// sends a packet over the network to every active player, except the one specified
SendToAllBut :: proc(packet : ^enet.Packet, exceptPlayerId : int) {
    for i in 0..<MAX_PLAYERS-1 {
        if !Players[i].Active || i == exceptPlayerId {
            continue
        }
        enet.peer_send(Players[i].Peer, 0, packet)
    }
}

store_i16 :: proc(buffer: ^[10]u8, offset: i32, value: i16) {
    buffer[offset]     = (u8)(value & 0xFF);        // First byte
    buffer[offset + 1] = (u8)((value >> 8) & 0xFF);   // Second byte
}

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
// the main server loop
main :: proc() {
    fmt.println("Startup")

    // set up networking
    if enet.initialize() != 0 {
        return
    }

    fmt.println("Initialized")

    // network servers must 'listen' on an interface and a port
    address: enet.Address
    address.host = enet.HOST_ANY
    address.port = 4545

    // create the server host
    server: ^enet.Host = enet.host_create(&address, MAX_PLAYERS, 1, 0, 0)

    if server == nil {
        return
    }

    fmt.println("Created")

    // the server will run forever
    run: bool = true

    // main loop
    for run {
        event: enet.Event
        if enet.host_service(server, &event, 1000) > 0 {
            #partial switch(event.type) {
                case .CONNECT: 
                    fmt.println("Player Connected")

                    // find an empty slot, or disconnect them if we are full
                    playerId: int = 0
                    for playerId < MAX_PLAYERS {
                        if !Players[playerId].Active {
                            break
                        }
                        playerId += 1
                    }

                    // we are full
                    if playerId == MAX_PLAYERS {
                        enet.peer_disconnect(event.peer, 0)
                        break
                    }

                    // player is good, don't give away the slot
                    Players[playerId].Active = true

                    // but don't send out an update to everyone until they give us a good position
                    Players[playerId].ValidPosition = false
                    Players[playerId].Peer = event.peer

                    // pack up a message to send back to the client
                    buffer: [2]u8 = {0, 0}
                    buffer[0] = u8(Command.ACCEPT)  // command for the client
                    buffer[1] = u8(playerId)      // the player ID

                    // create and send packet
                    packet: ^enet.Packet = enet.packet_create(raw_data(buffer[:]), 2, {.RELIABLE})
                    enet.peer_send(event.peer, 0, packet)

                    // We have to tell the new client about all the other players that are already on the server
                    // so send them an add message for all existing active players.
                    for i in 0..<MAX_PLAYERS-1 {
                        if i == playerId || !Players[i].ValidPosition {
                            continue
                        }

                        // pack up an add player message with the ID and the last known position
                        addBuffer: [10]u8;
                        addBuffer[0] = u8(Command.ADD)
                        addBuffer[1] = u8(i)

                        store_i16(&addBuffer, 2, Players[i].X);
                        store_i16(&addBuffer, 4, Players[i].Y);
                        store_i16(&addBuffer, 6, Players[i].DX);
                        store_i16(&addBuffer, 8, Players[i].DY);

                        // create and send packet
                        packet = enet.packet_create(raw_data(addBuffer[:]), 10, {.RELIABLE})
                        enet.peer_send(event.peer, 0, packet)
                    }

                    break;
                case .RECEIVE: 
                    // find the player who sent the data
                    playerId: int = GetPlayerId(event.peer)
                    if playerId == -1 {
                        // not one of our players, boot them
                        enet.peer_disconnect(event.peer, 0)
                        break
                    }

                    offset: int = 0
                    command: Command = auto_cast ReadByte(event.packet, &offset)

                    // update the location data with the new info
                    if command == Command.INPUT {
                        Players[playerId].X = ReadShort(event.packet, &offset)
                        Players[playerId].Y = ReadShort(event.packet, &offset)
                        Players[playerId].DX = ReadShort(event.packet, &offset)
                        Players[playerId].DY = ReadShort(event.packet, &offset)

                        // tell everyone about this new location
                        outboundCommand: Command = Command.UPDATE
                        if !Players[playerId].ValidPosition {
                            outboundCommand = Command.ADD
                        }

                        // mark as valid position
                        Players[playerId].ValidPosition = true

                        // prepare the update message
                        addBuffer: [10]u8;
                        addBuffer[0] = u8(outboundCommand)
                        addBuffer[1] = u8(playerId)

                        store_i16(&addBuffer, 2, Players[playerId].X);
                        store_i16(&addBuffer, 4, Players[playerId].Y);
                        store_i16(&addBuffer, 6, Players[playerId].DX);
                        store_i16(&addBuffer, 8, Players[playerId].DY);

                        // create and send the update packet to all but the sender
                        packet: ^enet.Packet = enet.packet_create(raw_data(addBuffer[:]), 10, {.RELIABLE})
                        SendToAllBut(packet, playerId)
                    }

                    // recycle packet
                    enet.packet_destroy(event.packet)
                case .DISCONNECT: 
                    // player was disconnected
                    fmt.println("Player Disconnected")

                    playerId: int = GetPlayerId(event.peer)
                    if playerId == -1 {
                        break
                    }

                    // mark as inactive and clear the peer pointer
                    Players[playerId].Active = false
                    Players[playerId].Peer = nil

                    // notify everyone that a player left
                    buffer: [2]u8;
                    buffer[0] = u8(Command.REMOVE);
                    buffer[1] = u8(playerId)

                    // create and send packet
                    packet: ^enet.Packet = enet.packet_create(raw_data(buffer[:]), 2, {.RELIABLE})
                    SendToAllBut(packet, -1)
            }
        }
    }

    // cleanup
    enet.host_destroy(server)
    enet.deinitialize()
}


package client

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import enet "vendor:Enet"
import "core:time"

FIELD_WIDTH :: 800
FIELD_HEIGHT :: 600
MoveSpeed : f32 : 200.0

PlayerColors: [MAX_PLAYERS]rl.Color

RunGame: bool = true

GameState :: enum {
    Connecting,
    Playing,
    Disconnecting,
    Disconnected
}

CurrentState := GameState.Disconnected

SetColors :: proc() {
    PlayerColors[0] = rl.WHITE
    PlayerColors[1] = rl.RED
    PlayerColors[2] = rl.GREEN
    PlayerColors[3] = rl.BLUE
    PlayerColors[4] = rl.PURPLE
    PlayerColors[5] = rl.GRAY
    PlayerColors[6] = rl.YELLOW
    PlayerColors[7] = rl.ORANGE
}

Quit :: proc() {
    RunGame = false
}

UpdateGame :: proc() {
    // Update the network gameplay system
    Update(rl.GetTime(), rl.GetFrameTime())

    switch CurrentState {
        case GameState.Disconnected:
            Quit()

        case GameState.Connecting:
            if Connected() && GetLocalPlayerId() >= 0 {
                CurrentState = GameState.Playing
            }

        case GameState.Disconnecting:
            if !Connected() {
                CurrentState = GameState.Disconnected
            }

        case GameState.Playing:
            if rl.WindowShouldClose() {
                Disconnect()
                CurrentState = GameState.Disconnecting
            } else if !Connected() {
                Connect("127.0.0.1")
                CurrentState = GameState.Connecting
            } else {
                // Handle player movement
                movement := rl.Vector2{0, 0}
                speed := MoveSpeed

                if rl.IsKeyDown(.UP) {
                    movement.y -= speed
                }
                if rl.IsKeyDown(.DOWN) {
                    movement.y += speed
                }
                if rl.IsKeyDown(.LEFT) {
                    movement.x -= speed
                }
                if rl.IsKeyDown(.RIGHT) {
                    movement.x += speed
                }

                // Update local player movement
                UpdateLocalPlayer(movement, rl.GetFrameTime())
            }
    }
}

DrawGame :: proc() {
    switch CurrentState {
        case GameState.Disconnected:
            rl.DrawText("Disconnected", 0, 20, 20, rl.RED)

        case GameState.Connecting:
            rl.DrawText("Connecting...", 0, 20, 20, rl.DARKGREEN)

        case GameState.Disconnecting:
            rl.DrawText("Disconnecting from server...", 0, 20, 20, rl.MAROON)

        case GameState.Playing:
            // Draw the local player's ID and color
            rl.DrawText(rl.TextFormat("Player %d", GetLocalPlayerId()), 0, 20, 20, PlayerColors[GetLocalPlayerId()])

            // Draw all active players
            for i in 0..<MAX_PLAYERS {
                pos := rl.Vector2{0, 0}
                if GetPlayerPos(auto_cast i, &pos) {
                    rl.DrawRectangle(i32(pos.x), i32(pos.y), PLAYER_SIZE, PLAYER_SIZE, PlayerColors[i])
                }
            }
    }
}

// main game client
main :: proc() {
    SetColors()

    // Initialize raylib
    rl.InitWindow(FIELD_WIDTH, FIELD_HEIGHT, "Client")
    rl.SetTargetFPS(60)

    // Connect to server
    Connect("127.0.0.1")
    CurrentState = GameState.Connecting

    for RunGame {
        UpdateGame()

        // Draw game screen
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        DrawGame()
        rl.DrawFPS(0, 0)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}

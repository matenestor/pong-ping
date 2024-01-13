package pongping

import "core:fmt"
import rl "vendor:raylib"

FPS :: 60
WIDTH :: 800
HEIGHT :: 450
BG :: 0x20
Vector2 :: struct {x, y: f32}

main :: proc() {
	pos: Vector2 = {WIDTH / 2, HEIGHT / 2}
	dir: Vector2 = {100, 0}
	velocity: f32 = 3
	dt: f32 = 0

	rl.InitWindow(WIDTH, HEIGHT, "Pong Ping game")
	rl.SetTargetFPS(FPS)
	rl.SetExitKey(rl.KeyboardKey.CAPS_LOCK)

    for !rl.WindowShouldClose() {
		dt = rl.GetFrameTime()

        rl.BeginDrawing()
            rl.ClearBackground({BG, BG, BG, 0xff})

			// getting input
			if      rl.IsKeyDown(rl.KeyboardKey.J) { dir.y += velocity }
			else if rl.IsKeyDown(rl.KeyboardKey.K) { dir.y -= velocity }

			// out of bounds checks
			if pos.x > WIDTH || pos.x < 0 { dir.x *= -1 }
			if pos.y > HEIGHT || pos.y < 0 { dir.y *= -1 }

			// rendering
			pos.x = pos.x + dir.x * dt
			pos.y = pos.y + dir.y * dt
			rl.DrawCircle(i32(pos.x), i32(pos.y), 10, rl.RAYWHITE)

        rl.EndDrawing()
    }
    rl.CloseWindow()
}

/*
72 h
74 j
75 k
76 l
265 ^
263 <
264 v
262 >
87 w
65 a
83 s
68 d
*/


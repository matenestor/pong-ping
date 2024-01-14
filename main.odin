package pongping

import "core:fmt"
import rl "vendor:raylib"

FPS :: 60
WIDTH :: 800
HEIGHT :: 450
BG :: 0x20

BAT_W :: 20
BAT_H :: 80
BAT_SPEED :: 100
BAT_OFFSET :: 0.05
BALL_SPEED_X :: 160
BALL_SPEED_Y :: 4
BALL_RADIUS :: 10

main :: proc() {
	// ball
	pos: rl.Vector2 = {WIDTH / 2, HEIGHT / 2}
	dir: rl.Vector2 = {100, 0}

	// bats
	bat_left := rl.Rectangle{
		WIDTH * BAT_OFFSET,
		HEIGHT * BAT_OFFSET,
		BAT_W,
		BAT_H
	}
	bat_right := rl.Rectangle{
		WIDTH * (1 - BAT_OFFSET) - BAT_W,
		HEIGHT * (1 - BAT_OFFSET) - BAT_H,
		BAT_W,
		BAT_H
	}
	dir_bat_left := rl.Vector2{0, BAT_SPEED}
	dir_bat_right := rl.Vector2{0, BAT_SPEED * -1}

	dt: f32 = 0
	cl, cr: rl.Color = rl.RAYWHITE, rl.RAYWHITE

	rl.InitWindow(WIDTH, HEIGHT, "Pong Ping game")
	rl.SetTargetFPS(FPS)
	rl.SetExitKey(rl.KeyboardKey.CAPS_LOCK)

    for !rl.WindowShouldClose() {
		dt = rl.GetFrameTime()

        rl.BeginDrawing()
            rl.ClearBackground({BG, BG, BG, 0xff})

			// getting input
			if      rl.IsKeyDown(rl.KeyboardKey.J) { dir.y += BALL_SPEED_Y }
			else if rl.IsKeyDown(rl.KeyboardKey.K) { dir.y -= BALL_SPEED_Y }

			// out of bounds checks
			if pos.x < 0 || pos.x > WIDTH { dir.x *= -1 }
			if pos.y < 0 || pos.y > HEIGHT { dir.y *= -1 }
			if bat_left.y  < 0 || bat_left.y  > (HEIGHT - BAT_H) { dir_bat_left.y *= -1 }
			if bat_right.y < 0 || bat_right.y > (HEIGHT - BAT_H) { dir_bat_right.y *= -1 }

			// ball and bat collision
			if rl.CheckCollisionCircleRec(pos, BALL_RADIUS, bat_left) {
				cl = rl.RED
			} else { cl = rl.RAYWHITE }
			if rl.CheckCollisionCircleRec(pos, BALL_RADIUS, bat_right) {
				cr = rl.RED
			} else { cr = rl.RAYWHITE }

			// rendering
			pos.x += dir.x * dt
			pos.y += dir.y * dt
			rl.DrawCircleV(pos, BALL_RADIUS, rl.RAYWHITE)

			bat_left.y += dir_bat_left.y * dt
			bat_right.y += dir_bat_right.y * dt
			rl.DrawRectangleRec(bat_left, cl)
			rl.DrawRectangleRec(bat_right, cr)
        rl.EndDrawing()
    }
    rl.CloseWindow()
}


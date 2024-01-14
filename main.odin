package pongping

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

FPS :: 60
WIDTH :: 800
HEIGHT :: 500
BG :: 0x20

BAT_W :: 20
BAT_H :: 80
BAT_SPEED :: 100
BAT_OFFSET :: 0.03
BALL_SPEED_X :: 160
BALL_SPEED_Y :: 4
BALL_RADIUS :: 10
BALL_TOP_SPEED :: 600

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
	lives, score: int = 3, 0
	str_lives, str_score := "", ""
	game_over := false

	rl.InitWindow(WIDTH, HEIGHT, "Pong Ping game")
	rl.SetTargetFPS(FPS)
	rl.SetExitKey(rl.KeyboardKey.CAPS_LOCK)

	for !rl.WindowShouldClose() {
		dt = rl.GetFrameTime()

		rl.BeginDrawing()
			rl.ClearBackground({BG, BG, BG, 0xff})

			if game_over {
				rl.DrawText("GAME OVER", WIDTH / 2 - 70, HEIGHT / 2 - 30, 24, rl.BLUE)
				rl.EndDrawing()
				continue
			}

			// getting input
			if rl.IsKeyDown(rl.KeyboardKey.J) || rl.IsKeyDown(rl.KeyboardKey.S) {
				dir.y += BALL_SPEED_Y
			}
			else if rl.IsKeyDown(rl.KeyboardKey.K) || rl.IsKeyDown(rl.KeyboardKey.W) {
				dir.y -= BALL_SPEED_Y
			}
			if abs(dir.y) > BALL_TOP_SPEED {
				sign := dir.y / abs(dir.y)
				dir.y = sign * BALL_TOP_SPEED
			}

			// out of bounds checks
			if pos.y - BALL_RADIUS < 0 || pos.y + BALL_RADIUS > HEIGHT { dir.y *= -1 }
			if bat_left.y  < 0 || bat_left.y  > (HEIGHT - BAT_H) { dir_bat_left.y *= -1 }
			if bat_right.y < 0 || bat_right.y > (HEIGHT - BAT_H) { dir_bat_right.y *= -1 }

			// ball and bat collision
			if rl.CheckCollisionCircleRec(pos, BALL_RADIUS, bat_left) \
			|| rl.CheckCollisionCircleRec(pos, BALL_RADIUS, bat_right) {
				// FIXME glitching when the collision is from top/bottom
				dir.x *= -1
				score += 100
			}

			// ball and the edge collision
			if pos.x < 0 || pos.x > WIDTH {
				if lives > 0 {
					lives -= 1
					pos = {WIDTH / 2, HEIGHT / 2}
					dir = {100, 0}
				}
				else {
					dir = {0, 0}
					dir_bat_left = {0, 0}
					dir_bat_right = {0, 0}
					game_over = true
				}
			}

			// rendering
			pos.x += dir.x * dt
			pos.y += dir.y * dt
			rl.DrawCircleV(pos, BALL_RADIUS, rl.RAYWHITE)

			bat_left.y += dir_bat_left.y * dt
			bat_right.y += dir_bat_right.y * dt
			rl.DrawRectangleRec(bat_left, rl.RAYWHITE)
			rl.DrawRectangleRec(bat_right, rl.RAYWHITE)

			// draw text
			str_lives = fmt.tprintf("lives: %d", lives)
			str_score = fmt.tprintf("score: %d", score)
			rl.DrawText(strings.unsafe_string_to_cstring(str_lives), 80, 20, 24, rl.BLUE)
			rl.DrawText(strings.unsafe_string_to_cstring(str_score), WIDTH / 2 - 50, 20, 24, rl.BLUE)
		rl.EndDrawing()
	}
	rl.CloseWindow()
}


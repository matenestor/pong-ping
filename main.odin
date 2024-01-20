package pongping

import "core:fmt"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

FPS :: 60
WIDTH :: 800
HEIGHT :: 500
BG :: 0x20

BAT_W :: 20
BAT_H :: 100
BAT_SPEED :: 100
BAT_OFFSET :: 0.03
BALL_SPEED_X :: 100
BALL_SPEED_Y :: 3
BALL_RADIUS :: 10
BALL_TOP_SPEED :: 600

sign :: #force_inline proc(num: f32) -> f32 {
	return num / abs(num)
}

get_random_sign :: proc() -> f32 {
	return rl.GetRandomValue(1, 2) == 1 ? 1 : -1
}

// FIXME refactor to procs
main :: proc() {
	rl.SetRandomSeed(u32(time.time_to_unix(time.now())))

	// FIXME create one entity struct for the ball and the bats
	// ball
	pos: rl.Vector2 = {WIDTH / 2, HEIGHT / 2}
	dir: rl.Vector2 = {
		get_random_sign() * BALL_SPEED_X,
		f32(rl.GetRandomValue(-BALL_SPEED_X, BALL_SPEED_X))
	}

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
	ball_speed_change: f32 = BALL_SPEED_Y
	momentum: f32 = -0.1  // not 0, because of the division in sign()
	str_lives, str_score := "", ""
	game_over := false

	rl.InitWindow(WIDTH, HEIGHT, "Pong Ping game")
	rl.SetTargetFPS(FPS)
	// Raylib uses Escape as a default exit key, but my Escape is remaped to
	// CapsLock and Raylib ignores it. So use Q.
	rl.SetExitKey(rl.KeyboardKey.Q)

	STRLEN_GAMEOVER := rl.MeasureText("GAME OVER", 32) / 2
	STRLEN_PLAYAGAIN := rl.MeasureText("Press Space to play again", 20) / 2
	STRLEN_SCORE := rl.MeasureText("Score: 0000", 24) / 2

	for !rl.WindowShouldClose() {
		dt = rl.GetFrameTime()

		rl.BeginDrawing()
			rl.ClearBackground({BG, BG, BG, 0xff})

			if game_over {
				rl.DrawText("GAME OVER", WIDTH / 2 - STRLEN_GAMEOVER, HEIGHT / 2 - 40, 32, rl.BLUE)
				str_score = fmt.tprintf("Score: %d", score)
				rl.DrawText(strings.unsafe_string_to_cstring(str_score), WIDTH / 2 - STRLEN_SCORE, HEIGHT / 2, 24, rl.BLUE)
				rl.DrawText("Press Space to play again", WIDTH / 2 - STRLEN_PLAYAGAIN, HEIGHT / 2 + 50, 20, rl.BLUE)

				if rl.IsKeyDown(rl.KeyboardKey.SPACE) {
					pos = {WIDTH / 2, HEIGHT / 2}
					dir = {BALL_SPEED_X, 0}
					dir_bat_left = {0, BAT_SPEED}
					dir_bat_right = {0, BAT_SPEED * -1}
					ball_speed_change = BALL_SPEED_Y
					lives = 3
					game_over = false
				}

				rl.EndDrawing()
				continue
			}

			// getting input
			if rl.IsKeyDown(rl.KeyboardKey.J) || rl.IsKeyDown(rl.KeyboardKey.S) {
				dir.y += ball_speed_change
			}
			else if rl.IsKeyDown(rl.KeyboardKey.K) || rl.IsKeyDown(rl.KeyboardKey.W) {
				dir.y -= ball_speed_change
			}
			if abs(dir.y) > BALL_TOP_SPEED {
				dir.y = sign(dir.y) * BALL_TOP_SPEED
			}

			// out of bounds checks on y-axis for the ball and the bats
			if pos.y - BALL_RADIUS < 0 || pos.y + BALL_RADIUS > HEIGHT { dir.y *= -1 }
			if bat_left.y  < 0 || bat_left.y  > (HEIGHT - BAT_H) { dir_bat_left.y *= -1 }
			if bat_right.y < 0 || bat_right.y > (HEIGHT - BAT_H) { dir_bat_right.y *= -1 }

			// ball and bat collision
			if rl.CheckCollisionCircleRec(pos, BALL_RADIUS, bat_right) {
				if pos.x < bat_right.x {
					score += 100

					// increase the ball speed every second hit
					if score % 200 == 0 {
						dir.x += 20
						ball_speed_change += 1
					}

					dir.x *= -1
					momentum = BALL_SPEED_X
					// side collision correction
					pos.x = bat_right.x - BALL_RADIUS - 1

					if dir_bat_right.y < 300 && rl.GetRandomValue(0, 2) == 0 {
						dir_bat_right.y *= 1.1
					}

					// NOTE: It is also possible to calculate the corrected postion like
					// this, maybe it's more intuitive, but it requires more operations:
					//   pos.x -= BALL_RADIUS - abs(pos.x - bat_right.x) + 1
					//
					// The same with pos.y:
					//   top: pos.y -= BALL_RADIUS - abs(pos.y - bat_right.y) + 1
					//   btm: pos.y += BALL_RADIUS - abs(pos.y - (bat_right.y + bat_right.height)) + 1
				}
				else {
					dir.y *= -1

					if pos.y < bat_right.y {
						// top collision correction
						pos.y = bat_right.y - BALL_RADIUS - 1
					}
					else {
						// bottom collision correction
						pos.y = bat_right.y + bat_right.height + BALL_RADIUS + 1
					}
				}
			}
			else if rl.CheckCollisionCircleRec(pos, BALL_RADIUS, bat_left) {
				if pos.x > bat_left.x + bat_left.width {
					score += 100

					// increase the ball speed every second hit
					if score % 200 == 0 {
						dir.x -= 20
						ball_speed_change += 1
					}

					dir.x *= -1
					momentum = BALL_SPEED_X
					pos.x = bat_left.x + bat_left.width + BALL_RADIUS + 1

					if dir_bat_left.y < 300 && rl.GetRandomValue(0, 2) == 0 {
						dir_bat_left.y *= 1.1
					}
				}
				else {
					dir.y *= -1

					if pos.y < bat_left.y {
						pos.y = bat_left.y - BALL_RADIUS - 1
					}
					else {
						pos.y = bat_left.y + bat_left.height + BALL_RADIUS + 1
					}
				}
			}

			// ball and the edge collision
			if pos.x < 0 || pos.x > WIDTH {
				if lives > 0 {
					lives -= 1
					pos = {WIDTH / 2, HEIGHT / 2}
					dir = {
						get_random_sign() * BALL_SPEED_X,
						f32(rl.GetRandomValue(-BALL_SPEED_X, BALL_SPEED_X))
					}
					ball_speed_change = BALL_SPEED_Y
					momentum = -0.1
				}
				else {
					dir = {0, 0}
					dir_bat_left = {0, 0}
					dir_bat_right = {0, 0}
					game_over = true
				}
			}


			// update physics
			if momentum > 0 do momentum -= 2 * BALL_SPEED_X * dt
			pos.x += (dir.x + sign(dir.x) * momentum) * dt
			pos.y += dir.y * dt
			bat_left.y += dir_bat_left.y * dt
			bat_right.y += dir_bat_right.y * dt

			// rendering
			rl.DrawCircleV(pos, BALL_RADIUS, rl.RAYWHITE)
			rl.DrawRectangleRec(bat_left, rl.RAYWHITE)
			rl.DrawRectangleRec(bat_right, rl.RAYWHITE)

			// draw text
			str_lives = fmt.tprintf("Lives: %d", lives)
			str_score = fmt.tprintf("Score: %d", score)
			rl.DrawText(strings.unsafe_string_to_cstring(str_lives), WIDTH * 0.1, 20, 24, rl.BLUE)
			rl.DrawText(strings.unsafe_string_to_cstring(str_score), WIDTH / 2 - STRLEN_SCORE, 20, 24, rl.BLUE)
		rl.EndDrawing()
	}
	rl.CloseWindow()
}


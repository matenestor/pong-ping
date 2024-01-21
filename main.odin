package pongping

// TODO bounce bats on hit

import "core:fmt"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

FPS :: 60
WIDTH :: 800
HEIGHT :: 500
BG :: 0x20

BAT_WIDTH :: 20
BAT_HALF :: BAT_WIDTH / 2
BAT_HEIGHT :: 100
BAT_SPEED :: 100
BAT_OFFSET :: 0.03
BALL_SPEED_X :: 100
BALL_SPEED_Y :: 3
BALL_RADIUS :: 10
BALL_TOP_SPEED :: 600

Ball :: struct {
	pos: rl.Vector2,
	dir: rl.Vector2,
	turning_speed: f32,
	momentum: f32,
}

BatType :: enum { LEFT, RIGHT }

Bat :: struct {
	pos: rl.Rectangle,
	dir: rl.Vector2,
}

sign :: #force_inline proc(num: f32) -> f32 {
	return num / abs(num)
}

get_random_sign :: proc() -> f32 {
	return rl.GetRandomValue(1, 2) == 1 ? 1 : -1
}

init_ball :: proc() -> Ball {
	return Ball{
		rl.Vector2{WIDTH / 2, HEIGHT / 2},
		rl.Vector2{
			get_random_sign() * BALL_SPEED_X,
			f32(rl.GetRandomValue(-BALL_SPEED_X, BALL_SPEED_X)),
		},
		BALL_SPEED_Y,
		-1,  // not 0, because of the division in sign()
	}
}

init_bat :: proc(bat_type: BatType) -> Bat {
	x, y, dir: f32 = 0, 0, 0

	if bat_type == .LEFT {
		x = WIDTH * BAT_OFFSET
		y = HEIGHT * BAT_OFFSET
		dir = 1
	}
	else if bat_type == .RIGHT {
		x = WIDTH * (1 - BAT_OFFSET) - BAT_WIDTH
		y = HEIGHT * (1 - BAT_OFFSET) - BAT_HEIGHT
		dir = -1
	}

	return Bat{
		rl.Rectangle{x, y, BAT_WIDTH, BAT_HEIGHT},
		rl.Vector2{0, BAT_SPEED * dir}
	}
}

is_ball_and_wall_colliding :: proc(ball: ^Ball) -> bool {
	return ball^.pos.y - BALL_RADIUS < 0 || ball^.pos.y + BALL_RADIUS > HEIGHT
}

is_ball_and_edge_colliding :: proc(ball: ^Ball) -> bool {
	return ball^.pos.x < 0 || ball^.pos.x > WIDTH
}

is_bat_and_wall_colliding :: proc(bat: ^Bat) -> bool {
	return bat^.pos.y < 0 || bat^.pos.y > (HEIGHT - BAT_HEIGHT)
}

is_safe_collision :: proc(ball: ^Ball, bat_edge: f32) -> bool {
	return abs(ball^.pos.x - WIDTH / 2) < abs(bat_edge - WIDTH / 2)
}

ball_and_bat_collision :: proc(ball: ^Ball, bat: ^Bat) -> bool {
	// NOTE: It is also possible to calculate the corrected postion like
	// this, maybe it's more intuitive, but it requires more operations:
	//   ball^.pos.x -= BALL_RADIUS - abs(ball^.pos.x - bat^.pos.x) + 1
	//
	// The same with pos.y on a bad collision:
	//   top: ball^.pos.y -= BALL_RADIUS - abs(ball^.pos.y - bat^.pos.y) + 1
	//   btm: ball^.pos.y += BALL_RADIUS - abs(ball^.pos.y - (bat^.pos.y + bat^.pos.height)) + 1

	// -1 because the bat's edge is towards the ball's direction
	sign := sign(ball^.dir.x) * -1

	bat_middle := bat^.pos.x + BAT_HALF
	bat_edge := bat_middle + sign * BAT_HALF

	if is_safe_collision(ball, bat_edge) {
		ball^.dir.x *= -1
		ball^.momentum = BALL_SPEED_X

		// side collision correction (-1 to avoid clipping)
		ball^.pos.x = bat_middle + sign * (BAT_HALF + BALL_RADIUS) - 1

		// 33 % chance to increase the bat speed
		if bat^.dir.y < 300 && rl.GetRandomValue(0, 2) == 0 {
			bat^.dir.y *= 1.1
		}

		return true
	}
	else {
		ball^.dir.y *= -1

		if ball^.pos.y < bat^.pos.y {
			// top collision correction
			ball^.pos.y = bat^.pos.y - BALL_RADIUS - 1
		}
		else {
			// bottom collision correction
			ball^.pos.y = bat^.pos.y + bat^.pos.height + BALL_RADIUS + 1
		}

		return false
	}
}

stop_movement :: proc(element: ^$T) {
	element^.dir.x = 0
	element^.dir.y = 0
}

main :: proc() {
	rl.SetRandomSeed(u32(time.time_to_unix(time.now())))

	ball := init_ball()
	bat_left := init_bat(BatType.LEFT)
	bat_right := init_bat(BatType.RIGHT)

	dt: f32 = 0
	lives, score: int = 3, 0
	str_lives, str_score := "", ""
	game_over := false
	collided_ok := false

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
					lives = 3
					game_over = false

					ball = init_ball()
					bat_left = init_bat(BatType.LEFT)
					bat_right = init_bat(BatType.RIGHT)
				}

				rl.EndDrawing()
				continue
			}

			// getting input
			if rl.IsKeyDown(rl.KeyboardKey.J) || rl.IsKeyDown(rl.KeyboardKey.S) {
				ball.dir.y += ball.turning_speed
			}
			else if rl.IsKeyDown(rl.KeyboardKey.K) || rl.IsKeyDown(rl.KeyboardKey.W) {
				ball.dir.y -= ball.turning_speed
			}
			if abs(ball.dir.y) > BALL_TOP_SPEED {
				// clamp the Y speed
				ball.dir.y = sign(ball.dir.y) * BALL_TOP_SPEED
			}

			// out of bounds checks on y-axis for the ball and the bats
			if is_ball_and_wall_colliding(&ball)     do ball.dir.y *= -1
			if is_bat_and_wall_colliding(&bat_left)  do bat_left.dir.y *= -1
			if is_bat_and_wall_colliding(&bat_right) do bat_right.dir.y *= -1

			// ball and bat collision
			collided_ok = false
			if rl.CheckCollisionCircleRec(ball.pos, BALL_RADIUS, bat_right.pos) {
				collided_ok = ball_and_bat_collision(&ball, &bat_right)
			}
			else if rl.CheckCollisionCircleRec(ball.pos, BALL_RADIUS, bat_left.pos) {
				collided_ok = ball_and_bat_collision(&ball, &bat_left)
			}
			if collided_ok {
				score += 100

				// increase the ball speed every second hit
				if score % 200 == 0 {
					ball.dir.x += sign(ball.dir.x) * 20
					ball.turning_speed += 1
				}
			}

			// ball and the edge collision
			if is_ball_and_edge_colliding(&ball) {
				if lives > 0 {
					lives -= 1
					ball = init_ball()
				}
				else {
					game_over = true
					stop_movement(&ball)
					stop_movement(&bat_left)
					stop_movement(&bat_right)
				}
			}

			// update physics
			if ball.momentum > 0 do ball.momentum -= 2 * BALL_SPEED_X * dt
			ball.pos.x += (ball.dir.x + sign(ball.dir.x) * ball.momentum) * dt
			ball.pos.y += ball.dir.y * dt
			bat_left.pos.y += bat_left.dir.y * dt
			bat_right.pos.y += bat_right.dir.y * dt

			// rendering
			rl.DrawCircleV(ball.pos, BALL_RADIUS, rl.RAYWHITE)
			rl.DrawRectangleRec(bat_left.pos, rl.RAYWHITE)
			rl.DrawRectangleRec(bat_right.pos, rl.RAYWHITE)

			// draw text
			str_lives = fmt.tprintf("Lives: %d", lives)
			str_score = fmt.tprintf("Score: %d", score)
			rl.DrawText(strings.unsafe_string_to_cstring(str_lives), WIDTH * 0.1, 20, 24, rl.BLUE)
			rl.DrawText(strings.unsafe_string_to_cstring(str_score), WIDTH / 2 - STRLEN_SCORE, 20, 24, rl.BLUE)
		rl.EndDrawing()
	}
	rl.CloseWindow()
}


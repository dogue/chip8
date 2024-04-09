package main

import (
	// "chip8/core"
	"chip8/core"
	"log"

	"github.com/gen2brain/raylib-go/raylib"
)

func main() {
	rl.InitWindow(1024, 512, "CHIP-8")
	defer rl.CloseWindow()

	display := make(chan [32][64]bool, 100)

	rl.SetTargetFPS(60)

	core := core.New(display)
	core.Load("ibm-logo.ch8")
	go core.Run()

	for !rl.WindowShouldClose() {
		select {
		case pixels := <-display:
			log.Println("GOT PIXEL DATA")
			rl.BeginDrawing()

			for y, rows := range pixels {
				for x, col := range rows {
					draw(x, y, col)
				}
			}

			rl.EndDrawing()

		default:
			continue
		}
	}
}

func draw(x, y int, on bool) {
	var color rl.Color
	if on {
		color = rl.White
	} else {
		color = rl.Black
	}

	for i := range 16 {
		for j := range 16 {
			px := x*16 + i
			py := y*16 + j
			rl.DrawPixel(int32(px), int32(py), color)
		}
	}
}

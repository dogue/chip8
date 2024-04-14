package chip8

import "core:fmt"
import "core:os"
import "core:sync/chan"
import "core:thread"
import "core:time"
import "emu"
import rl "vendor:raylib"

main :: proc() {
    prog, _ := os.read_entire_file("ibm-logo2.ch8")
    core := emu.create_init(prog)
    pixels := core.display
    core_t := thread.create_and_start_with_data(core, emu.run, context)

    rl.InitWindow(64 * 16, 32 * 16, "CHIP-8")
    rl.SetTargetFPS(60)
    rl.SetExitKey(.Q)
    defer rl.CloseWindow()

    pix_data: emu.PixBuf
    debug_grid := false

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()

        if chan.can_recv(pixels) {
            pix_data, _ = chan.recv(pixels)
        }

        for rows, i in pix_data {
            for on, j in rows {
                color := on ? rl.WHITE : rl.BLACK
                rl.DrawRectangle(i32(j) * 16, i32(i) * 16, 16, 16, color)
            }
        }

        if debug_grid {
            for i in 0 ..< 32 {
                rl.DrawLine(0, i32(i * 16), 64 * 16, i32(i * 16), rl.DARKGRAY)
            }

            for i in 0 ..< 64 {
                rl.DrawLine(i32(i * 16), 0, i32(i * 16), 32 * 16, rl.DARKGRAY)
            }
        }

        rl.EndDrawing()

        if rl.IsKeyPressed(.D) {
            debug_grid = !debug_grid
        }
    }

    core.should_exit = true
    thread.join(core_t)
}

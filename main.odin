package chip8

import "chip"
import "core:fmt"
import "core:log"
import "core:os"
import "core:sync/chan"
import "core:thread"
import "core:time"
import rl "vendor:raylib"

main :: proc() {
    context.logger = log.create_console_logger()

    prog, _ := os.read_entire_file("ibm-logo2.ch8")
    core := chip.create_init(prog)
    pixels := chip.get_out_chan(core)
    log.debug("initializing emulator thread")
    emu := thread.create_and_start_with_data(core, chip.run, context)

    if thread.is_done(emu) {
        log.fatal("emulator thread exited early")
    }

    rl.InitWindow(64 * 16, 32 * 16, "CHIP-8")
    rl.SetTargetFPS(60)
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)
    rl.EndDrawing()
    defer rl.CloseWindow()

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        pix_data, _ := chan.recv(pixels)
        log.debug("got pixel data")

        for rows, i in pix_data {
            for on, j in rows {
                color := on ? rl.WHITE : rl.BLACK
                rl.DrawRectangle(i32(j * 16), i32(i * 16), 16, 16, color)
            }
        }
        rl.EndDrawing()
    }
}

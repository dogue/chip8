package chip8

import "core:fmt"
import "core:os"
import "core:sync/chan"
import "core:thread"
import "core:time"
import "emu"
import pb "pixbuffer"
import "pixbuffer/draw"

main :: proc() {
    win, err := pb.init_window({
        title = "CHIP-8",
        width = 64 * 16,
        height = 32 * 16,
        pos = {pb.CENTERED, pb.CENTERED},
        flags = {},
    })
    if err != .None {
        fmt.panicf("Failed to create window: %v", err)
    }

    prog, _ := os.read_entire_file("ibm-logo2.ch8")
    core := emu.create(prog)
    pixels := core.display
    core_t := thread.create_and_start_with_data(core, emu.run, context)
    pix_data: emu.PixBuf
    debug_grid := false

    win_should_close := false
    for !win_should_close {

        if chan.can_recv(pixels) {
            pix_data, _ = chan.recv(pixels)
        }

        for rows, i in pix_data {
            for on, j in rows {
                color := on ? pb.WHITE : pb.BLACK
                draw.rect(win, j * 16, i * 16, 16, 16, color)
            }
        }

        if debug_grid {
            for i in 0 ..< 32 {
                draw.line(win, 0, i * 16, 64 * 16, i * 16, pb.DARK_GRAY)
            }

            for i in 0 ..< 64 {
                draw.line(win, i * 16, 0, i * 16, 32 * 16, pb.DARK_GRAY)
            }
        }

        evt: pb.Event
        pb.poll_event(&evt)

        #partial switch evt.type {
        case .QUIT: win_should_close = true
        case .KEYDOWN:
            #partial switch evt.key.keysym.sym {
            case .ESCAPE: win_should_close = true
            case .D: debug_grid = !debug_grid
            }
        }

        pb.render(win)
    }

    core.should_exit = true
    thread.join(core_t)
}

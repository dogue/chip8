//+private
package chip

import "core:log"
import "core:sync/chan"

Opcode :: struct {
    A:    u8,
    B:    u8,
    C:    u8,
    D:    u8,
    full: u16,
}

fetch :: proc(core: ^Core) -> Opcode {
    log.debug("fetching next instruction")
    log.debugf("PC: %4X", core.pc)
    if core.pc >= 4096 {
        {}
    }

    high := core.memory[core.pc]
    core.pc += 1
    low := core.memory[core.pc]
    core.pc += 1

    op := Opcode {
        A    = high & 0xF0 >> 4,
        B    = high & 0x0F,
        C    = low & 0xF0 >> 4,
        D    = low & 0x0F,
        full = (u16(high) << 8) | u16(low),
    }

    log.debugf("fetched opcode %4X", op.full)
    return op
}

decode :: proc(core: ^Core, op: Opcode) {
    log.debugf("decoding opcode %2X", op.A)
    switch op.A {

    case 0x0:
        if op.C == 0xE && op.D == 0 {
            log.debug("clearing screen")
            clear_display(core)
        }

        if op.C == 0xE && op.D == 0xE {
            // ret
        }

    case 0x1:
        addr := op.full & 0xFFF
        log.debugf("jmp to %3X", addr)
        core.pc = addr

    case 0x6:
        val := op.full & 0xFF
        core.var[op.B] = u8(val)

    case 0x7:
        val := op.full & 0xFF
        core.var[op.B] += u8(val)

    case 0xD:
        draw(core, op.B, op.C, op.D)

    }
}

send_pixels :: proc(core: ^Core) {
    log.debug("sending pixel data to raylib")
    ok := chan.send(core.display, core.pixels)
    if !ok {
        log.fatal("could not send pixel data over channel")
    }
}

clear_display :: proc(core: ^Core) {
    for rows, i in core.pixels {
        for _, j in rows {
            core.pixels[i][j] = false
        }
    }

    send_pixels(core)
}

draw :: proc(core: ^Core, x, y, size: u8) {
    log.debugf("drawing at %d, %d", x, y)
    x := x
    y := y
    core.var[0xF] = 0

    log.debugf("sprite size: %d", size)
    for n in 0 ..< size {
        log.debugf("n: %d", n)
        curr_x := x
        data := core.memory[core.index + u16(n)] >> 4
        log.debugf("data: %X", data)

        for i := 7; i >= 0; i -= 1 {
            log.debugf("i: %d", i)
            if curr_x >= 64 {
                break
            }

            bit := data & (1 << u8(i))
            if bit > 0 {
                core.pixels[y][curr_x] = !core.pixels[y][curr_x]
                if core.pixels[y][curr_x] == false {
                    core.var[0xF] = 1
                }
            }
            curr_x += 1
        }
        y += 1
        send_pixels(core)
    }

}

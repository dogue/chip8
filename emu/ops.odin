#+ private
package chip

import "core:sync/chan"

// 4x4bit opcodes, A = $F000, B = $0F00, C = $00F0, D = $000F
Opcode :: bit_field u16 {
    D: u8 | 4,
    C: u8 | 4,
    B: u8 | 4,
    A: u8 | 4,
}

fetch :: proc(core: ^Core) -> Opcode {
    if core.pc >= 4096 {
        {}
    }

    high := core.memory[core.pc]
    core.pc += 1
    low := core.memory[core.pc]
    core.pc += 1

    return Opcode(u16(high) << 8 | u16(low))
}

decode :: proc(core: ^Core, op: Opcode) {
    switch op.A {

    case 0x0:
        if op.C == 0xE && op.D == 0 {
            clear_display(core)
        }

        if op.C == 0xE && op.D == 0xE {
            // ret
        }

    case 0x1:
        addr := u16(op) & 0xFFF
        core.pc = addr

    case 0x6:
        val := u16(op) & 0xFF
        core.var[op.B] = u8(val)

    case 0x7:
        val := u16(op) & 0xFF
        core.var[op.B] += u8(val)

    case 0xA:
        val := u16(op) & 0xFFF
        core.index = val

    case 0xD:
        draw(core, op.B, op.C, op.D)

    }
}

send_pixels :: proc(core: ^Core) {
    ok := chan.send(core.display, core.pixels)
    if !ok {
        panic("failed to send pixel buffer to render thread")
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
    x := core.var[x] & 63
    y := core.var[y] & 31
    core.var[0xF] = 0

    for n in 0 ..< size {
        curr_x := x
        data := core.memory[core.index + u16(n)]

        for i := 7; i >= 0; i -= 1 {
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
    }

    send_pixels(core)
}

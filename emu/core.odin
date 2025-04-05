package chip

import "core:log"
import "core:sync/chan"
import "core:time"

PixBuf :: distinct [32][64]bool

Instruction :: bit_field u16 {
	a: u8 | 4,
	b: u8 | 4,
	c: u8 | 4,
	d: u8 | 4,
}

Core :: struct {
    memory:      [4096]u8,
    pc:          u16,
    index:       u16,
    stack:       u16,
    delay:       u8,
    sound:       u8,
    var:         [16]u8,
    pixels:      PixBuf,
    display:     chan.Chan(PixBuf),
    should_exit: bool,
}

create :: proc {
    create_empty,
    create_init,
}

create_empty :: proc() -> ^Core {
    return new(Core)
}

create_init :: proc(program: []byte) -> ^Core {
    core := create()
    init(core, program)
    return core
}

destroy :: proc(core: ^Core) {
    free(core)
}

init :: proc(core: ^Core, program: []byte) {
    load_font(core)

    for b, i in program {
        idx := 0x200 + i
        core.memory[idx] = b
    }

    channel, err := chan.create_buffered(
        chan.Chan(PixBuf),
        16,
        context.allocator,
    )
    if err != nil {
        log.fatalf("failed to create pixel buffer channel: %v", err)
    }

    core.display = channel

    core.pc = 0x200
}

run :: proc(core: rawptr) {
    core := cast(^Core)core

    for core.pc < 4096 {
        if core.should_exit {
            return
        }
        opcode := fetch(core)
        decode(core, opcode)
    }
}

@(private)
load_font :: proc(core: ^Core) {
    for char, i in Font {
        core.memory[i] = char
    }
}

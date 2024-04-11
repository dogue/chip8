package chip

import "core:log"
import "core:sync/chan"
import "core:time"

PixBuf :: distinct [32][64]bool

Core :: struct {
    memory:  [4096]u8,
    pc:      u16,
    index:   u16,
    stack:   u16,
    delay:   u8,
    sound:   u8,
    var:     [16]u8,
    pixels:  PixBuf,
    display: chan.Chan(PixBuf),
}

create :: proc() -> ^Core {
    log.debug("creating new core")
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
    log.debug("loading font data")
    load_font(core)

    log.debug("loading program data")
    for b, i in program {
        idx := 0x200 + i
        core.memory[idx] = b
    }

    log.debug("initializing pixel buffer channel")
    channel, err := chan.create_unbuffered(
        chan.Chan(PixBuf),
        context.allocator,
    )
    if err != nil {
        log.fatalf("failed to create pixel buffer channel: %v", err)
    }

    core.display = channel

    core.pc = 0x200
}

run :: proc(core: rawptr) {
    log.debug("casting rawptr to ^Core")
    core := cast(^Core)core

    log.debug("entering main emulator loop")
    for core.pc < 4096 {
        opcode := fetch(core)
        time.sleep(time.Second)
        decode(core, opcode)
        time.sleep(time.Second)
    }
}

get_out_chan :: proc(core: ^Core) -> chan.Chan(PixBuf) {
    log.debug("returning pointer to pixel buffer channel")
    return core.display
}

@(private)
load_font :: proc(core: ^Core) {
    for char, i in Font {
        core.memory[i] = char
    }
}

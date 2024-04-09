package core

import (
	"log"
	"os"
	"time"
)

type Core struct {
	Memory     [4096]uint8
	PC         uint16
	I          uint16
	Stack      uint16
	Delay      uint8
	Sound      uint8
	V          [16]uint8
	Display    [32][64]bool
	OutputChan chan [32][64]bool
}

func New(output chan [32][64]bool) *Core {
	core := &Core{OutputChan: output}
	core.init()
	return core
}

func (core *Core) Load(filename string) {
	data, err := os.ReadFile(filename)
	if err != nil {
		panic(err)
	}

	log.Println("loading file data into memory")
	i := 0x200
	for _, byte := range data {
		core.Memory[i] = byte
		i++
	}
}

func (core *Core) Run() {
	log.Println("entering main run loop")
	for {
		opcode := core.Fetch()
		log.Printf("fetched: %x", opcode)
		core.Decode(opcode)
		time.Sleep(time.Second)
	}
}

func (core *Core) init() {
	// load font
	for i, b := range Font {
		core.Memory[i] = b
	}

	core.PC = 0x200
}

func (core *Core) Fetch() uint16 {
	if core.PC >= 4096 {
		return 0
	}

	first := core.Memory[core.PC]
	core.PC++
	second := core.Memory[core.PC]
	core.PC++

	return (uint16(first) << 8) | uint16(second)
}

func (core *Core) Decode(opcode uint16) {
	nibble := [4]uint16{
		(opcode & 0xF000) >> 12,
		(opcode & 0x0F00) >> 8,
		(opcode & 0x00F0) >> 4,
		(opcode & 0x000F),
	}

	switch nibble[0] {

	case 0x0:
		switch nibble[3] {
		case 0x0:
			for i := range core.Display {
				for j := range i {
					core.Display[i][j] = false
				}
			}
			core.OutputChan <- core.Display
		case 0xE:
			// RET
		}

	case 0x1:
		// JMP
		core.PC = (nibble[1] << 8) | (nibble[2] << 4) | nibble[3]

	case 0x6:
		core.V[nibble[1]] = uint8((nibble[2] << 4) | nibble[3])

	case 0x7:
		core.V[nibble[1]] += uint8((nibble[2] << 4) | nibble[3])

	case 0xA:
		core.I = (nibble[1] << 8) | (nibble[2] << 4) | nibble[3]

	case 0xD:
		log.Println("display opcode")
		// time.Sleep(time.Second)
		x := core.V[nibble[1]] & 63
		y := core.V[nibble[2]] & 31
		log.Printf("x, y: %d, %d", x, y)
		// time.Sleep(time.Second)
		core.V[0xF] = 0
		for n := range nibble[3] {
			cx := x
			log.Printf("n (%d) in range %d", n, nibble[3])
			// time.Sleep(time.Second)
			data := core.Memory[core.I+n]
			log.Printf("data: %d", data)
			// time.Sleep(time.Second)
			for b := 7; b >= 0; b-- {
				if cx >= 64 {
					break
				}
				bit := data & (1 << b)
				log.Printf("bit (%d) is: %d", b, bit)
				// time.Sleep(time.Second)
				if bit > 0 {
					log.Printf("x, y: %d, %d", x, y)
					core.Display[y][cx] = true
				} else {
					log.Println("pixel off")
					// time.Sleep(time.Second)
					core.Display[y][cx] = false
				}
				cx++
				core.OutputChan <- core.Display
				// time.Sleep(time.Second)
			}
			y++
		}
		log.Println("sending pixel data over channel")
		// time.Sleep(time.Second)
		core.OutputChan <- core.Display
	}
}

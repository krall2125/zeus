package zeus

import "core:os"
import "core:strings"
import "core:fmt"

ZeusStandard :: enum {
	Z1, Z2, Z3
}

read_file :: proc(filepath: string) -> string {
	data, ok := os.read_entire_file(filepath, context.allocator)

	if !ok {
		return ""
	}

	return string(data)
}

ZeusBytecode :: enum {
	INC, DEC, PUTN, PUTC,
	MULT, DIV, ZERO, SAVE, RESTORE,
	PARF, BLOCKOPEN, BLOCKCLOSE, JUMP_FALSE, JUMP, END
}

block_stuff :: proc(program: string, i: int, bytecode: ^[dynamic]int, positions: ^[dynamic]int, regular_jump: bool) {
	if len(positions) == 0 {
		fmt.eprintf("Error: No corresponding jump for end of block.\n")
		return
	}

	pos := pop(positions)

	if bytecode^[pos - 1] != int(ZeusBytecode.JUMP_FALSE) && (regular_jump && bytecode^[pos - 1] != int(ZeusBytecode.JUMP)) {
		fmt.eprintf("Error: No corresponding jump for end of block.\n")
		return
	}

	bytecode^[pos] = len(bytecode)
}

actual_compile :: proc(program: string, i: int, bytecode: ^[dynamic]int, positions: ^[dynamic]int) {
	switch program[i] {
		case '+': append(bytecode, int(ZeusBytecode.INC))
		case '-': append(bytecode, int(ZeusBytecode.DEC))
		case '.': append(bytecode, int(ZeusBytecode.PUTN))
		case ':': append(bytecode, int(ZeusBytecode.PUTC))
		case '*': append(bytecode, int(ZeusBytecode.MULT))
		case '/': append(bytecode, int(ZeusBytecode.DIV))
		case '0': append(bytecode, int(ZeusBytecode.ZERO))
		case '{': append(bytecode, int(ZeusBytecode.SAVE))
		case '}': append(bytecode, int(ZeusBytecode.RESTORE))
		case 'p': append(bytecode, int(ZeusBytecode.PARF))
		case '?':
			block_stuff(program, i, bytecode, positions, false)

			append(bytecode, int(ZeusBytecode.JUMP_FALSE))
			append(positions, len(bytecode))
			append(bytecode, i + 2)
		case '!':
			block_stuff(program, i, bytecode, positions, false)

			append(bytecode, int(ZeusBytecode.JUMP))
			append(positions, len(bytecode))
			append(bytecode, i + 2)
		case ')':
			block_stuff(program, i, bytecode, positions, true)

			append(bytecode, int(ZeusBytecode.END))
	}
}

compile_zeus :: proc(program: string) -> [dynamic]int {
	bytecode := make([dynamic]int)

	doing_block_stuff := false

	positions := make([dynamic]int)
	defer delete(positions)

	for i in 0..<len(program) {
		actual_compile(program, i, &bytecode, &positions)
	}

	return bytecode
}

main :: proc() {
	std := ZeusStandard.Z2
	for arg in os.args[1:] {
		if arg[0] == '-' {
			parse_cmd_args(&std, arg[1:])
		}

		contents := read_file(arg)

		if contents == "" {
			continue
		}
	}
}

parse_cmd_args :: proc(standard: ^ZeusStandard, arg: string) {
	switch arg {
		case "z1": standard^ = ZeusStandard.Z1
		case "z2": standard^ = ZeusStandard.Z2
		case "z3": standard^ = ZeusStandard.Z3
		case:
	}
}

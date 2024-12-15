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
	PARF, BLOCKOPEN, BLOCKCLOSE, JUMP_FALSE, JUMP,
}

compile_zeus :: proc(program: string) -> [dynamic]ZeusBytecode {
	storage := 0
	values := make([dynamic]int)
	defer delete(values)

	bytecode := make([dynamic]ZeusBytecode)

	doing_block_stuff := false

	for token in program {
		switch token {
			case '+': append(&bytecode, ZeusBytecode.INC)
			case '-': append(&bytecode, ZeusBytecode.DEC)
			case '.': append(&bytecode, ZeusBytecode.PUTN)
			case ':': append(&bytecode, ZeusBytecode.PUTC)
			case '*': append(&bytecode, ZeusBytecode.MULT)
			case '/': append(&bytecode, ZeusBytecode.DIV)
			case '0': append(&bytecode, ZeusBytecode.ZERO)
			case '{': append(&bytecode, ZeusBytecode.SAVE)
			case '}': append(&bytecode, ZeusBytecode.RESTORE)
			case 'p': append(&bytecode, ZeusBytecode.PARF)
			case '?': append(&bytecode, ZeusBytecode.JUMP_FALSE)
		}
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

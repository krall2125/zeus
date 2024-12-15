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
	PARF, BLOCKOPEN, BLOCKCLOSE
}

compile_zeus :: proc(program: string) -> [dynamic]ZeusBytecode {
	storage := 0
	values := make([dynamic]int)
	defer delete(values)

	bytecode := make([dynamic]ZeusBytecode)

	for token in program {
		switch token {
			case '+': storage += 1
			case '-': storage -= 1
			case '.': fmt.printf("%d", storage)
			case ':': fmt.printf("%c", storage)
			case '*': storage *= 2
			case '/': storage /= 2
			case '0': storage = 0
			case '{': append(&values, storage)
			case '}': storage = pop(&values)
			case 'p': fmt.printf("meow :3\n")
		}
	}
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

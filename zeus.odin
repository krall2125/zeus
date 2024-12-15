package zeus

import "core:os"
import "core:strings"
import "core:fmt"

ZeusStandard :: enum {
	Z1, Z2
}

read_file :: proc(filepath: string) -> string {
	data, ok := os.read_entire_file(filepath, context.allocator)

	if !ok {
		return ""
	}

	return string(data)
}

execute_z1 :: proc(program: string) {
	storage := 0

	for token in program {
		switch token {
			case '+': storage += 1
			case '-': storage -= 1
			case '.': fmt.printf("%d", storage)
			case ':': fmt.printf("%c", storage)
		}
	}
}

execute_z2 :: proc(program: string) {
	storage := 0
	values := make([dynamic]int)
	defer delete(values)

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

		switch std {
			case ZeusStandard.Z1: execute_z1(contents)
			case ZeusStandard.Z2: execute_z2(contents)
		}
	}
}

parse_cmd_args :: proc(standard: ^ZeusStandard, arg: string) {
	switch arg {
		case "z1": standard^ = ZeusStandard.Z1
		case "z2": standard^ = ZeusStandard.Z2
		case:
	}
}

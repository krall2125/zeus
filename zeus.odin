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
	PARF, JUMP_FALSE, JUMP, END
}

block_stuff :: proc(program: string, i: int, bytecode: ^[dynamic]int, positions: ^[dynamic]int, regular_jump: bool) {
	if len(positions^) == 0 {
		fmt.eprintf("Error: No corresponding jump for end of block.\n")
		return
	}

	pos := pop(positions)

	if bytecode^[pos - 1] != int(ZeusBytecode.JUMP_FALSE) && (regular_jump && bytecode^[pos - 1] != int(ZeusBytecode.JUMP)) {
		fmt.eprintf("Error: No corresponding jump for end of block.\n")
		return
	}

	bytecode^[pos] = len(bytecode^)
}

actual_compile :: proc(std: ZeusStandard, program: string, i: int, bytecode: ^[dynamic]int, positions: ^[dynamic]int) {
	switch program[i] {
		case '+': append(bytecode, int(ZeusBytecode.INC))
		case '-': append(bytecode, int(ZeusBytecode.DEC))
		case '.': append(bytecode, int(ZeusBytecode.PUTN))
		case ':': append(bytecode, int(ZeusBytecode.PUTC))
		case '*': if std >= ZeusStandard.Z2 { append(bytecode, int(ZeusBytecode.MULT)) }
		case '/': if std >= ZeusStandard.Z2 { append(bytecode, int(ZeusBytecode.DIV)) }
		case '0': if std >= ZeusStandard.Z2 { append(bytecode, int(ZeusBytecode.ZERO)) }
		case '{': if std >= ZeusStandard.Z2 { append(bytecode, int(ZeusBytecode.SAVE)) }
		case '}': if std >= ZeusStandard.Z2 { append(bytecode, int(ZeusBytecode.RESTORE)) }
		case 'p': if std >= ZeusStandard.Z2 { append(bytecode, int(ZeusBytecode.PARF)) }
		case '?':
			if std < ZeusStandard.Z3 {
				return
			}

			append(bytecode, int(ZeusBytecode.JUMP_FALSE))
			append(positions, len(bytecode^))
			append(bytecode, i + 2)
		case '!':
			if std < ZeusStandard.Z3 {
				return
			}
			block_stuff(program, i, bytecode, positions, false)

			append(bytecode, int(ZeusBytecode.JUMP))
			append(positions, len(bytecode^))
			append(bytecode, i + 2)
		case ')':
			if std < ZeusStandard.Z3 {
				return
			}

			block_stuff(program, i, bytecode, positions, true)

			append(bytecode, int(ZeusBytecode.END))
	}
}

compile_zeus :: proc(program: string, std: ZeusStandard) -> [dynamic]int {
	bytecode := make([dynamic]int)

	doing_block_stuff := false

	positions := make([dynamic]int)
	defer delete(positions)

	for i in 0..<len(program) {
		actual_compile(std, program, i, &bytecode, &positions)
	}

	return bytecode
}

main :: proc() {
	std := ZeusStandard.Z3
	for arg in os.args[1:] {
		if arg[0] == '-' {
			parse_cmd_args(&std, arg[1:])
		}

		contents := read_file(arg)
		defer delete(contents)

		if contents == "" {
			continue
		}

		bytecode := compile_zeus(contents, std)
		defer delete(bytecode)

		fmt.printf("%v\n", bytecode)
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

exec_zeus :: proc(program: [dynamic]int) {
	storage: i64 = 0
	stack := make([dynamic]i64)

	defer delete(stack)

	for i := 0; i < len(program); i += 1 {
		switch ZeusBytecode(program[i]) {
			case .INC: storage += 1
			case .DEC: storage -= 1
			case .PUTN: fmt.printf("%d", storage)
			case .PUTC: fmt.printf("%c", storage)
			case .MULT: storage *= 2
			case .DIV: storage /= 2
			case .ZERO: storage = 0
			case .SAVE: append(&stack, storage)
			case .RESTORE: storage = pop(&stack)
			case .PARF: fmt.printf("meow :3\n")
		}
	}
}

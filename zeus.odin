package zeus

import "core:os"
import "core:strings"
import "core:fmt"
import "core:strconv"

ZeusStandard :: enum {
	Z1, Z2, Z3, Z4, Z4b
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
	PARF, JUMP_FALSE, JUMP, END,
	FOR, READN, READC, EQ, LT, NOT, SWAP,
		DEBUG, COUNT, COUNT_CHECK, COUNT_INC
}

block_stuff :: proc(program: string, i: int, bytecode: ^[dynamic]int, positions: ^[dynamic]int, regular_jump: bool) {
	if len(positions^) == 0 {
		fmt.eprintf("Error: No corresponding jump for end of block.\n")
		return
	}

	pos := pop(positions)

	if regular_jump && (bytecode^[pos - 1] == int(ZeusBytecode.COUNT)) {
		append(bytecode, int(ZeusBytecode.COUNT_INC))
		append(bytecode, int(ZeusBytecode.JUMP))
		append(bytecode, pos - 1)
		bytecode^[pos + 1] = len(bytecode^)
		return
	}

	if regular_jump && (bytecode^[pos - 1] == int(ZeusBytecode.FOR)) {
		append(bytecode, int(ZeusBytecode.JUMP))
		append(bytecode, pos - 1)
		bytecode^[pos + 1] = len(bytecode^)
		return
	}

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
			append(bytecode, len(bytecode^))
		case '!':
			if std < ZeusStandard.Z3 {
				return
			}
			block_stuff(program, i, bytecode, positions, false)

			append(bytecode, int(ZeusBytecode.JUMP))
			append(positions, len(bytecode^))
			append(bytecode, len(bytecode^))
		case ')':
			if std < ZeusStandard.Z3 {
				return
			}

			block_stuff(program, i, bytecode, positions, true)

			append(bytecode, int(ZeusBytecode.END))
		case 'f':
			if std < ZeusStandard.Z4 {
				return
			}

			append(bytecode, int(ZeusBytecode.FOR))
			append(positions, len(bytecode^))
			append(bytecode, int(ZeusBytecode.JUMP_FALSE))
			append(bytecode, len(bytecode^))
		case ',':
			if std < ZeusStandard.Z4 {
				return
			}

			append(bytecode, int(ZeusBytecode.READN))
		case ';':
			if std < ZeusStandard.Z4 {
				return
			}

			append(bytecode, int(ZeusBytecode.READC))
		case '=':
			if std < ZeusStandard.Z4 {
				return
			}

			append(bytecode, int(ZeusBytecode.EQ))
		case '<':
			if std < ZeusStandard.Z4 {
				return
			}

			append(bytecode, int(ZeusBytecode.LT))
		case '~':
			if std < ZeusStandard.Z4 {
				return
			}

			append(bytecode, int(ZeusBytecode.NOT))
		case '\\':
			if std < ZeusStandard.Z4 {
				return
			}

			append(bytecode, int(ZeusBytecode.SWAP))
		case 'd':
			if std < ZeusStandard.Z4b {
				return
			}

			append(bytecode, int(ZeusBytecode.DEBUG))
		case 'c':
			if std < ZeusStandard.Z4b {
				return
			}

			append(bytecode, int(ZeusBytecode.COUNT))
			append(positions, len(bytecode^))
			append(bytecode, int(ZeusBytecode.COUNT_CHECK))
			append(bytecode, len(bytecode^))
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
	std := ZeusStandard.Z4b
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

		exec_zeus(bytecode)
	}
}

parse_cmd_args :: proc(standard: ^ZeusStandard, arg: string) {
	switch arg {
		case "z1": standard^ = ZeusStandard.Z1
		case "z2": standard^ = ZeusStandard.Z2
		case "z3": standard^ = ZeusStandard.Z3
		case "z4": standard^ = ZeusStandard.Z4
		case "z4b": standard^ = ZeusStandard.Z4b
		case:
	}
}

exec_zeus :: proc(program: [dynamic]int) {
	storage: i64 = 0
	stack := make([dynamic]i64)

	defer delete(stack)

	counts := make([dynamic]i64)

	defer delete(counts)

	iterators := make([dynamic]i64)

	defer delete(iterators)

	buf: [32]byte

	i := 0
	for i < len(program) {
		// fmt.printf("i: %d %s\n", i, ZeusBytecode(program[i]))
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
			case .JUMP_FALSE:
				if storage == 0 {
					i = program[i + 1]
					// fmt.printf("jumping to %d\n", i)
				}
				else {
					i += 1
				}
			case .JUMP:
				i = program[i + 1]
				// fmt.printf("jumping to %d\n", i)
			case .READN:
				os.read(0, buf[:])
				storage, _ = strconv.parse_i64(string(buf[:]))
			case .READC:
				os.read(0, buf[:])
				storage = i64(buf[0])
			case .EQ:
				if len(stack) <= 0 {
					fmt.eprintf("Cannot perform equality check because there is nothing to compare against!\n")
					continue
				}

				append(&stack, storage)
				storage = i64(storage == stack[len(stack) - 2])
			case .LT:
				if len(stack) <= 0 {
					fmt.eprintf("Cannot perform less-than check because there is nothing to compare against!\n")
					continue
				}

				append(&stack, storage)
				storage = i64(storage < stack[len(stack) - 2])
			case .NOT:
				storage = i64(!bool(storage))
			case .SWAP:
				temp := pop(&stack)
				append(&stack, storage)

				storage = temp
			case .DEBUG:
				fmt.printf("Storage cell: %d\n", storage)
				fmt.printf("Stack: %v\n", stack)
			case .COUNT:
				append(&counts, storage)
				append(&iterators, 0)
			case .COUNT_CHECK:
				idx := len(iterators) - 1
				if iterators[idx] >= counts[idx] {
					i = program[i + 1] + 1
					continue
				}

				i += 1
			case .COUNT_INC:
				iterators[len(iterators) - 1] += 1
				i += 1
			case .END:
			case .FOR:
		}
		i += 1
	}
}

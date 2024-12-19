# zeus - the perfect esoteric programming languagewirtenn in Odin
it's perfect. literally perfect. it currently has 3 standards. z1 is the most minimalistic one and contains only 4 operations. every operation is one character long.

## z1 standard
- introduced `+` which increments the storage cell
- introduced `-` which decrements the storage cell
- introduced `.` which prints the storage cell as a number
- introduced `:` which prints the storage cell as a char

## z2 standard
- introduced `*` which multiplies the storage cell by 2
- introduced `/` which divides the storage cell by 2
- introduced `0` which resets the storage cell to 0
- introduced `{` which pushes the storage cell onto a stack
- introduced `}` which pops the storage cell from a stack

## z3 standard
- introduced `p` which is the parf operation
- introduced `?` which checks if the storage is 0 and if that's true jumps to either the end or else branch
- introduced `!` which is the else branch
- introduced `)` which is the end of a block

## z4 standard
- introduced `f` which is a looping construct (executes code block ending with `)` while storage cell is nonzero)
- introduced `,` which reads a number from the user into the storage cell
- introduced `;` which reads a single character from the user (technically it reads a bunch but only saves the first one)
- introduced `=` which checks if the storage cell and value atop the stack are equal. it saves a 0 or 1 into the storage cell backing up the initial value onto the top of the stack
- introduced `<` which does the same thing as `=` but actually checks if hte storage cell is less than top of hte stack instead
- introduced `~` which performs logical not on the storage cell
- introduced `\` which swaps the storage cell and value atop the stack

### z4b standard
- introduced `d` which prints the stack and storage cell
- introduced the count loop `c` which executes a block of code storage cell times
- introduced `m` which pushes the storage cell to the stack and sets it to a pointer to beginning of memory
- introduced `r` which reads from the address in storage cell and pushes the value to the stack
- introduced `w` which writes the top of hte stack to the address in the storage cell

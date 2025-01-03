#pragma once

#include <stddef.h>
#include <stdint.h>

typedef enum {
	OP_INC,
	OP_INCN,
	OP_DEC,

	OP_PUTC,
	OP_PUTN,
	OP_PUTF,
} bcode;

typedef struct bclist {
	bcode *items;
	size_t size;
	size_t cap;
} bclist_t;

void init_bclist(bclist_t *list);
void append_bclist(bclist_t *list, bcode elem);
void free_bclist(bclist_t *list);

// This function does NOT free the original list.
// Always remember to free it yourself
bclist_t *optimize_bclist(bclist_t *list);

// Write a list of bytecode into a binary file
void writeout_bclist(bclist_t *list, char *filename);
// Read a list of bytecode from a binary file
bclist_t *read_bytecode(char *filename);

void print_bclist(bclist_t *list);

void execute_bclist(bclist_t *list);

typedef struct bc_executor {
	bclist_t *list;
	size_t iter;
	int64_t storage;
} bcexec_t;

#include <bytecode.h>
#include <stdlib.h>

void init_bclist(bclist_t *list) {
	list->size = 0;
	list->cap = 0;
	list->items = NULL;
}

void append_bclist(bclist_t *list, bcode bc) {
	if (list->size >= list->cap) {
		if (list->cap == 0) list->cap = 4;
		list->cap <<= 1;
		list->items = realloc(list->items, list->cap);
	}

	list->items[list->size++] = bc;
}

void free_bclist(bclist_t *list) {
	free(list->items);
	init_bclist(list);
}

typedef struct bc_optimizer {
	bclist_t *list;
	int16_t counter;
	size_t *i;
} bcopt_t;

void optimize_switch(bcopt_t *optimizer, bclist_t *out_list) {
	switch (optimizer->list->items[*optimizer->i]) {
		case OP_INC:
			optimizer->counter++;
			break;
		case OP_DEC:
			optimizer->counter--;
			break;
		case OP_PUTC:
			if (optimizer->counter) {
				uint8_t lsb = (uint8_t)optimizer->counter & 0xff;
				uint8_t msb = (uint8_t)optimizer->counter >> 8;
				optimizer->counter = 0;
			}
	}
}

bclist_t *optimize_bclist(bclist_t *list) {
	bcopt_t optimizer = (bcopt_t) {
		.list = list,
		.counter = 0
	};

	for (size_t i = 0; i < list->size; i++) {
	}
}

void execute_bclist(bclist_t *list) {
	for (size_t i = 0; i < list->size; i++) {
	}
}

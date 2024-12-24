#include "zeus_str.h"
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
	int64_t cell;
	zstr_t *format;
	uint16_t putncount;
} bcopt_t;

static void optimize_incdec(bcopt_t *optimizer, bclist_t *out_list) {
	if (!optimizer->counter) {
		return;
	}

	uint8_t lsb = (uint8_t)optimizer->counter & 0xff;
	uint8_t msb = (uint8_t)optimizer->counter >> 8;

	optimizer->cell += optimizer->counter;

	append_bclist(out_list, OP_INCN);
	append_bclist(out_list, lsb);
	append_bclist(out_list, msb);

	optimizer->counter = 0;
}

// putf is a special instruction
static void wrapup_putf(bcopt_t *optimizer, bclist_t *out_list) {
	append_bclist(out_list, OP_PUTF);

	uint8_t lsb = (uint8_t)optimizer->putncount & 0xff;
	uint8_t msb = (uint8_t)optimizer->putncount >> 8;

	append_bclist(out_list, lsb);
	append_bclist(out_list, msb);
}

void optimize_switch(bcopt_t *optimizer, bclist_t *out_list) {
	switch (optimizer->list->items[*optimizer->i]) {
		case OP_INC:
			optimizer->counter++;
			break;
		case OP_DEC:
			optimizer->counter--;
			break;
		case OP_PUTC:
			optimize_incdec(optimizer, out_list);

			char *s = malloc(2);
			s[0] = (char)optimizer->cell;
			s[1] = '\0';

			zstr_t str = zfrom_cstr(s);

			// we can free s since str has a copy of it
			free(s);

			zappend(optimizer->format, &str);

			zfree(&str);

			if ((char)optimizer->cell == 10) {
				wrapup_putf(optimizer, out_list);
			}
			break;
		case OP_PUTN:
			optimizer->putncount++;
			optimize_incdec(optimizer, out_list);

			zstr_t fmt = zfrom_cstr("%d");

			zappend(optimizer->format, &str);

			zfree(&fmt);

			if (optimizer->putncount >= UINT16_MAX - 1) {
				wrapup_putf(optimizer, out_list);
			}
		default:
			break;
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

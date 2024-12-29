#include "zeus_str.h"
#include <bytecode.h>
#include <stdlib.h>
#include <stdio.h>

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
	zstr_t format;
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

	for (int i = 0; i < optimizer->format.len; i++) {
		append_bclist(out_list, optimizer->format.cstr[i]);
	}

	append_bclist(out_list, 0);
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

			zappend(&optimizer->format, &str);

			zfree(&str);

			if ((char)optimizer->cell == 10) {
				wrapup_putf(optimizer, out_list);
			}
			break;
		case OP_PUTN:
			optimizer->putncount++;
			optimize_incdec(optimizer, out_list);

			zstr_t fmt = zfrom_cstr("%d");

			zappend(&optimizer->format, &fmt);

			zfree(&fmt);

			if (optimizer->putncount >= UINT16_MAX - 1) {
				wrapup_putf(optimizer, out_list);
			}
		case OP_PUTF:
			(*optimizer->i) += 2;

			while (optimizer->list->items[*optimizer->i] != 0) {
				(*optimizer->i)++;
			}
			break;
		case OP_INCN:
			(*optimizer->i) += 2;
			break;
	}
}

bclist_t *optimize_bclist(bclist_t *list) {
	bcopt_t optimizer = (bcopt_t) {
		.list = list,
		.counter = 0,
		.cell = 0,
		.putncount = 0,
		.format = zfrom_cstr(""),
	};

	bclist_t *out = malloc(sizeof(bclist_t));
	init_bclist(out);

	size_t i = 0;
	optimizer.i = &i;

	for (; *optimizer.i < list->size; (*optimizer.i)++) {
		optimize_switch(&optimizer, out);
	}

	return out;
}

char *op_string(bcode op) {
	switch (op) {
		case OP_INC: return "OP_INC";
		case OP_INCN: return "OP_INCN";
		case OP_DEC: return "OP_DEC";
		case OP_PUTC: return "OP_PUTC";
		case OP_PUTF: return "OP_PUTF";
		case OP_PUTN: return "OP_PUTN";
	}
}

static void print_args(bcode op, bclist_t *list, size_t *i) {
	switch (op) {
		case OP_INCN: {
			// collect bytes
			(*i)++;
			uint8_t lsb = list->items[*i];
			(*i)++;
			uint8_t msb = list->items[*i];

			uint16_t num = (msb << 8) | lsb;
			printf(" %d", num);

			break;
		}
		case OP_PUTF: {
			(*i)++;
			uint8_t lsb = list->items[*i];
			(*i)++;
			uint8_t msb = list->items[*i];

			uint16_t putncount = (msb << 8) | lsb;

			printf(" %d", putncount);

			zstr_t string = zfrom_cstr("");

			char temp[5] = {0};
			uint8_t counter = 0;

			(*i)++;

			while (list->items[*i] != 0) {
				if (counter >= 4) {
					temp[4] = '\0';

					zstr_t ztemp = zfrom_cstr(temp);

					zappend(&string, &ztemp);

					zfree(&ztemp);
					counter = 0;
				}

				temp[counter++] = list->items[*i];
				(*i)++;
			}

			if (counter > 0) {
				temp[4] = '\0';

				zstr_t ztemp = zfrom_cstr(temp);

				zappend(&string, &ztemp);

				zfree(&ztemp);
				counter = 0;
			}

			printf(" '%s'", string.cstr);

			zfree(&string);
			break;
		}
		default:
			break;
	}

	printf("\n");
}

void print_bclist(bclist_t *list) {
	for (size_t i = 0; i < list->size; i++) {
		bcode op = list->items[i];

		printf("%s", op_string(op));

		print_args(op, list, &i);
	}
}

void execute_bclist(bclist_t *list) {
	for (size_t i = 0; i < list->size; i++) {
	}
}

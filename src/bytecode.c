#include <zeus_str.h>
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
		if (list->cap < 1) list->cap = 8;
		list->cap *= 2;
		list->items = realloc(list->items, list->cap * sizeof(bcode));
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
			append_bclist(out_list, OP_PUTC);
			break;
		case OP_PUTN:
			optimize_incdec(optimizer, out_list);
			append_bclist(out_list, OP_PUTN);
			break;
		case OP_INCN:
			optimize_incdec(optimizer, out_list);
			append_bclist(out_list, OP_INCN);
			(*optimizer->i)++;
			append_bclist(out_list, optimizer->list->items[*optimizer->i]);
			(*optimizer->i)++;
			append_bclist(out_list, optimizer->list->items[*optimizer->i]);
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

	if (!optimizer.counter) {
		optimize_incdec(&optimizer, out);
	}

	zfree(&optimizer.format);

	return out;
}

char *op_string(bcode op) {
	switch (op) {
		case OP_INC: return "OP_INC";
		case OP_INCN: return "OP_INCN";
		case OP_DEC: return "OP_DEC";
		case OP_PUTC: return "OP_PUTC";
		case OP_PUTN: return "OP_PUTN";
		default: return "UNKNOWN";
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

static void execute_instr(bclist_t *list, size_t *i, int64_t *storage) {
	switch (list->items[*i]) {
		case OP_INC:
			(*storage)++;
			break;
		case OP_INCN:
			(*i)++;
			uint8_t lsb = list->items[*i];
			(*i)++;
			uint8_t msb = list->items[*i];

			uint16_t num = (msb << 8) | lsb;

			(*storage) += num;
			break;
		case OP_DEC:
			(*storage)--;
			break;
		case OP_PUTC:
			printf("%c", (char) *storage);
			break;
		case OP_PUTN:
			printf("%ld", *storage);
			break;
	}
}

void execute_bclist(bclist_t *list) {
	int64_t storage = 0;
	for (size_t i = 0; i < list->size; i++) {
		execute_instr(list, &i, &storage);
	}
}

bclist_t *read_bytecode(char *filename) {
	FILE *file = fopen(filename, "rb");

	if (file == NULL) {
		fprintf(stderr, "Couldn't open file '%s' for reading bytecode.\n", filename);
		return NULL;
	}

	fseek(file, 0L, SEEK_END);

	size_t s = ftell(file);
	rewind(file);

	char *buffer = malloc(s + 1);

	size_t r = fread(buffer, sizeof(char), s, file);
	buffer[r] = '\0';

	fclose(file);

	bclist_t *list = malloc(sizeof(bclist_t));
	init_bclist(list);

	for (int i = 0; i < r; i++) {
		if (buffer[i] != '#') {
			append_bclist(list, buffer[i]);
			continue;
		}

		i++;
		if (buffer[i] != '!') {
			i--;
			continue;
		}

		while (buffer[i] != 10 && buffer[i] != '\0') {
			i++;
		}
	}

	return list;
}

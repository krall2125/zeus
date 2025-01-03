#include <bytecode.h>
#include <compiler.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

bclist_t *compile(char *src) {
	bclist_t *list = malloc(sizeof(bclist_t));

	init_bclist(list);

	for (int i = 0; i < strlen(src); i++) {
		switch (src[i]) {
			case '+':
				append_bclist(list, OP_INC);
				break;
			case '-':
				append_bclist(list, OP_DEC);
				break;
			case '.':
				append_bclist(list, OP_PUTN);
				break;
			case ':':
				append_bclist(list, OP_PUTC);
				break;
		}
	}

	return list;
}

char *read_file(const char *path, size_t *len) {
	FILE *file = fopen(path, "rb");

	if (file == NULL) {
		fprintf(stderr, "Couldn't open file '%s'.\n", path);
		return NULL;
	}

	fseek(file, 0L, SEEK_END);

	size_t s = ftell(file);
	rewind(file);

	char *buffer = malloc(s + 1);

	size_t r = fread(buffer, sizeof(char), s, file);
	buffer[r] = '\0';

	if (len != NULL) {
		*len = r;
	}

	fclose(file);

	return buffer;
}

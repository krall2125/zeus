#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zeus_str.h>

zstr_t zstring() {
	zstr_t str = (zstr_t) {
		.cstr = malloc(1),
		.len = 1
	};

	return str;
}

zstr_t from_cstr(char *cstr) {
	size_t len = strlen(cstr);

	zstr_t str = (zstr_t) {
		.cstr = malloc(len),
		.len = len
	};

	strcpy(str.cstr, cstr);

	return str;
}

void zappend(zstr_t *dest, zstr_t *src) {
	size_t outlen = dest->len + src->len - 1;

	char *temp = realloc(dest->cstr, outlen);
	if (!temp) {
		fprintf(stderr, "Memory allocation error.\n");
		return;
	}

	dest->cstr = temp;

	strcat(dest->cstr, src->cstr);
}

void zfree(zstr_t *str) {
	free(str->cstr);

	str->len = 0;
	str->cstr = NULL;
}

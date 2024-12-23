#pragma once

#include <stddef.h>

typedef struct zeus_string {
	char *cstr;
	size_t len;
} zstr_t;

zstr_t zstring();
zstr_t zfrom_cstr(char *cstr);

void zappend(zstr_t *dest, zstr_t *src);

void zfree(zstr_t *str);

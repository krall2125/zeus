#pragma once

#include <bytecode.h>

char *read_file(const char *path, size_t *len);
bclist_t *compile(char *src);

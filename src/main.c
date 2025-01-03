#include <bytecode.h>
#include <stdlib.h>
#include <compiler.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
	for (int i = 1; i < argc; i++) {
		if (strcmp(argv[i], "exec") == 0) {
			i++;
			if (i >= argc) {
				fprintf(stderr, "Usage: zeus exec [filename]\n");
				fprintf(stderr, "Execute a file of zeus bytecode.\n");
				exit(1);
			}

			bclist_t *list = read_bytecode(argv[i]);

			if (list == NULL) {
				exit(1);
			}

			bclist_t *optimized = optimize_bclist(list);

			print_bclist(optimized);

			execute_bclist(optimized);

			free_bclist(optimized);
			free(optimized);
			free_bclist(list);
			free(list);
		}
	}

	return 0;
}

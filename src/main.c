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

			execute_bclist(list);

			free_bclist(list);
			free(list);
		}
		else if (strcmp(argv[i], "c") == 0) {
			i++;
			if (i >= argc) {
				fprintf(stderr, "Usage: zeus c [filename]\n");
				fprintf(stderr, "Compile a zeus file.\n");
				exit(1);
			}

			char *src = read_file(argv[i], NULL);

			if (src == NULL) {
				exit(1);
			}

			bclist_t *list = compile(src);
			free(src);

			char *main_filename = strtok(argv[i], ".");

			bclist_t *optimized = optimize_bclist(list);

			free_bclist(list);
			free(list);

			int len = strlen(main_filename) + 5;
			char *output = malloc(len);

			memset(output, 0, len - 1);

			strcat(output, main_filename);
			strcat(output, ".zbc");

			writeout_bclist(optimized, output);

			free(output);

			free_bclist(optimized);
			free(optimized);
		}
		else if (strcmp(argv[i], "run") == 0) {
			i++;
			if (i >= argc) {
				fprintf(stderr, "Usage: zeus run [filename]\n");
				fprintf(stderr, "Run a zeus file without generating a binary bytecode file.\n");
				exit(1);
			}

			char *src = read_file(argv[i], NULL);

			if (src == NULL) {
				exit(1);
			}

			bclist_t *list = compile(src);
			free(src);

			bclist_t *optimized = optimize_bclist(list);

			execute_bclist(optimized);

			free_bclist(optimized);
			free(optimized);
		}
	}

	return 0;
}

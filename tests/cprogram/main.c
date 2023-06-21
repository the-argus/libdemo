#include <demo.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stderr, "No file path provided");
    exit(EXIT_FAILURE);
  }

  FILE *demo_fp = fopen(argv[1], "r");

  if (!demo_fp) {
    perror("Error opening file: ");
    exit(EXIT_FAILURE);
  }

  demo_to_json(demo_fp, stdout);

  fclose(demo_fp);

  return 0;
}

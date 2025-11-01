#include "listings/listing65.c"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//
// Task: generate a json file:
//
// pairs array containing multiple x0 y0 x1 y1 in the range x [-180, 180] and y [-90, 90]
// generator input: generator.exe [uniform | cluster] [seed] [n of points]
// output: the json file, also the method, seed, pair count and expected sum which can be taken
// via the function fo listing 65
//

typedef const uint32_t u32;
typedef uint32_t mu32;
typedef uint32_t b32;

typedef const int32_t s32;
typedef int32_t ms32;

typedef const double f64;
typedef double mf64;

typedef struct pair_t
{
  mf64 x0, y0;
  mf64 x1, y1;
} pair_t;

float rand_range(float min, float max)
{
  float scale = rand() / (float)RAND_MAX;
  return min + scale * (max - min);
}

static FILE *open_haversine_stream(const b32 is_cluster)
{
  char buf[256];
  sprintf(buf, "haversine_%s.json", is_cluster ? "cluster" : "uniform");
  return fopen(buf, "w");
}

int main(int argc, char *argv[])
{
  if (argc != 4)
  {
  bad_args:
    printf("use generator.exe [uniform | cluster] [seed] [n of pairs]\n");
    return 0;
  }

  b32 is_cluster = strcmp(argv[1], "cluster");
  b32 is_uniform = strcmp(argv[1], "uniform");

  if (!is_cluster && !is_uniform)
  {
    printf("[uniform | cluster] are the only options.\n");
    goto bad_args;
  }

  u32 seed = strtol(argv[2], NULL, 10);

  if (seed == 0L)
  {
    printf("[seed] must be a 32-bit integer.\n");
    goto bad_args;
  }

  u32 n_pairs = strtol(argv[3], NULL, 10);

  if (n_pairs == 0L)
  {
    printf("[n of pairs] must be a 32-bit integer.\n");
    goto bad_args;
  }

  mf64 estimated_total;
  pair_t pairs[n_pairs];
  for (mu32 i = 0; i < n_pairs; ++i)
  {
    srand(seed);
    f64 x0 = rand_range(-180, 180);
    f64 y0 = rand_range(-90, 90);
    f64 x1 = rand_range(-180, 180);
    f64 y1 = rand_range(-90, 90);

    pairs[i] = (pair_t){
        .x0 = x0,
        .y0 = y0,
        .x1 = y1,
        .y1 = x1,
    };

    estimated_total += ReferenceHaversine(x0, y0, x1, y1, 6372.8);
  }

  FILE *haversine_json = open_haversine_stream(is_cluster);
  fprintf(haversine_json, "{\"pairs\":[\n");

  for (mu32 i = 0; i < n_pairs; ++i)
  {
    if (i == n_pairs - 1)
    {
      fprintf(haversine_json, "{\"x0\":%.16f, \"y0\":%.16f, \"x1\":%.16f, \"y1\":%.16f}\n",
              pairs[i].x0, pairs[i].y0, pairs[i].x1, pairs[i].x1);

      break;
    }
    fprintf(haversine_json, "{\"x0\":%.16f, \"y0\":%.16f, \"x1\":%.16f, \"y1\":%.16f},\n",
            pairs[i].x0, pairs[i].y0, pairs[i].x1, pairs[i].x1);
  }

  fprintf(haversine_json, "]}\n");
  fclose(haversine_json);

  printf("Method: %s\n", is_cluster ? "cluster" : "uniform");
  printf("Seed: %d\n", seed);
  printf("Pairs: %d\n", n_pairs);
  printf("Expected sum: %.16f\n", estimated_total);
}

#include "listings/listing65.c"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

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

typedef const float f32;
typedef float mf32;

typedef const double f64;
typedef double mf64;

typedef struct pair_t
{
  mf64 x0, y0;
  mf64 x1, y1;
} pair_t;

static inline f32 rand_range(f32 min, f32 max)
{
  return ((max - min) * ((float)rand() / RAND_MAX)) + min;
}

static inline FILE *open_haversine_json_stream(const b32 is_cluster)
{
  char buf[256];
  sprintf(buf, "haversine_%s.json", is_cluster ? "cluster" : "uniform");
  return fopen(buf, "w");
}

static inline FILE *open_haversine_value_stream(void)
{
  char buf[256];
  sprintf(buf, "haversine_value.f64");
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

  b32 is_uniform = strcmp(argv[1], "uniform") == 0 ? 1 : 0;
  b32 is_cluster = strcmp(argv[1], "cluster") == 0 ? 1 : 0;

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

  srand(seed);

  u32 n_pairs = strtol(argv[3], NULL, 10);

  if (n_pairs == 0L)
  {
    printf("[n of pairs] must be a 32-bit integer.\n");
    goto bad_args;
  }

  LARGE_INTEGER StartingTime, EndingTime, ElapsedMicroseconds;
  LARGE_INTEGER Frequency;

  QueryPerformanceFrequency(&Frequency);
  QueryPerformanceCounter(&StartingTime);

  mf64 estimated_total = 0.0;
  pair_t *pairs = malloc(n_pairs * sizeof(pair_t));

  if (is_uniform)
  {
    for (mu32 i = 0; i < n_pairs; ++i)
    {
      f64 x0 = rand_range(-180, 180);
      f64 y0 = rand_range(-90, 90);
      f64 x1 = rand_range(-180, 180);
      f64 y1 = rand_range(-90, 90);
      pairs[i] = (pair_t){
          .x0 = x0,
          .y0 = y0,
          .x1 = x1,
          .y1 = y1,
      };
      estimated_total += ReferenceHaversine(x0, y0, x1, y1, 6372.8);
    }
  }
  else
  {
    mu32 n_clusters = 32;
    mu32 j = 0;
    mu32 n_per_cluster = n_pairs;

    if (n_pairs < n_clusters)
    {
      n_clusters = 1;
    }
    else
    {
      n_per_cluster = n_pairs / n_clusters;
    }
    for (mu32 i = 0; i < n_clusters; ++i)
    {
      f64 cluster_center_x = rand_range(-180, 180);
      f64 cluster_center_y = rand_range(-90, 90);

      f64 rect_width = rand_range(16.0, 32.0);
      f64 rect_height = rand_range(16.0, 32.0);

      for (mu32 k = 0; k < n_per_cluster; ++k)
      {
        f64 offset_x0 = rand_range(-rect_width / 2.0, rect_width / 2.0);
        f64 offset_y0 = rand_range(-rect_height / 2.0, rect_height / 2.0);
        f64 offset_x1 = rand_range(-rect_width / 2.0, rect_width / 2.0);
        f64 offset_y1 = rand_range(-rect_height / 2.0, rect_height / 2.0);

        mf64 x0 = cluster_center_x + offset_x0;
        mf64 y0 = cluster_center_y + offset_y0;
        mf64 x1 = cluster_center_x + offset_x1;
        mf64 y1 = cluster_center_y + offset_y1;

        x0 = (x0 < -180) ? -180 : (x0 > 180) ? 180 : x0;
        y0 = (y0 < -90) ? -90 : (y0 > 90) ? 90 : y0;
        x1 = (x1 < -180) ? -180 : (x1 > 180) ? 180 : x1;
        y1 = (y1 < -90) ? -90 : (y1 > 90) ? 90 : y1;

        pairs[j++] = (pair_t){
            .x0 = x0,
            .y0 = y0,
            .x1 = x1,
            .y1 = y1,
        };
        estimated_total += ReferenceHaversine(x0, y0, x1, y1, 6372.8);
      }
    }
  }

  QueryPerformanceCounter(&EndingTime);
  LONGLONG elapsed_micro = EndingTime.QuadPart - StartingTime.QuadPart;
  double elapsed_sec = (double)elapsed_micro / (double)Frequency.QuadPart;
  printf("Elapsed time to generate pairs: %.6f\n", elapsed_sec);

  printf("Method: %s\n", is_cluster ? "cluster" : "uniform");
  printf("Seed: %d\n", seed);
  printf("Pairs: %d\n", n_pairs);
  printf("Expected sum: %.16f\n", estimated_total / n_pairs);

  FILE *haversine_value_file = open_haversine_value_stream();
  FILE *haversine_json_file = open_haversine_json_stream(is_cluster);

  fprintf(haversine_json_file, "{\"pairs\":[\n");

  for (mu32 i = 0; i < n_pairs; ++i)
  {
    if (i == n_pairs - 1)
    {
      fprintf(haversine_json_file, "{\"x0\":%.16f, \"y0\":%.16f, \"x1\":%.16f, \"y1\":%.16f}\n",
              pairs[i].x0, pairs[i].y0, pairs[i].x1, pairs[i].y1);

      break;
    }
    fprintf(haversine_json_file, "{\"x0\":%.16f, \"y0\":%.16f, \"x1\":%.16f, \"y1\":%.16f},\n",
            pairs[i].x0, pairs[i].y0, pairs[i].x1, pairs[i].y1);
  }

  fprintf(haversine_json_file, "]}\n");
  fclose(haversine_json_file);

  char buf[256];
  sprintf(buf, "%.16f\n", estimated_total / n_pairs);

  fprintf(haversine_value_file, "%s", buf);
  fclose(haversine_value_file);
  free(pairs);
}

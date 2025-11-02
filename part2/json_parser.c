#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef const uint8_t u8;
typedef uint8_t mu8;

typedef const uint32_t u32;
typedef uint32_t mu32;

typedef const int64_t s64;
typedef int64_t ms64;

typedef const double f64;
typedef double mf64;

typedef struct pair_t
{
  f64 x0, y0, x1, y1;
} pair_t;

static void parse_json(FILE *json_input)
{
  char *data = NULL;
  ms64 bufsize = 0;
  mu32 lines = 0;

  while (!feof(json_input))
  {
    char ch = fgetc(json_input);
    if (ch == '\n')
    {
      lines++;
    }
  }

  if (json_input != NULL)
  {
    if (fseek(json_input, 0L, SEEK_END) == 0)
    {
      bufsize = ftell(json_input);
      if (bufsize == -1)
      {
        return;
      }

      data = malloc(sizeof(char) * (bufsize));

      if (fseek(json_input, 0L, SEEK_SET) != 0)
      {
        return;
      }

      size_t newLen = fread(data, sizeof(char), bufsize, json_input);
      if (ferror(json_input) != 0)
      {
        fputs("Error reading file", stderr);
      }
      else
      {
        data[newLen++] = '\0';
      }
    }
    fclose(json_input);
  }

  mu8 *cursor = (mu8 *)data;
  mu8 *end = cursor + bufsize;

  while (cursor < end)
  {
    if (cursor[0] == '{' && cursor[1] == '"')
    {
      cursor += 2;
      char field[256];
      mu32 i = 0;
      while (cursor[0] != '"')
      {
        field[i++] = *cursor++;
      }
      field[i] = '\0';
      cursor++;

      printf("field: %s\n", field);

      if (cursor[0] == ':' && cursor[1] == '[')
      {
        mu32 num_fields = 0;
        while (cursor[0] != ']')
        {
          if (cursor[0] == '}')
          {
            num_fields++;
          }
          cursor++;
        }
        printf("num values in field: %d\n", num_fields);
      }
    }

    cursor++;
  }

  free(data);
}

int main(int argc, char **argv)
{
  if ((argc < 2) || (argc > 3))
  {
    printf("usage:\n- json_parser.exe [haversine_input.json]\n- json_parser.exe "
           "[haversine_input.json] [haversine_answer.f64]");
    return 0;
  }

  FILE *haversine_input = fopen(argv[1], "r");
  parse_json(haversine_input);

  if (argc == 3)
  {
    printf("todo: parse answer");
  }

  fclose(haversine_input);
}

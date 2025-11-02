rmdir build /s /q
mkdir build

clang -g -O0 json_parser.c -o build\json_parser.exe


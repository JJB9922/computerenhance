rmdir build /s /q
mkdir build

clang -g -O0 haversine_generator.c -o build\haversine_generator.exe


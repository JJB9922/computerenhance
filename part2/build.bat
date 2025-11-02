rmdir build /s /q
mkdir build

clang -O3 haversine_generator.c -o build\haversine_generator.exe


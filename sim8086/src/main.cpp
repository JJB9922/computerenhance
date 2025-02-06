#include <cstdlib>
#include <iostream>

#include "disassembler.h"

int main(int argc, char *argv[]) {

  if (argc < 1) {
    std::cerr << "use: ./d {filename}";
    return EXIT_FAILURE;
  }

  char *filename = argv[1];
  printf("bits 16\n\n");

  auto instructions = Disassembler::fromFileGetBinaryInstructions(filename);

  for (auto &i : instructions) {
    auto instruction = Disassembler::fromBinaryInstructionGetAssemblyInstruction(i);
    std::cout << instruction << "\n";
  }

  return EXIT_SUCCESS;
}

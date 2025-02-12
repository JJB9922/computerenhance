#ifndef DISASSEMBLER_H
#define DISASSEMBLER_H

#include <bitset>
#include <map>
#include <string>

namespace Disassembler {

enum class ModEncoding {
  None,
  NoDisplacement,
  EightBitDisplacement,
  SixteenBitDisplacement,
  RegisterMode
};

static const std::map<std::string, std::string> opcodeFromBinary{
    {"100010", "mov"},   // Reg/Mem to/from Reg
    {"1100011", "mov"},  // Immediate to Reg/Mem
    {"1011", "mov"},     // Immediate to Reg
    {"1010000", "mov"},  // Mem to Accumulator
    {"1010001", "mov"},  // Accumulator to Mem
    {"10001110", "mov"}, // Reg/Mem to Segment Reg
    {"10001100", "mov"}, // Segment Reg to Reg/Mem
};

static const std::map<std::string, std::string> regFromBinaryWord{
    {"000", "ax"}, {"001", "cx"}, {"010", "dx"}, {"011", "bx"},
    {"100", "sp"}, {"101", "bp"}, {"110", "si"}, {"111", "di"},
};

static const std::map<std::string, std::string> regFromBinaryByte{
    {"000", "al"}, {"001", "cl"}, {"010", "dl"}, {"011", "bl"},
    {"100", "ah"}, {"101", "ch"}, {"110", "dh"}, {"111", "bh"},
};

static const std::map<std::string, std::string> rmFromBinaryWord{
    {"000", "ax"}, {"001", "cx"}, {"010", "dx"}, {"011", "bx"},
    {"100", "sp"}, {"101", "bp"}, {"110", "si"}, {"111", "di"},
};

static const std::map<std::string, std::string> rmFromBinaryByte{
    {"000", "al"}, {"001", "cl"}, {"010", "dl"}, {"011", "bl"},
    {"100", "ah"}, {"101", "ch"}, {"110", "dh"}, {"111", "bh"},
};

std::string
fromBinaryInstructionGetAssemblyInstruction(const std::bitset<48> &byte);
std::vector<std::bitset<48>>
fromFileGetBinaryInstructions(const char *filename);

} // namespace Disassembler

#endif // DISASSEMBLER.H

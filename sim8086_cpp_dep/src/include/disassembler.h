#ifndef DISASSEMBLER_H
#define DISASSEMBLER_H

#include <bitset>
#include <map>
#include <string>

namespace Disassembler {

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
    std::vector<std::string>
    fromFileGetBinaryInstructions(const char *filename);

}

#endif // DISASSEMBLER.H

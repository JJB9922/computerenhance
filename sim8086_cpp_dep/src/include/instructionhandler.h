#ifndef INSTRUCTION_HANDLER_H
#define INSTRUCTION_HANDLER_H

#include <string>
#include <map>

namespace InstructionHandler
{
    enum class OpCode
    {
        NONE = 0,
        MOVA,
        MOVB,
        MOVC,
        MOVD,
        MOVE,
        MOVF,
        MOVG
    };
     
     enum class ModEncoding {
      None,
      NoDisplacement,
      EightBitDisplacement,
      SixteenBitDisplacement,
      RegisterMode
    };

    static const std::map<std::string, OpCode> opcodeFromBinary{
        {"100010", OpCode::MOVA},   // Reg/Mem to/from Reg
        {"1100011", OpCode::MOVB},  // Immediate to Reg/Mem
        {"1011", OpCode::MOVC},     // Immediate to Reg
        {"1010000", OpCode::MOVD},  // Mem to Accumulator
        {"1010001", OpCode::MOVE},  // Accumulator to Mem
        {"10001110", OpCode::MOVF}, // Reg/Mem to Segment Reg
        {"10001100", OpCode::MOVG}, // Segment Reg to Reg/Mem
    };

    void handleMOVA();
    ModEncoding GetModEncoding(const std::string &mod);
    std::string GetBinaryInstructionWithModeData(std::ifstream &is, const ModEncoding &mod, char (&parse)[6], uint8_t &location);
}

#endif // INSTRUCTION_HANDLER_H
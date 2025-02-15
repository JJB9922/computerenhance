#include "disassembler.h"
#include "instructionhandler.h"

#include <fstream>
#include <ios>
#include <iostream>

namespace Disassembler
{

  std::string
  fromBinaryInstructionGetAssemblyInstruction(const std::bitset<48> &byte)
  {
    return std::string();
  }

  InstructionHandler::OpCode GetOpcode(char &c)
  {
    std::string parsedOpcode = std::bitset<8>(c).to_string();
    InstructionHandler::OpCode foundOpcode = InstructionHandler::OpCode::NONE;

    for (auto const &[key, val] : InstructionHandler::opcodeFromBinary)
    {
      if (parsedOpcode.find(key) != std::string::npos)
      {
        foundOpcode = val;
        break;
      }
    }

    return foundOpcode;
  }

  std::vector<std::string>
  fromFileGetBinaryInstructions(const char *filename)
  {
    std::vector<std::string> instructions;
    std::ifstream is(filename, std::ifstream::in);

    is.seekg(0, std::ios_base::end);
    auto lengthInChars = is.tellg();

    uint8_t location = 0;
    while (location < lengthInChars)
    {
      // Step 1: Find opcode so we know what type of instruction we are dealing with
      char parse[6];
      is.seekg(location);
      is.read(parse, 1);
      InstructionHandler::OpCode currentOpcode = GetOpcode(parse[0]);

      // Step 2: Figure out how to parse this instruction in terms of bit length
      InstructionHandler::ModEncoding modEncoding;
      switch (currentOpcode)
      {

      case InstructionHandler::OpCode::MOVA:
      {
        std::cout << "MOVA\n";
        is.seekg(location);
        is.read(parse, 2);

        std::string mod = std::bitset<8>(parse[1]).to_string().substr(0, 2);
        modEncoding = InstructionHandler::GetModEncoding(mod);

        std::string binaryInstruction = InstructionHandler::GetBinaryInstructionWithModeData(is, modEncoding, parse, location);
        std::cout << binaryInstruction << "\n";

        instructions.push_back(binaryInstruction);
      }
      break;
      case InstructionHandler::OpCode::MOVB:
      {
        std::cout << "MOVB\n";
      }
      break;
      case InstructionHandler::OpCode::MOVC:
      {
        std::cout << "MOVC\n";
        std::string w = std::bitset<8>(parse[0]).to_string().substr(4, 1);
        is.seekg(location);
        is.read(parse, 2);

        if (w == "0")
        {
          location += 2;
          std::string binaryInstruction = std::bitset<16>(std::bitset<8>(parse[0]).to_string() + std::bitset<8>(parse[1]).to_string()).to_string();
          instructions.push_back(binaryInstruction);
        }
        else
        {
          is.read(parse, 3);
          location += 3;

          std::string binaryInstruction = std::bitset<24>(std::bitset<8>(parse[0]).to_string() + std::bitset<8>(parse[1]).to_string() + std::bitset<8>(parse[2]).to_string()).to_string();
          instructions.push_back(binaryInstruction);
        }
      }
      break;
      case InstructionHandler::OpCode::MOVD:
      {
        std::cout << "MOVD\n";
      }
      break;
      case InstructionHandler::OpCode::MOVE:
      {
        std::cout << "MOVE\n";
      }
      break;
      case InstructionHandler::OpCode::MOVF:
      {
        std::cout << "MOVF\n";
      }
      break;
      case InstructionHandler::OpCode::MOVG:
      {
        std::cout << "MOVG\n";
      }
      break;
      default:
      {
        std::cerr << "Opcode not recognized\n";
      }
      break;
      }
    }

    is.close();

    for (int i = 0; i <= instructions.size(); i++)
    {
      std::cout << "Instruction " << i << ": " << instructions[i] << "\n";
    }
    return instructions;
  }

} // namespace Disassembler

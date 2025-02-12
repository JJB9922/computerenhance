#include "disassembler.h"

#include <fstream>
#include <ios>
#include <iostream>
#include <sstream>

namespace Disassembler {

std::string
fromBinaryInstructionGetAssemblyInstruction(const std::bitset<48> &byte) {
  std::string instruction;

  std::string fullOpcode = byte.to_string().substr(0, 8);

  /*
  for (auto const& [key, val] : opcodeFromBinary)
  {
    if(fullOpcode.find(key) != std::string::npos) {
      std::cout << "Opcode Found\n";
      return key;
    }
  }
*/

  std::bitset<6> opcode = std::bitset<6>(byte.to_string().substr(0, 6));
  std::bitset<1> d = std::bitset<1>(byte.to_string().substr(6, 1));
  std::bitset<1> w = std::bitset<1>(byte.to_string().substr(7, 1));

  std::bitset<2> mod = std::bitset<2>(byte.to_string().substr(8, 2));
  std::bitset<3> reg = std::bitset<3>(byte.to_string().substr(10, 3));
  std::bitset<3> rm = std::bitset<3>(byte.to_string().substr(13, 3));

  std::stringstream instStream;

  std::map<std::string, std::string>::const_iterator iter =
      opcodeFromBinary.find(opcode.to_string());

  if (iter != opcodeFromBinary.end()) {
    instStream << iter->second;
  } else {
    std::cerr << "Opcode " << opcode.to_string() << " not found!\n";
  }

  ModEncoding modEncoding = ModEncoding::None;

  if (mod.to_string() == "00") {
    modEncoding = ModEncoding::NoDisplacement;
  } else if (mod.to_string() == "01") {
    modEncoding = ModEncoding::EightBitDisplacement;
  } else if (mod.to_string() == "10") {
    modEncoding = ModEncoding::SixteenBitDisplacement;
  } else if (mod.to_string() == "11") {
    modEncoding = ModEncoding::RegisterMode;
  } else {
    std::cerr << "MOD encoding not found!\n";
  }

  bool regIsSource = (d.to_string() == "0") ? true : false;
  bool opOnWordData = (w.to_string() == "1") ? true : false;

  switch (modEncoding) {
  case ModEncoding::None:
  case ModEncoding::NoDisplacement:
  case ModEncoding::EightBitDisplacement:
  case ModEncoding::SixteenBitDisplacement:
    break;
  case ModEncoding::RegisterMode: {
    std::string registerA;
    std::string registerB;

    if (opOnWordData) {
      std::map<std::string, std::string>::const_iterator iterx =
          regFromBinaryWord.find(reg.to_string());

      if (iterx != regFromBinaryWord.end()) {
        registerA = iterx->second;
      } else {
        std::cerr << "REG register " << rm.to_string() << " not found!\n";
      }

      std::map<std::string, std::string>::const_iterator itery =
          rmFromBinaryWord.find(rm.to_string());

      if (itery != rmFromBinaryWord.end()) {
        registerB = itery->second;
      } else {
        std::cerr << "R/M register " << rm.to_string() << " not found!\n";
      }

    } else {
      std::map<std::string, std::string>::const_iterator iterx =
          regFromBinaryByte.find(reg.to_string());

      if (iterx != regFromBinaryByte.end()) {
        registerA = iterx->second;
      } else {
        std::cerr << "REG register " << rm.to_string() << " not found!\n";
      }

      std::map<std::string, std::string>::const_iterator itery =
          rmFromBinaryByte.find(rm.to_string());

      if (itery != rmFromBinaryWord.end()) {
        registerB = itery->second;
      } else {
        std::cerr << "R/M register " << rm.to_string() << " not found!\n";
      }
    }

    if (regIsSource) {
      instStream << " " << registerB << ", " << registerA;
    } else {
      instStream << " " << registerA << ", " << registerB;
    }

  } break;
  }

  instruction = instStream.str();
  return instruction;
}

std::vector<std::bitset<48>>
fromFileGetBinaryInstructions(const char *filename) {
  std::vector<std::bitset<48>> instructions;
  std::ifstream is(filename, std::ifstream::in);

  is.seekg(0, std::ios_base::end);
  auto lengthInChars = is.tellg();

  for (uint8_t i = 0; i < lengthInChars; i += 2) {
    char c[6];
    is.seekg(i);
    is.read(c, 2);
    std::bitset<48> inst(
        std::bitset<8>(c[0]).to_string() + std::bitset<8>(c[1]).to_string() +
        std::bitset<8>(c[2]).to_string() + std::bitset<8>(c[3]).to_string() +
        std::bitset<8>(c[4]).to_string() + std::bitset<8>(c[5]).to_string());

    std::cout << inst << "\n";
    instructions.push_back(inst);
  }

  is.close();

  return instructions;
}

} // namespace Disassembler

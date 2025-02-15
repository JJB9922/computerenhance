#include <instructionhandler.h>

namespace InstructionHandler {

void handleMOVA() {}

ModEncoding GetModEncoding(const std::string &mod) { return ModEncoding::None; }

std::string GetBinaryInstructionWithModeData(std::ifstream &is,
                                             const ModEncoding &mod,
                                             char (&parse)[6],
                                             uint8_t &location) {
  return std::string();
}
} // namespace InstructionHandler

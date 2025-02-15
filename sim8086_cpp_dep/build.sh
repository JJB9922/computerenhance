#!/bin/bash
set -e  # Exit on error

# Set variables
CXX="clang++"
CXXFLAGS="-std=c++17 -Wall -MMD -MP -I src/include"
SRCDIR="src"
BUILDDIR="build"
TARGET="$BUILDDIR/sim8086"
VERBOSE=false

# Parse arguments
if [[ "$1" == "clean" ]]; then
    echo "Cleaning build directory..."
    rm -rf "$BUILDDIR"
    exit 0
elif [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
    VERBOSE=true
    CXXFLAGS="$CXXFLAGS -v"
fi

# Ensure build directory exists
if ! mkdir -p "$BUILDDIR"; then
    echo "Failed to create build directory: $BUILDDIR"
    exit 1
fi

# Find all source files
SOURCES=$(find "$SRCDIR" -name "*.cpp")

# Get the number of CPU cores (macOS compatible)
NUM_CORES=$(sysctl -n hw.logicalcpu)

# Compile source files in parallel
echo "Compiling source files..."
for file in $SOURCES; do
    obj_file="$BUILDDIR/$(basename "$file" .cpp).o"
    dep_file="$BUILDDIR/$(basename "$file" .cpp).d"
    compile_cmd="$CXX $CXXFLAGS -c \"$file\" -o \"$obj_file\" -MF \"$dep_file\""
    echo "Running compile command: $compile_cmd"
    eval $compile_cmd &
    # Limit the number of parallel jobs to the number of CPU cores
    if [[ $(jobs -r -p | wc -l) -ge $NUM_CORES ]]; then
        wait -n
    fi
done
wait  # Wait for all background jobs to finish

# Link object files
echo "Linking $TARGET..."
link_cmd="$CXX $(find "$BUILDDIR" -name "*.o") -o \"$TARGET\""
echo "Running link command: $link_cmd"
eval $link_cmd

echo "Build complete!"

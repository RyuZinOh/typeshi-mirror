#!/bin/bash
set -e

mkdir -p build
cd build
cmake .. -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . -j $(nproc)
cd ..

ln -sf build/compile_commands.json compile_commands.json
./build/typeshi --nwpm

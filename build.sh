##format

clang-format -i src/*

#configure
cmake -B build/Release -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# build
cmake --build build/Release
##format

clang-format -i src/*

#configure
cmake -B build/Release -DCMAKE_BUILD_TYPE=Release

# build
cmake --build build/Release
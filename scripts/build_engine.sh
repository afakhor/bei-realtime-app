#!/bin/bash
set -e

cd "$(dirname "$0")/../engine"

echo "Building C++ engine..."
mkdir -p ../app/android/app/src/main/jniLibs/arm64-v8a
cmake -B build -G Ninja
cmake --build build

echo "libbei_engine.so copied to Flutter"
ls -lh ../app/android/app/src/main/jniLibs/arm64-v8a/libbei_engine.so

#! /bin/bash
set -e

[[ $0 != 'tools/culture_compiler/refresh.sh' ]] && echo "Must be run as tools/culture_compiler/refresh.sh" && exit

dart pub get

mkdir -p lib/data/cultures

dart tools/culture_compiler/encode_dart.dart tools/culture_compiler/data/cultures.bin lib/data/cultures

dart format lib/data/cultures

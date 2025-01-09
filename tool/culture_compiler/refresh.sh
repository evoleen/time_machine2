#! /bin/bash
set -e

[[ $0 != 'tool/culture_compiler/refresh.sh' ]] && echo "Must be run as tool/culture_compiler/refresh.sh" && exit

dart pub get

mkdir -p lib/data/cultures

dart tool/culture_compiler/encoode_json_to_bin.dart
dart tool/culture_compiler/encode_dart.dart tool/culture_compiler/data/cultures.bin lib/data/cultures

dart format lib/data/cultures

#! /bin/bash
set -e

[[ $0 != 'tool/tzdb_compiler/refresh.sh' ]] && echo "Must be run as tool/tzdb_compiler/refresh.sh" && exit

dart pub get

temp=$(mktemp -d -t tzdata-XXXXXXXXXX)

pushd $temp > /dev/null

echo "Fetching latest database..."
curl https://data.iana.org/time-zones/tzdata-latest.tar.gz | tar -zx

echo "Compiling into zoneinfo files..."
mkdir zoneinfo
make rearguard.zi
zic -d zoneinfo -b fat rearguard.zi

popd > /dev/null

mkdir -p lib/data/tzdb

# Pass the zoneinfo directory to the encoding script
dart tool/tzdb_compiler/encode_tzf.dart --zoneinfo $temp/zoneinfo

xz lib/data/tzdb/latest.tzf
xz lib/data/tzdb/latest_all.tzf
xz lib/data/tzdb/latest_10y.tzf

mv lib/data/tzdb/latest.tzf.xz lib/data/tzdb/latest.tzf
mv lib/data/tzdb/latest_all.tzf.xz lib/data/tzdb/latest_all.tzf
mv lib/data/tzdb/latest_10y.tzf.xz lib/data/tzdb/latest_10y.tzf

rm -r $temp

# Create the source embeddings
for scope in latest latest_all latest_10y; do
  echo "Creating embedding: $scope..."
  dart tool/tzdb_compiler/encode_dart.dart lib/data/tzdb/$scope.{tzf,dart}
done

dart format lib/data/tzdb

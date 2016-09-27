#!/bin/sh
set -e

my_dir="$( cd "$( dirname "${0}" )" && pwd )"

cd ${my_dir}/../docker/web-base
./build-image.sh

cd ${my_dir}/../docker/web
./build-image.sh

cd ${my_dir}/../cli
echo 'Bringing cyber-dojo down'
./cyber-dojo down

echo 'Removing existing start-points'
./cyber-dojo start-point ls --quiet | grep 'languages' && ./cyber-dojo start-point rm languages
./cyber-dojo start-point ls --quiet | grep 'exercises' && ./cyber-dojo start-point rm exercises
./cyber-dojo start-point ls --quiet | grep 'custom'    && ./cyber-dojo start-point rm custom
./cyber-dojo start-point ls

echo 'Recreating new start-points'
./cyber-dojo start-point create languages --dir=./../../start-points-languages
./cyber-dojo start-point create exercises --dir=./../../start-points-exercises
./cyber-dojo start-point create custom    --dir=./../../start-points-custom
./cyber-dojo start-point ls

cd ${my_dir}
./up_test.sh ${*}
done=$?
exit $done
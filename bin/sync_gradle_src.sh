#! /bin/bash

libPath="$HOME/.gradle/src"

rm -rf $libPath
mkdir -p $libPath

for file in $(find ~/.gradle/caches -type f -name '*-sources.jar'); do
  tar -C $libPath -zvxf $file
done

unzip /Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home/src.zip -d $libPath

cd $libPath && git init

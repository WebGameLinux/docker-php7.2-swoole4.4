#!/bin/bash

curDir=$(cd `dirname "$0"`; pwd)

source ./scripts/envs.sh

if [ "${image}" == "x" ];then
    # shellcheck disable=SC2154
    image="hw/php7.2-swoole4.4:v${version}"
fi

docker build -t "${image}"  .  --label=version:"${version}" --build-arg work_dir="${curDir}"

if [ "$?" != "0" ];then
  echo "build failed"
  return
fi

docker tag ${image} ${registry}/${dockerTag}

if [ "$?" != "0" ];then
  echo "tag failed"
  return
fi

docker push ${registry}/${dockerTag}

if [ "$?" != "0" ];then
  echo "push image failed"
  return
fi
#!/bin/bash

curDir=$(cd `dirname "$0"`; pwd)

source ${curDir}/scripts/env.sh

if [ "${image}" == "x" ];then
    # shellcheck disable=SC2154
    image="hw/php7.2-swoole4.4:v${version}"
fi

docker build -t "${image}"  .  --label=version:"${version}" --build-arg work_dir="${curDir}"

ok=$(docker image ls|grep "${image}")

if [ "${ok}" == "x" ];then
  echo "build failed \n"
  exit 1
fi

docker tag ${image} ${registry}/${dockerTag} && docker push ${registry}/${dockerTag}


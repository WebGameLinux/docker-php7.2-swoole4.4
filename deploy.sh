#!/bin/bash
# 上传dockerhub

curDir=$(cd `dirname "$0"`; pwd)
source ${curDir}/scripts/env.sh

docker tag ${image} ${dockerHubTag} && docker push ${dockerHubTag}
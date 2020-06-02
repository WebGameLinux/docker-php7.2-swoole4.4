#!/bin/bash

export  work_user=www
export  http_port=8080
export  version="1.0.0"
export  dockerTag="hw/php7.2-swoole4.4:${version}"
export  image="hw/php7.2-swoole4.4:v${version}"
export  user_dir=/home/www-data
export  app_dir=/data/www/app
export  registry=harbor.word-server.com

if [ -e .env ];then
    source .env
fi

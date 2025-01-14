#!/bin/bash

if [ "$#" -lt 3 ]; then
  echo "Error: Missing command line argument."
  echo 'example: `./test_qps.sh compose-post 2 async`'
  exit 1
fi

IP=130.127.133.219
WRK_BIN=../wrk
WRK_SCRIPT="lua_files/$1.lua"
CLUSTER_ID=$2
DEATHSTARBENCH=/proj/zyuxuanssf-PG0/faas-test/DeathStarBench
WORKLOAD=media_microservice_rust_lite
ENTRY_HOST=http://$IP:30080


if [[ $CLUSTER_ID -eq 2 ]]; then
   ENTRY_HOST=http://$IP:30081 # cluster 2 IP 
elif [[ $CLUSTER_ID -eq 3 ]]; then
   ENTRY_HOST=http://$IP:30081 # cluster 2 IP 
fi

if [ "$3" = "async" ]; then
  WORKLOAD="${WORKLOAD}_async"
fi

OPENFAAS_TEST_DIR=/proj/zyuxuanssf-PG0/faas-test/openfaas-test

#QPS=(20 40 60 80 100 140 180 240 300 400 500 750 1000 1500 2000)
#QPS=(8000 10000 14000 18000 24000 30000)
QPS=(100)

# Iterate over each element in the array
rm -rf *.log
for qps in "${QPS[@]}"; do
  cd $DEATHSTARBENCH/$WORKLOAD/cluster-1 && ./build.sh clean
  cd $DEATHSTARBENCH/$WORKLOAD/cluster-2 && ./build.sh clean
  cd $DEATHSTARBENCH/$WORKLOAD/cluster-3 && ./build.sh clean
  faas-cli remove $1
  faas-cli remove $1 --gateway=localhost:8081
  cd $OPENFAAS_TEST_DIR/setup/redis_memcached \
    && ./build.sh kill \
    && ./build.sh setup
  sleep 30
  cd $DEATHSTARBENCH/$WORKLOAD/cluster-1 && ./build.sh deploy
  cd $DEATHSTARBENCH/$WORKLOAD/cluster-2 && ./build.sh deploy
  faas-cli remove login --gateway=localhost:8081
  cd $DEATHSTARBENCH/$WORKLOAD/cluster-3/compose-review && faas-cli deploy -f deployFunc.yml
  sleep 30
  cd $OPENFAAS_TEST_DIR/wrk2/media_microservice
  ./initialize.sh
  faas-cli remove register-movie-id
  sleep 60
  FUNC_NAME=$1
  FUNC_NAME_OLD="${FUNC_NAME%-merged}"
  if [ "$1" = "compose-review-merged" ]; then
    cd $DEATHSTARBENCH/$WORKLOAD/cluster-3/$FUNC_NAME_OLD && faas-cli deploy -f deployMergedFunc.yml
  else
    cd $DEATHSTARBENCH/$WORKLOAD/cluster-$CLUSTER_ID/$FUNC_NAME_OLD && faas-cli deploy -f deployMergedFunc.yml 
  fi
  sleep 30
  cd $OPENFAAS_TEST_DIR/wrk2/media_microservice
  $WRK_BIN -t 1 -c 5 -d 900 -L -U \
	 -s $WRK_SCRIPT \
	 $ENTRY_HOST -R $qps 2 > /dev/null > output_$1-$3_$qps.log
  echo "===== QPS: $qps ====="
  ./get5099tput.py output_$1-$3_$qps.log
  echo "===================="
  faas-cli remove $1
  faas-cli remove $1 --gateway=localhost:8081
  faas-cli remove $1-merged
  faas-cli remove $1-merged --gateway=localhost:8081
done

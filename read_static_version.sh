#!/bin/bash
ssh 10.96.36.80 "cd /home/nba/nba_game_server/ && git pull && cat  app/config_data_cn/server_config_CN_DEV.js app/config_data_tw/server_config_TW_DEV.js "|grep "_id:" |awk -F "," '{print $1"\t"$2"\t"$22}'

#!/bin/bash
date +%s
ps x|grep FightServer|grep -v grep|awk '{print $1}'|xargs kill -9
for i in {0..9}
do
#	sed -i s/port=.*/port=887$i/g /data/nba/Config.txt
	nohup /data/nba/ServerBuild/FightServer -batchmode -nographics -port 887$i -logfile /data/nba/log/zone887${i}_output_log.txt & 2>&1
done

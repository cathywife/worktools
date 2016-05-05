#单独更新gmtool
sh /nba/server/tools/rsync_code.sh -H nba2_gmtool_and -T and -y yes
sh /nba/server/tools/rsync_code.sh -H nba2_gmtool_ios -T ios -y yes
lsgame -r 'sh /nba/reload_gm.sh' 'gmtoo'

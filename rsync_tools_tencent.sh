chmod +x *.sh
ssh -i /nba/pem/nba2-tencent.pem root@115.159.56.242 "cd /nba/server/tools/ && tar -czvf tools.`date +%s`.tgz *.sh"
scp  -i /nba/pem/nba2-tencent.pem -r *.sh *.js root@115.159.56.242:/nba/server/tools/
ssh -i /nba/pem/nba2-tencent.pem root@115.159.56.242 "cd /nba/server/tools/ && chmod +x *.sh"

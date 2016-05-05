#!/usr/bin/perl -w
#================================================================
#  (C) 2013-2014 Dena Group Holding Limited.
#
#  This program is used to operate the process of
#  login & web server.
#  Please check the options before using.
#
#  Authors:
#    Edison Chow <zhou.liyang@dena.jp>
#================================================================
use warnings;
use strict;
use Net::OpenSSH;
use Getopt::Long;
my @host;
my $service;
my $operate;
my %opt;
my $type;
my @world;
my $port;
my $all;
GetOptions(\%opt,
		'h|help',
		't|type=s',
		'a|all=s',
		's|service=s',
		'o|operate=s',
		'p|port=i',
		'world=s{,}' => \@world,
		'host=s{,}' => \@host
		) or &print_usage();
if (!scalar(%opt) && !scalar(@host))
{
		&print_usage();
}
$opt{'h'} and &print_usage();
$opt{'t'} and $type=$opt{'t'};
$opt{'p'} and $port=$opt{'p'};
$opt{'s'} and $service=$opt{'s'};
$opt{'o'} and $operate=$opt{'o'};
$opt{'a'} and $all=$opt{'a'};
sub print_usage()
{
printf <<EOF;
#================================================================
#  (C) 2013-2014 Dena Group Holding Limited.
#
#  This program is used to operate the process of
#  login & web server.
#  Please check the options before using.
#
#  Authors:
#    Edison Chow <zhou.liyang\@dena.jp>
#================================================================
=================================================================
   -h,--help           Print Help Info.
   -s,--service	       The service you wanna choose.
   -w,--world          The World.
   -t,--type           The Type.
   -p,--port		The port.
   -a,--all            Whether the operations of web server choose all the hosts all not.(yes or no)
                        Only for type=web
   -o,--operate        The Operate you wanna do.
   --host           The Host.You can input one or more host.

Sample :
For GS:
   shell > ./nba.pl  -s gs  -w 1 -t web -o start -a no
For CA:
   shell > ./nba.pl  -s ca  -w 1 -t web -o start -a no
Foe DKS
   shell > ./nba.pl  -s dks  -w 1 -t web -o start -a no
For Login
   shell > ./nba.pl  --host nba_login1 nba_login2 nba_login3  -t login -p 8200 -o start
=================================================================
EOF
exit;
}
#================================================================
#		Function	total
#================================================================
sub total()
{
my $flag;
my $flag1;
my @tmp;
my $t1;
my $t2;
@tmp=@_;
my $host1 = $tmp[0];
$t1=$tmp[1];
$t2=$tmp[2];
my $t3=$tmp[3];
my $t4=$tmp[4];
my $t5=$tmp[5];
my $ssh = Net::OpenSSH->new($host1);
$ssh->error and warn "can not connect to $host1" . $ssh->error;

	if($t4 =~ /^start$/)
	{

		if($t3 =~ /^gs$/)
		{
			print "$host1:"."\n";
			for(my $i=0;$i<$t2;$i++){
				my $pt=$t5+$i;
        			print "World:	$t1"."\n";
				print "Port:	$pt"."\n";
				$ssh->system("/sbin/initctl start gs_8600 PORT=$pt WORLD=$t1 TARGET=0");
				}
        		}
		elsif($t3 =~ /^ca$/)
		{
        		print "$host1:"."\n";
        		$ssh->system("/sbin/initctl start calculation_8400") ;
		}
		elsif($t3 =~ /^dks$/)
                {
                        print "$host1:"."\n";
                        $ssh->system("/sbin/initctl start dks") ;
                }
		else
		{
		print "please check the options"."\n";
		}
	}
	elsif($t4 =~ /^stop$/)
	{
		if($t3 =~ /^gs$/)
		{
        		print "$host1:"."\n";
        	                for(my $i=0;$i<$t2;$i++){
                                my $pt=$t5+$i;
                                print "World:   $t1"."\n";
                                print "Port:    $pt"."\n";
				 $ssh->system("/sbin/initctl stop gs_8600 PORT=$pt WORLD=$t1 TARGET=0");
                                }
		}
		elsif($t3 =~ /^ca$/)
		{
        	print "$host1:"."\n";
        	$ssh->system("/sbin/initctl stop calculation_8400") ;
		}
		elsif($t3 =~ /^dks$/)
                {
                print "$host1:"."\n";
                $ssh->system("/sbin/initctl stop dks") ;
                }
		else
		{
		print "please check the options"."\n";
		}
	}
	elsif($t4 =~ /^restart$/)
	{
		if($t3 =~ /^gs$/)
		{
		        print "$host1:"."\n";
                        for(my $i=0;$i<$t2;$i++){
                                my $pt=$t5+$i;
                                print "World:   $t1"."\n";
                                print "Port:    $pt"."\n";
                                #$ssh->system("/sbin/initctl stop gs_8600 PORT=$pt WORLD=$t1 TARGET=0 && sleep 1 && /sbin/initctl start gs_8600 PORT=$pt WORLD=$t1 TARGET=0");
                               # $ssh->system("/sbin/initctl stop gs_8600 PORT=$pt WORLD=$t1 TARGET=0  ");
                                $ssh->system("ps -ef | grep game_node| grep -v grep | grep $pt| awk '{print \$2}'|xargs kill -9");
                               # $ssh->system("/sbin/initctl start gs_8600 PORT=$pt WORLD=$t1 TARGET=0");

				}
$ssh->system("sleep 2");
       	 	}
		elsif($t3 =~ /^ca$/)
		{
        	print "$host1:"."\n";
        #	$ssh->system("/sbin/initctl stop calculation_8400 && sleep 1 && /sbin/initctl start calculation_8400") ;
		$ssh->system("ps -ef | grep calculation| grep -v grep | grep  usr| awk '{print \$2}'|xargs kill")
		}
		 elsif($t3 =~ /^dks$/)
                {
                print "$host1:"."\n";
                               $ssh->system("ps -ef | grep dks_rival_node| grep -v grep | awk '{print \$2}'|xargs kill")
                                               }
		else
		{
		print "please check the options"."\n";
		}
	}
	else
	{
	printf "please check the options"."\n";
	}
}



sub login(){
my @tmp=@_;
my $host2 = $tmp[0];
my $t1 = $tmp[1];
my $t2 = $tmp[2];
my $ssh = Net::OpenSSH->new($host2);
$ssh->error and warn "can not connect to $host2" . $ssh->error;
if ($t2 == 8300)
{
	if($t1 =~ /^start$/)
	{	printf $host2.":"."\n";
		for(my $j=8301;$j<8311;$j++){
		$ssh->system("initctl start login_8300 PORT=$j TARGET=0") ;
		}
	}
	elsif($t1 =~ /^stop$/)
	{	printf $host2.":"."\n";
		for(my $j=8301;$j<8311;$j++){
                $ssh->system("initctl stop login_8300 PORT=$j TARGET=0") ;
                }
	}
	elsif($t1 =~ /^restart$/)
	{	printf $host2.":"."\n";
		for(my $j=8301;$j<8311;$j++){
                $ssh->system("initctl stop login_8300 PORT=$j TARGET=0 && initctl start login_8300 PORT=$j TARGET=0") ;
                }
	}
	else
	{
	printf "please check the options"."\n";
	}



}
elsif($t2==8200)
{
 if($t1 =~ /^start$/)
        {       printf $host2.":"."\n";
                for(my $j=8201;$j<8211;$j++){
                $ssh->system("initctl start login_8200 PORT=$j TARGET=0") ;
                }
        }
        elsif($t1 =~ /^stop$/)
        {       printf $host2.":"."\n";
                for(my $j=8201;$j<8211;$j++){
                $ssh->system("initctl stop login_8200 PORT=$j TARGET=0") ;
                }
        }
        elsif($t1 =~ /^restart$/)
        {       printf $host2.":"."\n";
                for(my $j=8201;$j<8211;$j++){
               # $ssh->system("initctl stop login_8200 PORT=$j TARGET=0 && sleep 1 && initctl start login_8200 PORT=$j TARGET=0") ;
                $ssh->system("ps -ef | grep provision| grep 82|awk '{print \$2}' |xargs kill");
	#	$ssh->system("ps -ef | grep provision| grep 82");
	}
        }
        else
        {
        printf "please check the options"."\n";
        }


}
elsif($t2==8100)
{
 if($t1 =~ /^start$/)
        {       printf $host2.":"."\n";
                $ssh->system("initctl start login_8100 PORT=8101 TARGET=3") ;
        }
        elsif($t1 =~ /^stop$/)
        {       printf $host2.":"."\n";
                $ssh->system("initctl stop login_8100 PORT=8101 TARGET=3") ;
        }
        elsif($t1 =~ /^restart$/)
        {       printf $host2.":"."\n";
                #$ssh->system("initctl stop login_8100 PORT=8101 TARGET=3 && initctl start login_8100 PORT=8101 TARGET=3") ;
		$ssh->system("ps -ef | grep provision| grep 8100|awk '{print \$2}' |xargs kill") ;
		 $ssh->system("ps -ef | grep provision| grep 81");
	 }
        else
        {
        printf "please check the options"."\n";
        }


}

elsif($t2==8150)
{
 if($t1 =~ /^start$/)
        {       printf $host2.":"."\n";
                $ssh->system("initctl start login_8150 PORT=8150 TARGET=0") ;
        }
        elsif($t1 =~ /^stop$/)
        {       printf $host2.":"."\n";
                $ssh->system("initctl stop login_8150 PORT=8150 TARGET=0") ;
        }
        elsif($t1 =~ /^restart$/)
        {       printf $host2.":"."\n";
                $ssh->system("initctl stop login_8150 PORT=8150 TARGET=0 && initctl start login_8150 PORT=8150 TARGET=0") ;
        }
        else
        {
        printf "please check the options"."\n";
        }


}
}
#================================================================
#               Function main
#================================================================
sub main()
{
if($type =~ /^web$/){
if($all =~ /^no$/){
	for (my $i=0;$i<scalar(@world);$i++)
	{
                 print "$world[$i] 区："."\n";
                my @hhh=`cat /nba/server/server_$world[$i]|grep -v "#" |cut -f 1`;
                my @wd=`cat /nba/server/server_$world[$i] |grep -v "#" |cut -f 2`;
                my @pp=`cat /nba/server/server_$world[$i] |grep -v "#" |cut -f 3`;
                my @p1=`cat /nba/server/server_$world[$i]|grep -v "#" |cut -f 4`;
		for (my $j=0;$j<scalar(@hhh);$j++)
		{
		chomp($hhh[$j]);
		chomp($wd[$j]);
		chomp($pp[$j]);
                chomp($p1[$j]);
		&total("$hhh[$j]","$wd[$j]","$pp[$j]","$service","$operate","$p1[$j]");
		}
	}
}
elsif($all =~ /^yes$/){
                my @hhh=`cat /nba/server/server_*|grep -v "#" |cut -f 1`;
                my @wd=`cat /nba/server/server_*|grep -v "#" |cut -f 2`;
                my @pp=`cat /nba/server/server_*|grep -v "#" |cut -f 3`;
		my @p1=`cat /nba/server/server_*|grep -v "#" |cut -f 4`;
                for (my $j=0;$j<scalar(@hhh);$j++)
                {
                chomp($hhh[$j]);
                chomp($wd[$j]);
                chomp($pp[$j]);
		chomp($p1[$j]);
       		print "$wd[$j]区："."\n";
                &total("$hhh[$j]","$wd[$j]","$pp[$j]","$service","$operate","$p1[$j]");
                }
}
}
elsif($type =~ /^login$/){
for (my $i=0;$i<scalar(@host);$i++){
               &login("$host[$i]","$operate","$port");

}

}
}
&main();

# Scripts that automate ITM installation and configuration, work on both linux and AIX platform

Those scripts are proved to be able to greately prove productivity in my cooperation, and greately reduced work load.

1. config_or_linux0aix.sh - discover oracle instance automatically, and then automatically configure ITCAM for oracle. 

It has below features:
1) One script to do all: it will detect oracle databse instance name, and config them automatically without any interaction, as long as those instances has same monitor user and canonical TNS definition (which is true in a DC)
2) Able to detect already configured instances, and avoid duplicated config.
3) Able to detect oracle dataguard, and will skip it.



Usage:
1) Automaticlly find all oracle database instances, and config ITM Agent to monitor them, with TNS=tivoli_INSTANCENAME, User=tivoli, Pass=XXXX
	./config_or_linux.sh
2) Config a chosen oracle instance, with specified TNS,User and Pass, this is used for some special instances whose TNS,User/Pass is special.
	./config_or_linux.sh -s TNS -u User -p Pass Instance1
	
	TNS:  Optional. TNS string to connect to instance, if not specifed, the script will prefix tivoli(e.g: tivoli_INSTANCENAME) as TNS string. 
	User:  optional. User that ITM Agent will use to connect to oracle instaces to be monitored. if not specified, use hard-coded username.
	Pass:	Password for User, optional
	Instance1:	Instances to be configured and monitored

2. config_dc_linux0aix - discover IBM WAS (Websphere Application Server) servers and configure ITM data collector automatically. 

Usage:
	./config_dc_linux0aix.sh -u AdminUser -p AdminPass -n SoapPort Server1 Server2
	
	AdminUser： optional, the WAS dmgr admin user name
	AdminPass:	optional, password for AdminUser
	SoapPort:	optional, WAS SOAP port, if ommited, will discover from server.xml
	Server1, Server2: optional, server list, if ommited, will discover from WAS configuration home.

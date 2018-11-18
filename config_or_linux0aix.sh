curdir=`cd $(dirname $0) && pwd`
. /home/oracle/.profile >/dev/null

User=tivoli
Pass=****
SIDs=`ps -ef|grep pmon|grep -v grep|grep -v '+ASM'|awk '{print $NF}'|awk -F'_' '{print $NF}'`

##########################################################################
###                  Get install parameters                            ### 
##########################################################################
while getopts "s:u:p:" opt; do
case $opt in
        s) Tns=$OPTARG;;
        u) User=$OPTARG;;
        p) Pass=$OPTARG;;
        ?) echo "Usage: ./config_or_linux.sh -s TNS -u User -p Pass Instance1"
        exit 1;;
esac
done

shift $(($OPTIND - 1))
Target=$*;

##########################################################################
###                  Check if parameter is valid                       ### 
##########################################################################

# The target specified must be a valid SID 
if [ -z "$Target" ]; then
    Target=$SIDs
else
    for i in `echo $Target`; do
        echo $SIDs|grep -w $i >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "The Instance $i you specified doesnot exist, exiting!"
        exit;
        fi
    done
fi

# if TNS is specified, then only 1 instance can be configured
if [ -z "$Tns" ]; then
    userTNS=0;
else
    userTNS=1;
    num=`echo "$Target" | wc -w`
    if [ $num -ge 2 ];then
        echo "You can only config 1 instance at a time if you specify a TNS, exiting"
        exit
    fi
fi

##########################################################################
###                  Judge if database env is ready                    ### 
##########################################################################
# Check it is a primary instance
ps -ef|grep pmon|grep mrp >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Standby database, exiting..."
    exit
fi

# For each instance, check tns,users are all ready
for i in `echo $Target`;do
    # if user hasnot specify TNS, use tivoli_InsName as TNS
    if [ $userTNS -eq 0 ]; then
        Tns=`echo $i|sed 's/^/tivoli_/g'`
    fi

    # check TNS ready
    if [ `echo -n "$Tns"|wc -c` -gt 15 ]; then
        echo "The TNS $Tns for instance $i exceed the max len (15chars)";
        exit; 
    fi
 
    tnsping $Tns | grep "Failed to resolve name" >/dev/null 2>&1
    if [ $? -eq 0 ];then
        echo "The $Tns cannot be reached! please check tnsnames.ora config!"
        exit;
    fi

    #check user and previlege ready
    sqlplus -S $User/$Pass@$Tns >/dev/null <<EOF
    spool $curdir/sql_8888.log
    SET ECHO OFF
    SET HEADING OFF
    SET FEEDBACK OFF
    select INSTANCE_NAME from v\$INSTANCE;
    spool off
    exit
EOF

    cat $curdir/sql_8888.log
    cat $curdir/sql_8888.log 2>/dev/null|grep $i >/dev/null 2>&1
    if [ $? -ne 0 ];then
        echo "User $User with Pass $Pass for instance $i not exist or not granted, exiting!"
        exit
    fi
    rm $curdir/sql_8888.log

done

##########################################################################
###                  start configuration                               ### 
##########################################################################
#  
for i in `echo $Target`;do
    # Judge if the instance has been configured before
    grep "CONFIGSUCCESS" /TIVOLI/IBM/ITM/config/`hostname`_or_$i.cfg >/dev/null 2>&1
    if [ $? -eq 0 ];then
        echo "###  $i already configured, do you want to skip it(yes/no)?  "
        read skip;
        if [ "$skip" = "yes" ]; then
            echo "Skipping configuration process for $i"
            continue;
        fi
    fi 

    if [ $userTNS -eq 0 ];then
        Tns=`echo $i|sed 's/^/tivoli_/g'`
    fi

    # The real configuration process
    echo "Configuration for $i started: (User=$User, Pass=$Pass, Tns=$Tns)"
    /TIVOLI/IBM/ITM/bin/CandleDBConfig -s $i -i $User@$Tns -p $Pass or

    # to Check configuration successful
    grep "CONFIGSUCCESS" /TIVOLI/IBM/ITM/config/`hostname`_or_$i.cfg >/dev/null 2>&1
    if [ $? -eq 0 ];then
        echo "Configuration for $i successfully !"
    fi 

done

homeDir=`dirname $0`
######## 0) Pre-condition : node agent needs Running ##############
refargs=`ps -ef|grep java|grep nodeagent|grep -v "grep"`

#######  1) Determine ProfileHome, etc, ###########################
ProfileHome=`echo $refargs|awk '{print $(NF-3)}'|sed 's_/config__'`
CellName=`echo $refargs|awk '{print $(NF-2)}'`
NodeName=`echo $refargs|awk '{print $(NF-1)}'`
WasHome=`echo $ProfileHome|sed 's_/profiles/.*__'`
ProfileName=`echo $ProfileHome|awk -F'/' '{print $NF}'`

#######  2) Fix out DM IP   ################################
DmgrName=`echo $CellName|sed 's/Cell[0-9]*$//'`
DmgrIP=`cat /etc/hosts|grep "$DmgrName"|grep -v "^#"|head -1|awk '{print $1}'`


#######  3) Try to fix out SOAP Port ###################
XmlFile=`find $ProfileHome/config -name "serverindex.xml"|grep $CellName|grep -v $NodeName|grep Manager`
tmpno=`cat $XmlFile | grep -n SOAP_CONNECTOR_ADDRESS | awk -F: '{print $1}'`;
tmpno=`expr $tmpno + 1`
SoapPort=`cat  $XmlFile|sed -n ${tmpno}p| sed 's/.*port="\(.*\)".*/\1/'`

######   4) DM admin Username and Password ###############
AdminUser=wasadm;
AdminPass=****;

while getopts "u:p:n:" opt; do
case $opt in
        u) AdminUser=$OPTARG;;
        p) AdminPass=$OPTARG;;
        n) SoapPort=$OPTARG;;
        ?) echo "Parameter Error!"
        exit 1;;
esac
done

shift $(($OPTIND - 1))

########  5) What Servers to Config #####################
if [ -z "$*" ]; then
servers=`ls $ProfileHome/config/cells/$CellName/nodes/$NodeName/servers|grep -v "nodeagent"`
else
servers="$*";
fi

ServersConfigured=""
for i in `echo $servers`; do
    grep "TIVOLI" $ProfileHome/config/cells/$CellName/nodes/$NodeName/servers/$i/server.xml>/dev/null 2>&1
    if [ $? -eq 0 ]; then
        ServersConfigured="$ServersConfigured $i"
    fi
done
if [ -n "$ServersConfigured" ]; then
    echo "You choose to configure ["$servers"], But we found that ["$ServersConfigured"] are already configured"
    echo "Are you sure to continue? (yes/no)"
    read reply
    if [ "$reply" = "no" ]; then
        echo "exiting...";exit;
    fi 
fi

ServerName=`echo $servers | sed -e "s/^/$NodeName/" -e "s/ /,$NodeName/g"`
ServerPath=`echo $servers | sed -e "s#^#cells/$CellName/nodes/$NodeName/servers/#" -e "s_ _,cells/$CellName/nodes/$NodeName/servers/_g"`

########  6) Generate response file   #####################
cat ${homeDir}/template/config_dc_template.txt |
        sed -e "s%#ProfileHome#%$ProfileHome%" \
            -e "s%#DmgrIP#%$DmgrIP%" \
            -e "s%#AdminUser#%$AdminUser%" \
            -e "s%#AdminPass#%$AdminPass%" \
            -e "s%#SoapPort#%$SoapPort%" \
            -e "s%#ServerName#%$ServerName%" \
            -e "s%#ProfileName#%$ProfileName%" \
            -e "s%#WasHome#%$WasHome%" \
            -e "s%#ServerPath#%$ServerPath%" >${homeDir}/response/config_dc.txt

#######   7) Start to Config  #############################
OSUser=`echo $refargs|awk '{print $1}'`
id | grep $OSUser >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "User not correct"
    exit -1
fi
/TIVOLI/IBM/ITM/bin/itmcmd config -A -p ${homeDir}/response/config_dc.txt yn


#######   8) Check if the configuring process correct! ###########
for i in `echo $servers`; do
    grep "TIVOLI" $ProfileHome/config/cells/$CellName/nodes/$NodeName/servers/$i/server.xml>/dev/null 2>&1
    if [ $? -eq 0 ]
    then
        echo DC config for server $i Success
    else
        echo DC config for server $i Failed
    fi
done

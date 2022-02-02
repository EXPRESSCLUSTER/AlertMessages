#! /bin/sh
#***************************************************************
#*                    alertDestEdit.sh                         *
#* This is a tool to set Alert Destination setting onclp.conf. *
#* Target varsion is EXPRESCLUSTER X 4.                        *
#***************************************************************

#ulimit -s unlimited

confPath="./clp.conf"
alertListPath="./alertList_original.csv"


#**********************
#* Do not edit below  *
#**********************

clusterDirectory="/opt/nec/clusterpro"
alertSettingPath="//root/cluster/messages/use"  #xml path of Alert Setting Enable
snmpServerPath="//root/cluster/trap"            #xml path of SNMP Server
alertMessagePath="//root/messages"              #xml path of Alert Setting
alertSettingFrag=0
snmpServerFrag=0
alertMessageStartLine=0  #The head line number of //root/messages ("<messages>") 
alertMessageEndLine=0    #The last line number of //root/messages ("</messages>")
endLine=0                #The last line number of //root ("</root>")
count=0
path="/"

columns=(1 3 8 7 9 10 0 0)   # Alert list column numbers of module type, event id, syslog, alert, mail, trap, snmp, pubsub(0), alertexec(0)
tags=("syslog" "alert" "mail" "trap" "pubsub" "alertexec")   # xmls tags which are required for alert message setting

# Check current directory
current=$(cd $(dirname $0); pwd)
echo $current | grep $clusterDirectory
if [ $? -eq 0 ];
then
  echo "Error! Here is a cluster directory (/opt/nec/clusterpro)."
  echo "  -> You can not edit clp.conf on running cluster directory. Move to another directory."
  exit 1
fi

# Check alert list
result=`ls $alertListPath`
if [ $? -ne 0 ];
then
  echo "Error! $alertListPath does not exist:"
  echo " $result"
  exit 1
fi

# Check clp.conf path and take its backup
result=`ls $confPath`
if [ $? -ne 0 ];
then
  echo "Error! $confPath does not exist:"
  echo " $result"
  exit 1
fi
echo "Info: $confPath found."
echo "  -> Create backup: ${confPath}.org"
cp $confPath ${confPath}.org

# Check clp.conf
# Function to add xml path
add_path () {
  value=`echo $2 | sed 's/<//g' | sed 's/>//g'`
  echo "$1/$value"
}

# Fuction to remove xml path
remove_path () {
  value=`echo $2 | sed 's/<\///g' | sed 's/>//g'`
  echo `echo $1 | sed "s/\/$value//g"`
}

# Read clp.conf (xml)
while read line
do
  count=$(expr $count + 1)
  text=`echo $line | sed 's/ //g'`

  case "$text" in
  "<root>")
    path=`add_path $path $text`
    ;;
  "<cluster>")
    path=`add_path $path $text`
    ;;
  "</cluster>")
    path=`remove_path $path $text`
    ;;
  "<trap>")
    if [ "${path}/trap" = "$snmpServerPath" ];
    then
      snmpServerFrag=1
    fi
    ;;
  "<messages>")
    path=`add_path $path $text`
    if [ "$path" = "$alertMessagePath" ];
    then
      alertMessageStartLine=$count
    fi
    ;;
  "</messages>")
    if [ "$path" = "$alertMessagePath" ];
    then
      alertMessageEndLine=$count
    fi
    path=`remove_path $path $text`
    ;;
  "<use>1</use>")
    if [ "${path}/use" = "$alertSettingPath" ];
    then
      alertSettingFrag=1
    fi
    ;;
  esac
done < $confPath

endLine=`grep -e "</root>" -n $confPath | awk -F: '{print $1}'`
#echo "alertSetting: $alertSettingFrag"
#echo "snmpServer: $snmpServerFrag"
#echo "alertMessage: $alertMessageStartLine - $alertMessageEndLine"
#echo "endLine: $endLine"

# Check whether Alert Setting is enabled.
if [ $alertSettingFrag -eq 0 ];
then
  echo "Warning! Alert Setting is not enabled."
  echo "  -> Enable Alert Setting on Cluster WebUI before applying cluster configuration."
fi

# Check whether SNMP Server information is set.
if [ $snmpServerFrag -eq 0 ];
then
  echo "Warning! SNMP Server info is not set."
  echo "  -> Set SNMP Server info on Cluster WebUI before applying cluster configuration."
fi

# Remove existing Alert Settings.
# If no alert settings are added, add //root/messages path.
if [ $alertMessageStartLine -ne 0 ];
then
  diff=$((alertMessageEndLine - alertMessageStartLine))
  if [ $diff -lt 1 ];
  then
    echo "Error! Current clp.conf is not valid."
    exit 1
  elif [ $diff -gt 1 ];
  then
    sed -i -e ''$((alertMessageStartLine + 1))','$((alertMessageEndLine - 1))'d' $confPath
  fi
else
  alertMessageStartLine=$endLine
  sed -i -e ''$alertMessageStartLine'i  <messages>\n  </messages>' $confPath
fi

# Check Alert List
# Function to read alert list (csv)
read_alertlist () {
  type=$2
  if [ $type -eq 0 ];
  then
    echo ""
  else
    echo `echo $1 | awk -F, '{i='$type';print $i}'`
  fi
}

# Read alert list (csv) and add alert setting to clp.conf.
count=0
added=0
types=()
while read line
do
  count=$(expr $count + 1)
  params=()
  text=""

  # Check return code
  line=`echo $line | sed 's/\r//g'`

  # Read alert list and set each parameters in params[]
  for column in "${columns[@]}"
  do
    params=("${params[@]}" "`read_alertlist "$line" $column`")
  done

  # Check module type (params[0])
  if [ "${params[0]}" = "" ];
  then
    echo "Info: Skip line $count for invalid Module Type."
    continue 
  elif [ "${params[0]}" = "Module type" ];
  then
    echo "Info: Skip line $count for header line."
    continue
  fi

  # Check event ID (params[1])
  if [ "${params[1]}" = "" ] || [ $((params[1])) -le 0 ];
  then
    echo "Info: Skip line $count for invalid Event ID."
    continue
  fi

  # Check syslog, alert, mail, trap, subpub, rexec parameter (params[2]-[5])
  for i in 2 3 4 5 6 7
  do
    if [ "${params[$i]}" != "" ] && [ -n "${params[$i]}" ];
    then
      params[$i]="1"
    else
      params[$i]="0"
    fi
  done

  # Create xml text
  text="    <${params[0]} id=\"${params[1]}\">\n"

  c=2
  for tag in "${tags[@]}"
  do
    text=$text"      <$tag>${params[$c]}</$tag>\n"
    c=$(expr $c + 1)
  done

  text=$text"    </${params[0]}>"

  # Add text to clp.conf
  sed -i -e "${alertMessageStartLine}a${text}" $confPath
  if [ $? -ne 0 ];
  then
    echo "Info: Skip line $count for adding alert message setting failure."
  else
    added=$(expr $added + 1)
  fi

  # Add types name to types[]
  typeFrag=0
  for type in "${types[@]}"
  do
    if [ "$type" = "${params[0]}" ];
    then
      typeFrag=1
      break
    fi
  done
  if [ $typeFrag -eq 0 ];
  then
    types=("${types[@]}" ${params[0]})
  fi

done < $alertListPath

# Create xml text (module types)
text=""
for t in "${types[@]}"
do
  text=$text"    <types name=\"${t}\"/>\n"
done
sed -i -e "${alertMessageStartLine}a${text}" $confPath
if [ $? -ne 0 ];
then
  echo "Info: Skip line $count for adding alert message setting failure."
fi

echo "Finish! $added alert messages are added to $confPath"

exit 0

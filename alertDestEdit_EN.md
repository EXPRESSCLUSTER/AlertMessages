# EXPRESSCLUSTER alert destination setting tool
## Overview
This is a tool for EXPRESSCLUSTER X 4 to add alert destination settings to cluster configuration (clp.conf).

## Files of this tool
- [alertDestEdit.sh](https://github.com/EXPRESSCLUSTER/AlertMessages/blob/main/script/alertDestEdit.sh)
	- This is a script to add alert destination settings to cluster configuration (clp.conf) according to alert destination list file.
- Alert destination list file
	- In this file, alert destination are defined.
	- This file should be CSV, Comma-Separated Values.
	- About the details, refer [How to create alert destination list file](https://github.com/EXPRESSCLUSTER/AlertMessages/new/main#how-to-create-alert-destination-list-file).

## Target EXPRESSCLUSTER version
- EXPRESSCLUSTER X4 for Linux

## Notes
- This tool edit only alert destination settings, does not edit alert service settings (*).  
	Therefore, Alert Service should be enabled and any other required settings (such as mail server or SNMP server setting) should be configured in advance.
	- * Alert destination setting and alert service setting
		- Alert destination setting: Cluster Properties -> [Alert Service] tab -> [Edit] button
		- Alert destination service setting: Cluster Properties -> [Alert Service] tab
- If alert destination settings are configured on cluster configuration (clp.conf), it will be over-written by executing this tool.
- Alert destination list file should be described properly.
	- About description, refer [How to create alert destination list file](https://github.com/EXPRESSCLUSTER/AlertMessages/new/main#how-to-create-alert-destination-list-file).

## How to use
1. On primary cluster server, create tmp directory (e.g. /tmp) and copy this tool and alert destination list file (e.g. alerDestList.csv):
	```bat
	e.g.)
	/tmp/alertDestEdit.sh
	/tmp/alertDestList.csv
	```
	- Note: Do not create the directory under "/opt/nec/clusterpro".

1. Specify alert list file path and name as "alertListPath" in alertMessageEdit.sh:
	```bat
	<before>
	alertListPath="./alertListDest_original.csv"
	<after>
	alertListPath="./alertListDest.csv"
	```
1. Copy current cluster configuration (clp.conf) to the same directory:
	```bat
	# cp /opt/nec/clusterpro/etc/clp.conf /tmp/clp.conf
	```
1. Execute alertMessageEdit.sh and re-write alert destination setting on clp.conf:  
	```bat
	# sh ./alertMessageEdit.sh
	```
	- After execution, the following files are created:
		```bat
		/tmp/clp.conf		Cluster configuration after re-write alert destination setting
		/tmp/clp.conf.org	Cluster configuration before re-write alert destination setting (Backup)
		```
1. Apply the cluster configuration:
	```bat
	# clpcl --suspend -a
	# clpcfctrl --push -l -x /tmp
	# clpcl --resume -a
	```
	- Cluster suspend and resume are required to applying alert destination setting.

## How to roll-back cluster configuration
1. Remove cluster configuration after re-write alert destination setting in tmp directory:
	```bat
	# rm /tmp/clp.conf
	```
1. Rename backup cluster configuration:
	```bat
	# mv /tmp/clp.conf.org /tmp/clp.conf
	```
1. Apply the configuration:
	```bat
	# clpcl --suspend -a
	# clpcfctrl --push -l -x /tmp
	# clpcl --resume -a
	```
## How to create alert destination list file
- Alert destination list file should be CSV, Comma-Separated Values, format file.
- In each line, alert message and its destination should be described as follows:
	|Module type|Event type|Event ID|Message|Description|Solution|alert|syslog|mail|SNMP Trap|
	|:--|:--|:--|:--|:--|:--|:--|:--|:--|:--|
	|Module type1|Event type1|Event ID1|Message1|Description1|Solution1|alert1|syslog1|mail1|SNMP Trap1|
	|Module type2|Event type2|Event ID2|Message2|Description2|Solution2|alert2|syslog2|mail2|SNMP Trap2|
	|:|:|:|:|:|:|:|:|:|:|
	- Module type, Event ID columns
		- Describe with referring [EXPRESSCLUSTER X for Linux Reference Guide messages list](https://docs.nec.co.jp/sites/default/files/minisite/static/09fe37c6-42ac-47c2-a2a9-93b4b24cc229/ecx_x42_linux_en/L42_RG_EN/L_RG_10.html#messages-reported-by-syslog-alert-mail-and-snmp-trap).
			- You cannot describe other than alert messages in the list.
			- In the case that 2 module types are described in one line (e.g. rm and mm are described in one line as "rm / mm"), you need to separate it to 2 lines in alert destination list file.
	- Event type, Message, Description, Solution column:
		- Don't use "," (comma).
	- Alert, syslog, mail, SNMP Trap column:
		- Describe as follows:
			- In order to set it as alert destination: Set "1"
			- In order not to set it as alert destination: Leave it as blank
- Default alert destination list files:
	- [X4.2 default list](https://github.com/EXPRESSCLUSTER/AlertMessages/blob/main/csv/X42_alertDestList_org.csv)
		- To avoid type, we recommend to edit X4.2 default list than create a new file.
			- You can remove lines which you don't change setting from default.
			- Do not edit other columns than syslog, alert, mail, trap.
			- In syslog, alert, mail, trap columns, do not set character other than "1" if you want to make it as alert destination.
			- When you save alert destination list file, do not set other character than comma for separating values.


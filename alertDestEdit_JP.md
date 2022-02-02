# EXPRESSCLUSTER アラート送信先一括設定ツール
## 概要
EXPRESSCLUSTER X4 Linux 環境向けクラスタ構成情報 (clp.conf) のアラート送信先を一括設定するツールです。

## 必要なファイル
- [alertDestEdit.sh](https://github.com/EXPRESSCLUSTER/AlertMessages/tree/main/script)
	- 本ツールです。アラート送信先定義ファイルの内容に従って、クラスタ構成情報にアラート送信先を一括設定します。
- アラート送信先定義ファイル
	- 設定したいアラート送信先が定義されているファイルです。カンマ区切りの csv 形式である必要があります。
	- 詳細は[アラート送信先定義ファイルの編集](https://github.com/EXPRESSCLUSTER/AlertMessages/new/main#%E3%82%A2%E3%83%A9%E3%83%BC%E3%83%88%E9%80%81%E4%BF%A1%E5%85%88%E5%AE%9A%E7%BE%A9%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%81%AE%E7%B7%A8%E9%9B%86)を参照ください。

## 対象バージョン
- EXPRESSCLUSTER X4 for Linux

## 注意事項
- 本ツールではアラート送信先のみを一括設定します。アラートサービスの設定は変更しません。(*)  
	そのため、アラートサービスの有効化や SNMP サーバは事前に設定されている必要があります。
	- * アラート送信先の設定とアラートサービスの設定
		- アラート送信先の設定： Cluster Properties -> Alert Service タブ -> Edit ボタン
		- アラートサービスの設定： Cluster Properties -> Alert Service タブ
- 既に設定されているアラート送信先は、本ツールを実行すると上書きされます。
- アラート送信先定義ファイルは正しいフォーマットである必要があります。  
	編集方法についてはや編集時の注意事項については[アラート送信先定義ファイルの編集](https://github.com/EXPRESSCLUSTER/AlertMessages/new/main#%E3%82%A2%E3%83%A9%E3%83%BC%E3%83%88%E9%80%81%E4%BF%A1%E5%85%88%E5%AE%9A%E7%BE%A9%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%81%AE%E7%B7%A8%E9%9B%86)を参照ください。

## 使い方
1. クラスタサーバに tmp フォルダを作り（例： /tmp）、本ツールとアラート送信先定義ファイル (alertDestList.csv) を置きます：  
	```bat
	例：
	/tmp/alertDestEdit.sh
	/tmp/alertDestList.csv
	```
	- /opt/nec/clusterpro 配下には置かないでください。

1. alertMessageEdit.sh の alertListPath で定義ファイルを指定します：  
	```bat
	alertListPath="./alertListDest_original.csv"
	↓
	alertListPath="./alertListDest.csv"
	```
1. 今のクラスタ構成ファイルを同じフォルダにコピーしてください：  
	```bat
	# cp /opt/nec/clusterpro/etc/clp.conf /tmp/clp.conf
	```
1. alertMessageEdit.sh を実行して、定義ファイル内の設定を clp.conf に上書きします：  
	```bat
	# sh ./alertMessageEdit.sh
	```
	- 実行後、以下のファイルができます：  
		```bat
		/tmp/clp.conf     	アラート送信先設定上書き後の構成ファイル
		/tmp/clp.conf.org	アラート送信先設定上書き前の構成ファイル（バックアップ）
		```
1. 構成ファイルをクラスタに反映します：  
	```bat
	# clpcl --suspend -a
	# clpcfctrl --push -l -x /tmp
	# clpcl --resume -a
	```
	- アラート送信先設定変更の構成反映にはクラスタのサスペンド・リジュームが必要になります。

## 元の構成に戻したい場合
1. tmp フォルダのメッセージ追加後の構成ファイルを削除します：  
	```bat
	# rm /tmp/clp.conf
	```
1. バックアップファイルのファイル名を変更します：  
	```bat
	# mv /tmp/clp.conf.org /tmp/clp.conf
	```
1. 反映します：  
	```bat
	# clpcl --suspend -a
	# clpcfctrl --push -l -x /tmp
	# clpcl --resume -a
	```
## アラート送信先定義ファイルの編集
- アラート送信先定義ファイルは , (カンマ) 区切りの csv ファイルになります。
- 各行にアラートメッセージとその送信先が、以下の通り定義されている必要があります。  
	|Module type|Event type|Event ID|Message|Description|Solution|alert|syslog|mail|SNMP Trap|
	|:--|:--|:--|:--|:--|:--|:--|:--|:--|:--|
	|Module type1|Event type1|Event ID1|Message1|Description1|Solution1|alert1|syslog1|mail1|SNMP Trap1|
	|Module type2|Event type2|Event ID2|Message2|Description2|Solution2|alert2|syslog2|mail2|SNMP Trap2|
	|:|:|:|:|:|:|:|:|:|:|
	- Module type, Event ID 列
		- リファレンスガイドの[メッセージ一覧表](https://docs.nec.co.jp/sites/default/files/minisite/static/09fe37c6-42ac-47c2-a2a9-93b4b24cc229/ecx_x42_linux_en/L42_RG_EN/L_RG_10.html#messages-reported-by-syslog-alert-mail-and-snmp-trap)を参照して、記載してください。
			- 一覧表にないものを定義することはできません。
			- Module type について、メッセージ一覧表内で "rm / mm" のように 2 つのモジュールが 1 行にまとめて記載されてる場合、アラート送信先定義ファイル内では 2 行に分けて記載する必要があります。
	- Event type, Message, Description, Solution 列
		- , (カンマ) を入力しないでください。
	- alert, syslog, mail, SNMP Trap 列
		- 以下の通りに記載してください：
			- アラートメッセージを送信する: 1
			- アラートメッセージを送信しない: 空欄
- 規定値と同等のアラート送信先定義ファイルはこちらです：
	- [X4.2 規定値](https://github.com/EXPRESSCLUSTER/AlertMessages/blob/main/csv/X42_alertDestList_org.csv)
		- アラート送信先定義ファイルの誤記を防ぐために、新規作成するより規定値ファイルを編集することを推奨します。
			- 規定値のままでいいメッセージについては、行をそのまま削除してください。
			- syslog, alert, mail, trap 列以外は編集しないでください。
			- syslog, alert, mail, trap 列に 1 か空欄以外の文字列を入力しないでください。
			- 編集後、, (カンマ) 以外の区切り文字で保存しないでください。

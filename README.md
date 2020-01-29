# orderdemo

*N O T I C E  
This software is not supported by InterSystems as part of any released product.  It is supplied by InterSystems as a demo/test tool for a specific product and version.  The user or customer is fully responsible for the maintenance of this software after delivery, and InterSystems shall bear no responsibility nor liabilities for errors or misuse of this software.

# 使用するコンテナイメージ
下記のイメージを使用する。ビルドは各々、個別のレポジトリにてbuild.shを実行。

|GitHubレポジトリ名| イメージ名| 用途| メモリ設定| 
----|----|----|----
|whdemo-wsdemo| wsdemo	(環境制御機能)|	自動|
|whdemo-wshq|	wshq|	(本部機能)|	自動|
|whdemo-wsdc|	wsdc|	(WH機能)|	自動|
|whdemo-maker| 	maker|	(メーカー機能)|	自動|

下記のIRIS'ユーザが追加される。  
appuser 


# 事前準備
docker-compose.ymを環境に合わせて変更する事。
IRISアカウントの初期パスワード設定ファイルの場所。
```
secrets:
  password:
    # change here depending on your environment
    file:  /host_mnt/c/temp/password.txt
```

ライセンスキー指定(ECP使用のため必要)。
```
    command: --password-file /run/secrets/password --key /ISC/iris-docker.key

    volumes:
    - /host_mnt/c/InterSystems/licsense:/ISC
```

# 起動方法
```
# docker-compose up -d
# docker-compose ps
WARNING: The COMMIT_ID variable is not set. Defaulting to a blank string.
 Name               Command                  State                            Ports
---------------------------------------------------------------------------------------------------------
maker    /iris-main --password-file ...   Up (healthy)   0.0.0.0:9107->51773/tcp, 0.0.0.0:9207->52773/tcp
wsdc1    /iris-main --password-file ...   Up (healthy)   0.0.0.0:9105->51773/tcp, 0.0.0.0:9205->52773/tcp
wsdc2    /iris-main --password-file ...   Up (healthy)   0.0.0.0:9106->51773/tcp, 0.0.0.0:9206->52773/tcp
wsdemo   /iris-main --password-file ...   Up (healthy)   0.0.0.0:9103->51773/tcp, 0.0.0.0:9203->52773/tcp
wshq     /iris-main --password-file ...   Up (healthy)   0.0.0.0:9104->51773/tcp, 0.0.0.0:9204->52773/tcp
```
全て(healthy)になるまで時間を要します。

下記のコンテナが作成される。wsdemoを除く各々でプロダクションが開始する。  

|コンテナ名|用途| SSポート/WEBポート| ネームスペース| プロダクション名|
----|----|----|----|----
|wsdemo	|(環境制御,ECPサーバ)  |9103/9203|WSDEMO||  
|wshq	|(本部機能)	    |9104/9204 |WSHQ| WSHQ.Production.Production1|
|wsdc1	|(WH機能)	   |9105/9205  |WSDC| WSDC.Production.Production1|
|wsdc2	|(WH機能)	   |9106/9206  |WSDC| WSDC.Production.Production1|
|maker	|(メーカー機能)	|9107/9207 | MAKER| MAKER.Production.Production1|

全プロダクションが起動すると、時間経過と共に、各種処理が実行され、関連するデータ(テーブル)が随時更新される。  
例えば、管理ポータル(http://localhost:9204/csp/sys/%25CSP.Portal.Home.zen)でWSHQ(本部)のWSHQ_Data.Inventoryテーブルを見ると、入荷・出荷の実施状況が把握できる。

時間経過は、一日の経過を擬似的に"加速"するために、WSHQで稼動している
##class(WSHQ.Service.InitiatePseudoClock).OnCalculateMetrics()
ビジネスサービスにより進めている。  
初期設定では、開始日時は2001/1/1で、60秒(CallInterval値)で1日進む。下記コマンドで"現在"の日付を取得できる。
```
# docker-compose exec wshq iris session iris -U wshq
WSHQ> w $ZDATE(##class(Common.Util).GetToday())
01/04/2001
```

# 状態の確認方法
起動後の個々のプロダクションの状態確認にはプロダクションモニタが便利です。  
http://localhost:9204/csp/wshq/EnsPortal.ProductionMonitor.zen?$NAMESPACE=WSHQ

アプリレベルのイベントは各ネームスペースのイベントログ画面にて確認可能。  
http://localhost:9204/csp/wshq/EnsPortal.EventLog.zen?$NAMESPACE=WSHQ

個々のプロダクションで、Interoperability/モニタ/[アクティビティ] 画面が利用可能。  
http://localhost:9204/csp/wshq/EnsPortal.ActivityVolumeAndDuration.zen?$NAMESPACE=WSHQ


次項の「主な永続化データ」の変化をSQL文で参照。

WSHQにてCubeが利用可能。

# 停止方法
全プロダクション及びIRISインスタンスが停止する。
```
# docker-compose stop
```

全プロダクションの開始・停止。wsdemoコンテナにて
```
# docker-compose exec wsdemo iris session iris -U wsdemo
WSDEMO> d ##class(Common.Util).StartAll()
WSDEMO> d ##class(Common.Util).StopAll()
```

# リセット方法
各種テーブルの初期化方法。wsdemoコンテナにて
```
# docker-compose exec wsdemo iris session iris -U wsdemo
WSDEMO> d ##class(Common.Util).ClearAll()
```

# 完全削除方法
```
# docker-compose down -v
```
(コンテナ内に存在する)全データベースが削除される。
クラスやルーチン類も全て削除されるので、ポータルやスタジオで修正を施した場合は、注意。

# 処理概要
## 主な永続化データ

| WSHQ |  |  |
----|----|---- 
| | WSHQ.Data.InboundOrder | 発注オーダ |
| | WSHQ.Data.OutboundOrder | 販売オーダ |
| | WSHQ.Data.Inventory | 商品管理台帳 |
| | WSHQ.Data.Shortage | 欠品情報 |
| WSDC1/2 |  |  |
| | WSDC.Data.Shipping	|	出荷履歴 |
| | WSDC.Data.ShippingOrder	|	出荷オーダ |
| | WSDC.Data.ShippingDeliveryNote | 送り状 |
| | WSDC.Data.Receiving	| 入荷履歴 |
| | WSDC.Data.ReceivingOrder|入荷オーダ|
| | WSDC.Data.ReceivingDeliveryNote|メーカからの納品書|
| | WSDC.Data.InBound|発注オーダ履歴|
| | WSDC.Data.Inventory|在庫管理台帳|
| MAKER |  |  |
| | MAKER.Data.PurchaseOrder | 発注オーダ|

## 主なロジック

 http://www2.rku.ac.jp/takada/logist/plan_zaiko.html (図24,図25)を参考にした。

### 卸し本部側の処理	[WSHQ]  

- [入荷処理]  
##class(WSHQ.Operation.WSDC).DoInboundOrder()  
InitiateInboundOrderサービスにより、定期実行(15秒に一度)される。
発注オーダを検索し、配送予定日付が本日以前、DC配信済み=0 、メーカ配信済み=1 のものを対象に入荷オーダとして倉庫に伝送。
以下、未実装)	
    納入業者に伝送
	納入業者は納品書を添えて入荷。納入業者からのAES処理は未実装。

- [出荷処理]  
##class(WSHQ.Operation.WSDC).DoOutboundOrder()  
InitiateOutboundOrderサービスにより、定期実行(15秒に一度)される。
	販売オーダは、出荷オーダとして倉庫に伝送し、検品後、出荷履歴に蓄積。
	在庫不足で販売を満たせない場合も、自動発注する仕組みにする。

### 卸し倉庫側の処理	[WSDC]
- [入荷処理]  
##class(WSDC.Service.WSDC.Service.InitiateReceiving).OnCalculateMetrics()  
InitiateReceivingサービスにより、定期実行(15秒に一度)される。

	a1)入荷検品を行いながら、納品書の内容を入荷オーダから消しこむ  
	a2)入荷分は入荷履歴に追加する  
	a3)在庫管理台帳の入荷数量を更新。

- [出荷処理]  
##class(WSDC.Service.InitiateShipping).OnCalculateMetrics()  
InitiateShippingサービスにより、定期実行(15秒に一度)される。

	a1)受信した出荷オーダで当日出荷可能分の送り状を発行。  
	a2)出荷検品後、出荷オーダから消しこむ。  
	a3)出荷分を出荷履歴に追加する。  
	a4)在庫管理台帳の出荷数量を更新。  

- [発注処理]  
##class(WSDC.Service.InitiatePurchase).OnCalculateMetrics()  
InitiatePurchaseサービスにより、定期実行(15秒に一度)される。  
	倉庫内の商品の在庫数に基づいて、自動発注する仕組みになっている。
	発注オーダを作成して、本部に送信。送信失敗時には、メッセージの再試行(Retry)を繰り返す。
	再試行タイムアウト時には本部への送信オペレーションがDisableされる。復旧しない限り、発注オーダが蓄積し続ける。

### メーカ側の処理	[MAKER]
- [発注処理]  
##class(MAKER.Service.HQ).ReceivePurchaseOrder()  
WSHQから発注オーダを受け取る。

- [出荷処理]  
##class(MAKER.Service.InitiateSendDeliveryNote).OnCalculateMetrics()  
納品書を作成しWSDCに送信する。

## その他

アラート発生時には、localhost上のsmtpに対してemail送信を試みる。
WSDC上でのアラートの場合は、同情報はさらにユーザappuserにアサインされた状態で管理アラートに登録される。

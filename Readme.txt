●○●○ NTP 同期状態ロギング ○●○●

■ これは何 ?
現在時刻と、基準 NTP との時刻のズレを1分ごとにロギングします

■ 設置方法
適当なフォルダーにコピーして Install.ps1 を管理者権限で実行します
C:\NTP_Log に一式移動し、同期ログ出力と過去ログ(1か月より前)のログを削除するスケジュールを登録します。

現在 NTP 同期が設定がされていない場合は、補助ツールの SyncNTP.ps1 を使うと NTP 同期設定が出来ます。

■ ログフォーマット
記録日時[TAB]ズレ[TAB]参照 NTP Server[TAB]基準 NTP Server[TAB]最終同期時刻
C:\NTP_Log にログが出力されます(1か月保持)

■ 停止/Uninstall方法
C:\NTP_Log\RemoveSchedule.ps1 を管理者権限で実行します
C:\NTP_Log を削除します

■ 補助ツール
・SyncNTP.ps1
	現在時刻を合わせて、時刻同期設定をします
	ドメインメンバーは現在時刻だけ合わせます

	引数に同期先 NTP(FQDN or IP アドレス) を指定します(複数指定可)
	省略時は ntp.nict.jp に同期する設定をします

	例)
	SyncNTP.ps1 "NTPA", "NTPB", "NTPC"

・ForceNTPSync.ps1
	強制時刻同期スケジュール(10分ごとに強制同期)を登録します
	著しく時刻が狂う環境用に書いたので、通常は使用しません

■ 梱包リスト
Install.ps1
	インストーラー(ログ記録/過去ログ削除スケジュール登録)

RemoveSchedule.ps1
	スケジュール解除

ntp_diff_log.ps1
	時刻ズレログ出力本体(スケジュール起動)

RemoveLog.ps1
	過去ログ削除(スケジュール起動)

SyncNTP.ps1
	時刻同期設定スクリプト

Readme.txt
	このファイル

ForceNTPSync.ps1
	強制時刻同期スケジュール登録(通常使用しません)

■ ドメインコントローラーの時刻同期
代表 NTP になっているドメインコントローラーの時刻同期先設定は SyncNTP.ps1 で設定出来ないので、以下コマンドで手動設定してください。

# 現在時刻を合わせる
$TimeZome = Get-TimeZone
$TimeOffset = $TimeZome.BaseUtcOffset.ToString()
$UnixTime = [datetime]"1970/01/01 $TimeOffset"
Set-Date $UnixTime.AddSeconds((Invoke-RestMethod -Uri https://ntp-a1.nict.go.jp/cgi-bin/json).st)

# NICT に時刻同期する
w32tm /config /syncfromflags:manual /manualpeerlist:ntp.nict.jp /update
w32tm /resync

(参考ページ)
ドメインの時刻をNICTのNTPと同期させる
http://www.vwnet.jp/Windows/WS08R2/NTP/w32time.html

■ Web Page


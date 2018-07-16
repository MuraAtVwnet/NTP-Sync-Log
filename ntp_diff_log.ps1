##############################################################
# 基準 NTP Server(ntp.nict.jp) との時刻ズレ ロギング
#
#	以下フォーマットでロギングする
#		記録日時[TAB]ズレ[TAB]参照 NTP Server[TAB]基準 NTP Server[TAB]最終同期時刻
#
#	出力先
#		C:\NTP_Log\NTP_diff_Log_記録開始日正常.log
#
##############################################################

# 基準 NTP Server
$LC_StandardsNTP = "ntp.nict.jp"

# ログの出力先
$LC_LogPath = "C:\NTP_Log"

# ログファイル名
$LC_LogName = "NTP_diff_Log"

##########################################################################
# ログ出力
##########################################################################
function Log(
			$LogString
			){

	$Now = Get-Date

	# Log 出力文字列に時刻を付加(YYYY/MM/DD HH:MM:SS.MMM $LogString)
	$Log = $Now.ToString("yyyy/MM/dd HH:mm:ss.fff") + " "
	$Log += $LogString

	# ログファイル名が設定されていなかったらデフォルトのログファイル名をつける
	if( $LC_LogName -eq $null ){
		$LC_LogName = "LOG"
	}

	# ログファイル名(XXXX_YYYY-MM-DD.log)
	$LogFile = $LC_LogName + "_" +$Now.ToString("yyyy-MM-dd") + ".log"

	# ログフォルダーがなかったら作成
	if( -not (Test-Path $LC_LogPath) ) {
		New-Item $LC_LogPath -Type Directory
	}

	# ログファイル名
	$LogFileName = Join-Path $LC_LogPath $LogFile

	# ログ出力
	Write-Output $Log | Out-File -FilePath $LogFileName -Encoding Default -append

	# echo させるために出力したログを戻す
	Return $Log
}

##############################################################
# Main
##############################################################

### 同期した NTP Server の取得
$Results = w32tm /query /status

if($LASTEXITCODE -eq 0){
	### 値が取れ、基準 NTP がセットされているのて状態評価開始

	# エラー記録用
	$Now = Get-Date
	$NowTime = "{0:0000}-{1:00}-{2:00} " -f $Now.Year, $Now.Month, $Now.Day
	$NowTime += "{0:00}:{1:00}:{2:00}.{3:000}`t" -f $Now.Hour, $Now.Minute, $Now.Second, $Now.Millisecond
	$ErrorLogFile = "Error_{0:0000}-{1:00}-{2:00}.log" -f $Now.Year, $Now.Month, $Now.Day
	$ErrorLog = Join-Path $LC_LogPath $ErrorLogFile

	foreach( $Result in $Results ){
		# 最終同期時刻
		if( $Result -match "最終正常同期時刻: (?<SyncTime>.*?)$" ){
			$LastSyncTime = $Matches.SyncTime
		}
		if( $Result -match "Last Successful Sync Time: (?<SyncTime>.*?)$" ){
			$LastSyncTime = $Matches.SyncTime
		}

		# NTP Server 名
		if( $Result -match "ソース: (?<NTPServer>.*?)$" ){
			$SyncdNTP = $Matches.NTPServer
		}
		if( $Result -match "Source: (?<NTPServer>.*?)$" ){
			$SyncdNTP = $Matches.NTPServer
		}
	}

	if( ($LastSyncTime -eq $null) -or ($SyncdNTP -eq $null )){
		Write-Output $NowTime | Out-File -FilePath $ErrorLog -Encoding Default -append
		Write-Output $Results | Out-File -FilePath $ErrorLog -Encoding Default -append
		$Seplater = "----------------------------"
		Write-Output $Seplater | Out-File -FilePath $ErrorLog -Encoding Default -append
		$LastSyncTime = "Unknown"
	}

	### 時間のずれを取得
	$Results = w32tm /monitor /computers:$LC_StandardsNTP
	foreach( $Result in $Results ){
		if( $Result -match "NTP: (?<DiffString>.*)s " ){
			$DiffString = $Matches.DiffString
		}
	}
	if( $DiffString -eq $null ){
		Write-Output $NowTime | Out-File -FilePath $ErrorLog -Encoding Default -append
		Write-Output $Results | Out-File -FilePath $ErrorLog -Encoding Default -append
		$Seplater = "----------------------------"
		Write-Output $Seplater | Out-File -FilePath $ErrorLog -Encoding Default -append
		$DelayTime = "0"
	}
}
else{
	# w32tm がエラー起こした
	$DelayTime = "0"
}

# ヘッダー
$Now = Get-Date
$LogFile = $LC_LogName +"_{0:0000}-{1:00}-{2:00}.log" -f $Now.Year, $Now.Month, $Now.Day
$LogFileName = Join-Path $LC_LogPath $LogFile
if( -not (Test-Path $LogFileName)){
	$Message = "LogTime`tDiffTime`tSyncdNTP`tStandardsNTP`tLastSyncTime"
	if( -not (Test-Path $LC_LogPath)){
		md $LC_LogPath
	}
	Write-Output $Message | Out-File -FilePath $LogFileName -Encoding Default
}

# ログ出力
$Message = $DiffString + "`t" + $SyncdNTP + "`t" + $LC_StandardsNTP + "`t" + $LastSyncTime
Log $Message



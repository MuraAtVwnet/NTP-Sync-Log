#################################################
# NTP との同期設定
#################################################
Param( [array][string]$StandardNTPServers )

##########################################################################
# 対象の存在確認
##########################################################################
function IsExist( $IPAddress ){
	# Wait Time
	$WaitTime = 100
	# リトライ回数
	$RetryMax = 3

	$i = 0
	while( $true ){
		$Results = ping -w $WaitTime -n 1 $IPAddress | Out-String
		if(($Results -match "[0-9]ms ") -and ($LastExitCode -eq 0 )){
			Return $true
		}

		# リトライ回数失敗した時
		if( $i -ge $RetryMax ){
			return $false
		}
		$i++
	}
}

##########################################################################
# ドメインメンバーか?
##########################################################################
function IsDomainMember(){
	$ComputerSystem = Get-WmiObject Win32_ComputerSystem
	if( $ComputerSystem.PartOfDomain -eq $True ){
		return $true
	}
	else{
		return $false
	}
}

##########################################################################
# main
##########################################################################

# 管理権限で実行されていなかったらスクリプトを終了する
if (-not(([Security.Principal.WindowsPrincipal] `
	[Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
	[Security.Principal.WindowsBuiltInRole] "Administrator"`
	))) {
	echo "[FAIL] You must have administrative rights."
	exit
}

# 基準 NTP 指定がなかったら nict にする
if( $StandardNTPServers.Count -eq 0 ){
	[array]$StandardNTPServers = @("ntp.nict.jp")
}

# 現在設定されいる時刻
$Now = (Get-Date).DateTime
echo "[INFO]Now setting : $Now"

# 基準 NTP に ping が通るか確認
# OK なら NTP リストに加える
$StandardNTPServerList = ""
foreach( $StandardNTPServer in $StandardNTPServers ){
	if( IsExist $StandardNTPServer ){
		$StandardNTPServerList += $StandardNTPServer + " "
	}
	else{
		echo "[FAIL] NTP server is not exist : $StandardNTPServer"
		exit
	}
}

# NTP Service が稼働していなかったら自動起動にする
$Service = Get-Service w32time
if( $Service.Status -eq "Stopped" ){

	# w32time が止まっていたら遅延起動に設定しサービスを開始する
	cmd /c sc config w32time start= delayed-auto
	Start-Service w32time

	# 起動完了するまで10秒待つ
	sleep 10
}

# 現在時刻を合わせる
$NictUri = "https://ntp-a1.nict.go.jp/cgi-bin/json"
$UtcUnixTime = [datetime]"1970/01/01"

# NICT Web API 確認
try{
	$Dummy = Invoke-RestMethod -Uri $NictUri
}
catch{
	echo "[FAIL] NICT Web API not running. : $NictUri"
	$Error[0]
	exit
}

# Unix Time の TimeSpan を求める
$UnixTimeSpan = ([System.TimeZoneInfo]::FindSystemTimeZoneById("UTC")).GetUtcOffset($UnixTime)

# Unix Time の DateTimeOffset
$UnixTimeDateTimeOffset = New-Object System.DateTimeOffset( $UnixTime, $UnixTimeSpan )

# 現在の UTC
$UtcNow = $UnixTimeDateTimeOffset.AddSeconds((Invoke-RestMethod -Uri $NictUri).st)

# UTC を JST にする
$JstNow = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($UtcNow, "Tokyo Standard Time")

# 現在時刻のセット
Set-Date $JstNow.DateTime

# ドメインメンバーは NTP 同期先設定をしない
if( IsDomainMember ){
	echo "[WARNING] This Computer is Domain member."
	echo "[WARNING] NTP Sync setting is not changed."
}
else{
	# NTP に同期する設定を入れる
	echo "[INFO] Sync NTP Server : $StandardNTPServerList"
	w32tm /config /syncfromflags:manual /manualpeerlist:"$StandardNTPServerList" /update
	w32tm /resync

}

# 設定後の現在時刻
$Now = (Get-Date).DateTime
echo "[INFO]Update time : $Now"

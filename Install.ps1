###################################################
# 時刻同期ログキングスクリプトのスケジュール登録
###################################################

# 管理権限で実行されていなかったらスクリプトを終了する
if (-not(([Security.Principal.WindowsPrincipal] `
	[Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
	[Security.Principal.WindowsBuiltInRole] "Administrator"`
	))) {
	echo "[FAIL] You must have administrative rights."
	exit
}

$CurrentDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$InstallDir = "C:\NTP_Log"


# ディレクトリ無かったら作る
if( -not (Test-Path $InstallDir)){
	md $InstallDir
}

# ディレクトリ圧縮
$Dir = Get-WmiObject -query "Select * From Win32_Directory Where Name = 'C:\\NTP_Log'"
[void]$Dir.Compress()

# スクリプトコピー
if( $CurrentDir -ne $InstallDir ){
	$SourceScript = Join-Path $CurrentDir "*.ps1"
	copy $SourceScript $InstallDir -Force
	$SourceScript = Join-Path $CurrentDir "*.txt"
	copy $SourceScript $InstallDir -Force
}

# スケジュールの登録
$Script = Join-Path $InstallDir "ntp_diff_log.ps1"
SCHTASKS /Create /tn "MURA\NTP Log" /tr "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe $Script" /ru "SYSTEM" /sc MINUTE /mo 1 /st "00:00" /F

$Script = Join-Path $InstallDir "RemoveLog.ps1"
SCHTASKS /Create /tn "MURA\Remove NTP Log" /tr "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe $Script" /ru "SYSTEM" /sc DAILY /st "05:00" /F

ii $InstallDir

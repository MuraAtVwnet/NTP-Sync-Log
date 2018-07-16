###################################################
# 時刻同期ログキングスクリプトのスケジュール登録
###################################################

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
$SourceScript = Join-Path $CurrentDir "*.ps1"
move $SourceScript $InstallDir -Force
$SourceScript = Join-Path $CurrentDir "*.txt"
move $SourceScript $InstallDir -Force

# スケジュールの登録
$Script = Join-Path $InstallDir "ntp_diff_log.ps1"
SCHTASKS /Create /tn "MURA\NTP Log" /tr "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe $Script" /ru "SYSTEM" /sc MINUTE /mo 1 /st "00:00" /F

$Script = Join-Path $InstallDir "RemoveLog.ps1"
SCHTASKS /Create /tn "MURA\Remove NTP Log" /tr "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe $Script" /ru "SYSTEM" /sc DAILY /st "05:00" /F

ii $InstallDir

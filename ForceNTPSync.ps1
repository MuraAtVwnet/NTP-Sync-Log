#####################################################
# 強制時刻同期スケジュール登録
#####################################################
$ScheduleFllName = "MURA\Sync NTP"
$ScheduleStatus = schtasks /Query /TN $ScheduleFllName
if($LastExitCode -eq 0){
	schtasks /Delete /TN $ScheduleFllName /F
}
SCHTASKS /Create /tn $ScheduleFllName /tr "C:\Windows\System32\w32tm.exe /resync" /ru "SYSTEM" /sc minute /mo 10 /st "00:00"

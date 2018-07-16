##############################################################
# 古いログを削除する
##############################################################
$LogPath = "C:\NTP_Log"
$LogFiles = Join-Path $LogPath "*.log"
$DeleteDay = (Get-Date).AddMonths(-1)

dir $LogFiles | ? {$_.Attributes -notmatch "Directory"} | ? {$_.LastWriteTime -lt $DeleteDay } | del




# スケジュール削除

# 管理権限で実行されていなかったらスクリプトを終了する
if (-not(([Security.Principal.WindowsPrincipal] `
	[Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
	[Security.Principal.WindowsBuiltInRole] "Administrator"`
	))) {
	echo "[FAIL] You must have administrative rights."
	exit
}

SCHTASKS /Delete /tn "MURA\NTP Log" /F
SCHTASKS /Delete /tn "MURA\Remove NTP Log" /F

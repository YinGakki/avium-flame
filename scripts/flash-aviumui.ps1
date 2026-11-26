# =====================================================================
# AviumUI (Pixel 4 / flame) 一键刷机脚本  —— 实战验证版 (2026-11-24)
# 适配 Windows PowerShell 5.1+；本文件须保存为 UTF-8 with BOM。
# 依据 PORTING.md 阶段6。已验证的要点：
#   * 全程用 -s <真机序列号> 锁定设备，避免与模拟器(emulator)多设备歧义
#   * 每个模式切换点轮询等待真机出现，不因断开直接失败（超时才报错）
#   * 所有字符串拼接加括号(否则 Write-Host 会把 + 当参数分开)
#   * A/B 设备不支持 fastboot reboot recovery，进 recovery 需手动按键
# 用法:  powershell -ExecutionPolicy Bypass -File "D:\1\pixel4-flash\flash-aviumui.ps1"
# =====================================================================
param(
    [string]$StageDir = "$PSScriptRoot",
    [int]$WaitTimeout = 180,
    [switch]$SkipFirmwareCheck
)
function Pause-AnyKey {
    try { [Console]::ReadKey($true) | Out-Null } catch { }
}
$ErrorActionPreference = "Stop"
trap {
    Write-Host ""
    Write-Host ("!! 脚本异常终止: " + $_) -ForegroundColor Red
    Pause-AnyKey
    exit 1
}


function Log([string]$m){ Write-Host ""; Write-Host ("===== " + $m + " =====") -ForegroundColor Cyan }
function Say([string]$m,[string]$c){ if($c){ Write-Host $m -ForegroundColor $c } else { Write-Host $m } }
function Ask([string]$m){ $a = Read-Host ($m + "  [输入 y 继续, 其它中止]"); if($a -ne "y"){ Say "已中止。" Yellow; Pause-AnyKey; exit 1 } }

# --- 列出 adb 里的真机(排除 emulator 模拟器) ---
function Get-RealAdbDevices {
    $out = @(& adb devices 2>&1)
    $list = @()
    foreach($line in $out){
        if($line -match "^([0-9A-Za-z._-]+)\s+(device|sideload|recovery|unauthorized|offline)\b"){
            $sn = $Matches[1]; $st = $Matches[2]
            if($sn -match "emulator"){ continue }
            $list += (New-Object psobject -Property @{ Serial=$sn; State=$st })
        }
    }
    return $list
}
# --- 轮询等待 adb 真机进入指定状态之一, 返回序列号 ---
function Wait-AdbState([string[]]$states){
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while($sw.Elapsed.TotalSeconds -lt $WaitTimeout){
        foreach($d in (Get-RealAdbDevices)){
            if($states -contains $d.State){ Say ("检测到手机 " + $d.Serial + " [adb " + $d.State + "]") Green; return $d.Serial }
        }
        Start-Sleep -Seconds 2
    }
    Say ("等待手机(adb)超时 " + $WaitTimeout + " 秒。检查: 已连接/已授权USB调试/已选对模式。") Red; return $null
}
# --- 列出 fastboot 真机序列号(排除 emulator/waiting) ---
function Get-FastbootSerials {
    $out = @(& fastboot devices 2>&1)
    $arr = @($out | Where-Object { $_ -match "fastboot" -and $_ -notmatch "waiting for" -and $_ -notmatch "emulator" } | ForEach-Object { ($_ -split "\s+")[0] })
    return ,$arr
}
# --- 轮询等待 fastboot 真机, 返回序列号 ---
function Wait-Fastboot {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while($sw.Elapsed.TotalSeconds -lt $WaitTimeout){
        $s = Get-FastbootSerials
        if($s.Count -gt 0){ Say ("检测到手机 [fastboot] " + ($s -join ",")) Green; return $s[0] }
        Start-Sleep -Seconds 2
    }
    Say ("等待手机(fastboot/bootloader)超时 " + $WaitTimeout + " 秒。") Red; return $null
}

# 0/6 工具检查
Log "0/6 检查 adb / fastboot"
foreach($t in @("adb","fastboot")){
    $c = Get-Command $t -ErrorAction SilentlyContinue
    if($null -eq $c){ Say ("找不到 " + $t + "，请安装 platform-tools 并加入 PATH (PORTING.md 6.0)") Red; Pause-AnyKey; exit 1 }
    Say ("OK  " + $t + " -> " + $c.Source)
}

# 1/6 定位产物
Log ("1/6 查找产物 " + $StageDir)
$romZip = Get-ChildItem -Path $StageDir -Filter "AviumUI-*.zip" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$bootImg = Join-Path $StageDir "boot.img"
$dtboImg = Join-Path $StageDir "dtbo.img"
if($null -eq $romZip -or -not (Test-Path $bootImg) -or -not (Test-Path $dtboImg)){ Say ("缺少 AviumUI-*.zip / boot.img / dtbo.img，目录 " + $StageDir) Red; Pause-AnyKey; exit 1 }
Say ("ROM : " + $romZip.Name + "  " + [math]::Round($romZip.Length/1MB,1) + " MB")

# 2/6 固件检查
Log "2/6 检查连接状态 / 固件版本"
$inFastboot = Get-FastbootSerials
if($inFastboot.Count -gt 0){
    Say ("检测到手机已在 fastboot (" + ($inFastboot -join ",") + ")，跳过固件检查与 adb 重启。") Green
    $serial = $inFastboot[0]
} else {
  Say "让手机开机、开 USB 调试并在弹窗点允许，等待连接中..."
  $serial = Wait-AdbState @("device")
  if(-not $serial){ Pause-AnyKey; exit 1 }
  if(-not $SkipFirmwareCheck){
    $rel = (& adb -s $serial shell getprop ro.build.version.release 2>&1) -join ""
    $fp  = (& adb -s $serial shell getprop ro.build.fingerprint 2>&1) -join ""
    Say ("当前版本: Android " + $rel)
    Say ("fingerprint: " + $fp)
    if($rel.Trim() -ne "13"){
        Say ("当前不是官方 Android 13（Android " + $rel.Trim() + "），按【重刷】流程继续。") Yellow
        $ans = Read-Host "确认继续刷机? 输入 y 继续, 其它中止"
        if($ans -ne "y"){ Say "已中止。" Yellow; Pause-AnyKey; exit 1 }
    }
    Say "版本 OK (Android 13)。" Green
  }
}

# 3/6 进 bootloader + 解锁检查
Log "3/6 重启进入 bootloader 并检查解锁"
if($inFastboot.Count -eq 0){
    & adb -s $serial reboot bootloader 2>&1 | Out-Null
    $fbsn = Wait-Fastboot
    if(-not $fbsn){ Pause-AnyKey; exit 1 }
    $serial = $fbsn
} else {
    $fbsn = $inFastboot
}
$unlock = ""
for($ui=0; $ui -lt 6; $ui++){
    try {
        $u = ((& fastboot -s $serial getvar unlocked 2>&1 | Out-String) -join " ").Trim()
    } catch {
        $u = [string]$_
    }
    if($u -match "unlocked:\s*(yes|no)"){ $unlock = $u; break }
    if($ui -lt 5){ Start-Sleep -Seconds 2; $fbtmp = Get-FastbootSerials; if($fbtmp.Count -gt 0){ $serial = $fbtmp[0] } }
}
Say ("解锁状态读取: " + $unlock) Yellow
if($unlock -match "unlocked:\s*no"){
    Say "bootloader 未解锁。首次刷机需: fastboot flashing unlock (清空数据,音量键选Unlock电源确认),解锁后重跑本脚本。" Red
    Pause-AnyKey; exit 1
}
Say "bootloader 已解锁。" Green

# 4/6 flash boot + dtbo (带重试,规避 bootloader USB 重枚举)
function Invoke-FbFlash {
    param([string]$Part, [string]$Image, [string]$Label)
    for($fi=0; $fi -lt 8; $fi++){
        $fbs = Get-FastbootSerials
        if($fbs.Count -gt 0){ $script:serial = $fbs[0] }
        $fo = ""
        try {
            $fo = ((& fastboot -s $script:serial flash $Part $Image 2>&1 | Out-String) -join " ").Trim()
        } catch {
            $fo = [string]$_
        }
        Write-Host $fo
        if($fo -match "OKAY" -and $fo -notmatch "FAILED"){ return $true }
        if($fo -match "FAILED"){ return $false }
        Say ("等待设备就绪后重试 " + $Label + " (" + ($fi+1) + "/8)...") Yellow
        Start-Sleep -Seconds 2
    }
    return $false
}
Log "4/6 刷入 boot.img 和 dtbo.img"
Ask "即将 fastboot flash boot / fastboot flash dtbo"
if(-not (Invoke-FbFlash -Part boot -Image $bootImg -Label "boot")){ Say "刷 boot 失败" Red; Pause-AnyKey; exit 1 }
if(-not (Invoke-FbFlash -Part dtbo -Image $dtboImg -Label "dtbo")){ Say "刷 dtbo 失败" Red; Pause-AnyKey; exit 1 }
Say "boot / dtbo 已刷入。" Green

# 5/6 手动进 recovery + 格式化 data
Log "5/6 进 Avium Recovery 并格式化 data (手机手动操作)"
Say "手机当前在 bootloader。请在手机上：" Yellow
Say "  1) 音量减键切到 Recovery mode，电源键确认，进 Avium recovery"
Say "  2) Factory reset -> Format data / factory reset (清空数据)"
Say "  3) Apply update -> Apply from ADB (进入 sideload 等待)"
Say "完成后脚本会自动等待 sideload 状态。"
Ask "已进入 recovery 的 Apply from ADB 界面?"

# 6/6 等 sideload 并刷入
Log "6/6 等待 sideload 并刷入 ROM"
$ssn = Wait-AdbState @("sideload","recovery")
if(-not $ssn){ Say "未检测到 recovery sideload 设备，终止。确认手机在 Apply from ADB 界面。" Red; Pause-AnyKey; exit 1 }
Ask ("开始 adb sideload " + $romZip.Name + " ?")
$oldEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$sideloadRc = 0
try {
    & adb -s $ssn sideload $romZip.FullName 2>&1 | ForEach-Object { Write-Host $_ }
    $sideloadRc = $LASTEXITCODE
} catch {
    Write-Host ("sideload 异常: " + $_)
    $sideloadRc = 1
} finally {
    $ErrorActionPreference = $oldEAP
}
if($sideloadRc -ne 0){ Say "sideload 失败，检查数据线/驱动/包。" Red; Pause-AnyKey; exit 1 }

Say "刷入完成! recovery 选 Reboot system now 重启。首次开机较慢(3-10分钟)请耐心等。" Green
Say "可选 root (PORTING.md 6.4): Magisk patch boot.img 后 fastboot flash boot。" Yellow

Write-Host ''
Write-Host '========= 脚本结束 =========' -ForegroundColor Cyan
Pause-AnyKey

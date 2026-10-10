param([string]$TapLabel = '', [switch]$Snapshot)
$ErrorActionPreference = 'Stop'
$auditAdb = 'D:\src\android-sdk\platform-tools\adb.exe'
$auditDevice = 'ZD222QRCS7'
$auditDir = 'D:\projects\puja_proj\app\build\device-launch'
New-Item -ItemType Directory -Force -Path $auditDir | Out-Null
$auditForeground = & $auditAdb -s $auditDevice shell dumpsys activity activities
$auditResumed = ($auditForeground | Select-String 'mResumedActivity|topResumedActivity') -join ' '
if ($auditResumed -notmatch 'com.kolkatapuja.kolkata_puja') {
  throw 'Uma is not in the foreground; device check stopped.'
}
& $auditAdb -s $auditDevice shell uiautomator dump /sdcard/uma-device-launch.xml | Out-Null
$ErrorActionPreference = 'Continue'
& $auditAdb -s $auditDevice pull /sdcard/uma-device-launch.xml "$auditDir/ui.xml" 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Could not pull the device layout.' }
$ErrorActionPreference = 'Stop'
[xml]$auditUi = Get-Content -LiteralPath "$auditDir/ui.xml" -Raw
$auditNodes = $auditUi.SelectNodes('//node')
if ($TapLabel) {
  $auditNode = $auditNodes | Where-Object {
    $_.text -eq $TapLabel -or $_.'content-desc' -match ('^' + [regex]::Escape($TapLabel) + '(\r?\n|$)')
  } | Sort-Object -Property @{Expression = { if ($_.'content-desc' -match '\bTab \d+ of 5\b') { 0 } else { 1 } }} | Select-Object -First 1
  if (!$auditNode) { throw "Control not found: $TapLabel" }
  $auditBounds = [regex]::Matches($auditNode.bounds, '\d+') | ForEach-Object { [int]$_.Value }
  $auditX = [int](($auditBounds[0] + $auditBounds[2]) / 2)
  $auditY = [int](($auditBounds[1] + $auditBounds[3]) / 2)
  & $auditAdb -s $auditDevice shell input tap $auditX $auditY
  Write-Output "Tapped: $TapLabel"
} else {
  $auditLabels = $auditNodes | ForEach-Object { if ($_.'content-desc') { $_.'content-desc' } else { $_.text } }
  foreach ($auditLabel in $auditLabels) {
    if ($auditLabel -match '^(Location shared|Waiting for|Connecting location|Live GPS|Sync issue|Live$|Start$|Start navigation|Navigate|Route to|Recenter|End$|Head out|Following|GPS|Retry|Route options|Walking|Map$|Group$|People$|You have arrived|Turn |Continue )') {
      Write-Output ($auditLabel -replace '[\r\n]+', ' ')
    }
  }
}
if ($Snapshot) {
  $auditForeground = & $auditAdb -s $auditDevice shell dumpsys activity activities
  $auditResumed = ($auditForeground | Select-String 'mResumedActivity|topResumedActivity') -join ' '
  if ($auditResumed -notmatch 'com.kolkatapuja.kolkata_puja') {
    throw 'Uma left the foreground; screenshot skipped.'
  }
  & $auditAdb -s $auditDevice shell screencap -p /sdcard/uma-device-launch.png
  $ErrorActionPreference = 'Continue'
  & $auditAdb -s $auditDevice pull /sdcard/uma-device-launch.png "$auditDir/screen.png" 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Could not pull the device screenshot.' }
}

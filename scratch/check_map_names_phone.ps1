$ErrorActionPreference = 'Continue'
$adbPath = 'D:\src\android-sdk\platform-tools\adb.exe'
$deviceId = 'ZD222QRCS7'
$uiPath = 'D:\projects\puja_proj\app\build\map-names-ui.xml'
function Read-MapUi {
  & $adbPath -s $deviceId shell uiautomator dump /sdcard/uma-map-names-ui.xml | Out-Null
  & $adbPath -s $deviceId pull /sdcard/uma-map-names-ui.xml $uiPath 2>$null | Out-Null
  [xml]$xml = Get-Content -Raw -LiteralPath $uiPath
  return $xml
}
function Tap-MapLabel([string]$label) {
  $node = $null
  for ($attempt = 0; $attempt -lt 5 -and !$node; $attempt++) {
    $xml = Read-MapUi
    $node = $xml.SelectNodes('//node') | Where-Object { $_.'content-desc' -match ('^' + [regex]::Escape($label) + '(\r?\n|$)') -or $_.text -eq $label } | Select-Object -First 1
    if (!$node) { Start-Sleep -Seconds 1 }
  }
  if (!$node) { throw "Map control missing: $label" }
  $numbers = [regex]::Matches($node.bounds, '\d+') | ForEach-Object { [int]$_.Value }
  $tapX = [int](($numbers[0] + $numbers[2]) / 2)
  $tapY = [int](($numbers[1] + $numbers[3]) / 2)
  & $adbPath -s $deviceId shell input tap $tapX $tapY
}
function Save-MapScreenshot([string]$name) {
  & $adbPath -s $deviceId shell screencap -p /sdcard/uma-map-names.png
  & $adbPath -s $deviceId pull /sdcard/uma-map-names.png "D:\projects\puja_proj\app\build\$name" 2>$null | Out-Null
}
Tap-MapLabel 'Map Tools & Settings'
$xml = Read-MapUi
if (!($xml.SelectNodes('//node') | Where-Object { $_.'content-desc' -match 'More map names' -or $_.text -eq 'More map names' })) { throw 'Density setting missing' }
Write-Output 'More map names setting is visible on phone.'
Tap-MapLabel 'More map names'
Start-Sleep -Seconds 3
Save-MapScreenshot 'map-names-standard.png'
Tap-MapLabel 'Map Tools & Settings'
Tap-MapLabel 'More map names'
Start-Sleep -Seconds 3
Save-MapScreenshot 'map-names-detailed.png'
Write-Output 'Both density modes rendered; detailed mode restored.'

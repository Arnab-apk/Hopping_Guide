$ErrorActionPreference = 'Continue'
$adbPath = 'D:\src\android-sdk\platform-tools\adb.exe'
$deviceId = 'ZD222QRCS7'
$uiPath = 'D:\projects\puja_proj\app\build\journey-ui.xml'
function Read-JourneyUi {
  & $adbPath -s $deviceId shell uiautomator dump /sdcard/uma-route-ui.xml | Out-Null
  & $adbPath -s $deviceId pull /sdcard/uma-route-ui.xml $uiPath 2>$null | Out-Null
  [xml]$xml = Get-Content -Raw -LiteralPath $uiPath
  return $xml
}
function Tap-JourneyLabel([string]$label) {
 $xml = Read-JourneyUi
 $node = $xml.SelectNodes('//node') | Where-Object { $_.'content-desc' -match ('^'+[regex]::Escape($label)+'(\r?\n|$)') -or $_.text -eq $label } | Select-Object -First 1
 if (!$node) { throw "Missing route control: $label" }
 $values = [regex]::Matches($node.bounds,'\d+') | ForEach-Object { [int]$_.Value }
 & $adbPath -s $deviceId shell input tap ([int](($values[0]+$values[2])/2)) ([int](($values[1]+$values[3])/2))
}
function Save-JourneyScreenshot([string]$name) {
 & $adbPath -s $deviceId shell screencap -p /sdcard/uma-route-screen.png
 & $adbPath -s $deviceId pull /sdcard/uma-route-screen.png "D:\projects\puja_proj\app\build\$name" 2>$null | Out-Null
}


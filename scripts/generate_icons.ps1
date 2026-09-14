Add-Type -AssemblyName System.Drawing
$srcPath = Resolve-Path "app\assets\images\app_icon.png"
$srcImg = [System.Drawing.Image]::FromFile($srcPath.Path)

$sizes = @{
    "app\android\app\src\main\res\mipmap-mdpi\ic_launcher.png" = 48
    "app\android\app\src\main\res\mipmap-hdpi\ic_launcher.png" = 72
    "app\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png" = 96
    "app\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png" = 144
    "app\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png" = 192
}

foreach ($dest in $sizes.Keys) {
    $sz = $sizes[$dest]
    $destFull = (Resolve-Path (Split-Path $dest)).Path + "\" + (Split-Path $dest -Leaf)
    $bmp = New-Object System.Drawing.Bitmap $sz, $sz
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($srcImg, 0, 0, $sz, $sz)
    $g.Dispose()
    $bmp.Save($destFull, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Generated $dest ($sz x $sz)"
}
$srcImg.Dispose()

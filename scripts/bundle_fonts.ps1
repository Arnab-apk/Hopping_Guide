param([string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
$packages = Get-Content -LiteralPath "$ProjectRoot/app/.dart_tool/package_config.json" -Raw | ConvertFrom-Json
$fontPackage = $packages.packages | Where-Object { $_.name -eq 'google_fonts' }
$packageRoot = ([uri]$fontPackage.rootUri).LocalPath
$fontDir = "$ProjectRoot/app/assets/fonts/google"
New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
$families = @(
    @{ Method = 'plusJakartaSans'; Family = 'PlusJakartaSans'; Part = 'p'; License = 'plusjakartasans' },
    @{ Method = 'hindSiliguri'; Family = 'HindSiliguri'; Part = 'h'; License = 'hindsiliguri' },
    @{ Method = 'jetBrainsMono'; Family = 'JetBrainsMono'; Part = 'j'; License = 'jetbrainsmono' }
)
$weights = @{ 100 = 'Thin'; 200 = 'ExtraLight'; 300 = 'Light'; 400 = 'Regular'; 500 = 'Medium'; 600 = 'SemiBold'; 700 = 'Bold'; 800 = 'ExtraBold'; 900 = 'Black' }
foreach ($family in $families) {
    $part = Get-Content -LiteralPath "$packageRoot/lib/src/google_fonts_parts/part_$($family.Part).dart" -Raw
    $section = [regex]::Match($part, "(?s)static TextStyle $($family.Method)\(.*?final fonts = [^\{]*\{(.*?)\n    \};").Groups[1].Value
    if (!$section) { throw "Could not find descriptors for $($family.Family)" }
    $variants = [regex]::Matches($section, "(?s)fontWeight: FontWeight.w(\d+),\s*fontStyle: FontStyle.(normal|italic),.*?GoogleFontsFile\(\s*'([a-f0-9]+)',\s*(\d+)")
    foreach ($variant in $variants) {
        $weight = [int]$variant.Groups[1].Value
        $style = $weights[$weight]
        if ($variant.Groups[2].Value -eq 'italic') {
            $style = if ($weight -eq 400) { 'Italic' } else { "${style}Italic" }
        }
        $hash = $variant.Groups[3].Value
        $length = [int]$variant.Groups[4].Value
        $dest = "$fontDir/$($family.Family)-$style.ttf"
        if (!(Test-Path -LiteralPath $dest)) {
            Invoke-WebRequest -UseBasicParsing -Uri "https://fonts.gstatic.com/s/a/$hash.ttf" -OutFile $dest
        }
        if ((Get-Item -LiteralPath $dest).Length -ne $length -or (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) {
            throw "Font integrity check failed: $dest"
        }
        Write-Output "Verified $($family.Family)-$style.ttf"
    }
    $licensePath = "$fontDir/$($family.Family)-OFL.txt"
    if (!(Test-Path -LiteralPath $licensePath)) {
        Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/google/fonts/main/ofl/$($family.License)/OFL.txt" -OutFile $licensePath
    }
}

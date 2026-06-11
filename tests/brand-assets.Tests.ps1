$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        $failures.Add($Message)
    }
}

function Read-RepoFile {
    param([string]$Path)
    return Get-Content -LiteralPath (Join-Path $repo $Path) -Raw
}

$assetSpecs = @(
    @{ Path = "brand/deepapi-logo.svg"; Width = "640"; Height = "160"; Accessible = $true },
    @{ Path = "brand/deepapi-icon.svg"; Width = "128"; Height = "128"; Accessible = $true },
    @{ Path = "brand/favicon.svg"; Width = "64"; Height = "64"; Accessible = $false }
)

function Get-PngDimensions {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 24) {
        return $null
    }
    $pngSignature = @(137, 80, 78, 71, 13, 10, 26, 10)
    for ($i = 0; $i -lt $pngSignature.Count; $i++) {
        if ($bytes[$i] -ne $pngSignature[$i]) {
            return $null
        }
    }
    $width = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($bytes, 16))
    $height = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($bytes, 20))
    return @{ Width = $width; Height = $height }
}

foreach ($spec in $assetSpecs) {
    $fullPath = Join-Path $repo $spec.Path
    Assert-True (Test-Path -LiteralPath $fullPath) "$($spec.Path) must exist"
    if (-not (Test-Path -LiteralPath $fullPath)) {
        continue
    }

    [xml]$xml = Get-Content -LiteralPath $fullPath -Raw
    $svg = $xml.DocumentElement
    Assert-True ($svg.LocalName -eq "svg") "$($spec.Path) must have an svg root"
    Assert-True ($svg.width -eq $spec.Width) "$($spec.Path) must have the expected width"
    Assert-True ($svg.height -eq $spec.Height) "$($spec.Path) must have the expected height"
    Assert-True (-not [string]::IsNullOrWhiteSpace($svg.viewBox)) "$($spec.Path) must have a viewBox"

    if ($spec.Accessible) {
        $title = $svg.SelectSingleNode("*[local-name()='title']")
        $desc = $svg.SelectSingleNode("*[local-name()='desc']")
        Assert-True ($svg.role -eq "img") "$($spec.Path) must expose role=img"
        Assert-True ($svg.'aria-labelledby' -eq "title desc") "$($spec.Path) must reference title and desc"
        Assert-True ($title.id -eq "title") "$($spec.Path) must have the referenced title"
        Assert-True ($desc.id -eq "desc") "$($spec.Path) must have the referenced description"
    }
}

$logo = Read-RepoFile "brand/deepapi-logo.svg"
$icon = Read-RepoFile "brand/deepapi-icon.svg"
$favicon = Read-RepoFile "brand/favicon.svg"
foreach ($color in @("#08111F", "#24D6A5", "#8EDBFF")) {
    Assert-True ($logo.Contains($color)) "Primary logo must use $color"
    Assert-True ($icon.Contains($color)) "Square icon must use $color"
    Assert-True ($favicon.Contains($color)) "Favicon must use $color"
}

$pngLogoPath = Join-Path $repo "brand/deepapi-logo.png"
Assert-True (Test-Path -LiteralPath $pngLogoPath) "brand/deepapi-logo.png must exist"
if (Test-Path -LiteralPath $pngLogoPath) {
    $dimensions = Get-PngDimensions $pngLogoPath
    Assert-True ($null -ne $dimensions) "brand/deepapi-logo.png must be a valid PNG"
    if ($null -ne $dimensions) {
        Assert-True ($dimensions.Width -ge 1200) "brand/deepapi-logo.png must be wide enough for the pricing page"
        Assert-True ($dimensions.Height -ge 500) "brand/deepapi-logo.png must be tall enough for one-api replacement"
    }
}

$deploy = Read-RepoFile "deploy.sh"
$nginx = Read-RepoFile "nginx-deepapi.conf"
$application = Read-RepoFile "brand/APPLICATION.md"
$pricing = Read-RepoFile "static/pricing/index.html"

foreach ($asset in @("deepapi-logo.png", "deepapi-logo.svg", "deepapi-icon.svg", "favicon.svg")) {
    Assert-True ($deploy.Contains("brand/$asset")) "deploy.sh must install brand/$asset"
}

Assert-True ($deploy.Contains("static/pricing/index.html")) "deploy.sh must install the pricing page"

foreach ($route in @(
    "/pricing",
    "/pricing/",
    "/brand/deepapi-logo.png",
    "/brand/deepapi-logo.svg",
    "/brand/deepapi-icon.svg",
    "/favicon.svg",
    "/favicon.ico",
    "/logo.png"
)) {
    Assert-True ($nginx.Contains("location = $route")) "Nginx must explicitly serve $route"
    Assert-True ($application.Contains($route)) "Brand application guide must document $route"
}

Assert-True (([regex]::Matches($nginx, "types \{ \}")).Count -ge 2) "Legacy icon routes must force the SVG content type"
Assert-True ($nginx.Contains("default_type image/png")) "Nginx must serve the PNG logo with image/png"
Assert-True ($nginx.Contains("deepapi-site/pricing/index.html")) "Nginx must serve the pricing page before one-api"
Assert-True ($application.Contains("System Name")) "Brand guide must document the one-api System Name setting"
Assert-True ($application.Contains("Logo Image URL")) "Brand guide must document the one-api Logo setting"
Assert-True ($application.Contains("cannot guarantee")) "Brand guide must state the live-settings boundary"

foreach ($content in @(
    'Simple.',
    'Transparent.',
    'Affordable.',
    '$0.22',
    '$0.015',
    '$0.45',
    '$0.66',
    '$0.025',
    '$1.32',
    'Vision',
    '$0.18',
    '$1.50',
    '1M image tokens',
    'OCR and document parsing',
    'How to read the pricing?',
    'deepapi-logo.png'
)) {
    Assert-True ($pricing.Contains($content)) "Pricing page must contain $content"
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Output "FAIL: $_" }
    exit 1
}

Write-Output "Brand asset static checks passed."

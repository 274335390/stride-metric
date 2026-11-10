$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$environmentFile = Join-Path $projectRoot ".env"

if (-not (Test-Path -LiteralPath $environmentFile)) {
    throw "Missing .env. Copy .env.example to .env and add your AdMob IDs."
}

$configuration = @{}
foreach ($line in Get-Content -LiteralPath $environmentFile) {
    $trimmed = $line.Trim()
    if (-not $trimmed -or $trimmed.StartsWith("#")) {
        continue
    }
    $parts = $trimmed.Split("=", 2)
    if ($parts.Count -eq 2) {
        $configuration[$parts[0].Trim()] = $parts[1].Trim()
    }
}

$bannerId = $configuration["ADMOB_ANDROID_BANNER_ID"]
$appOpenId = $configuration["ADMOB_ANDROID_APP_OPEN_ID"]
if (-not $bannerId -or -not $appOpenId) {
    throw "Both Android AdMob ad unit IDs are required in .env."
}

Push-Location $projectRoot
try {
    & flutter build appbundle --release `
        "--dart-define=ADMOB_ANDROID_BANNER_ID=$bannerId" `
        "--dart-define=ADMOB_ANDROID_APP_OPEN_ID=$appOpenId"
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter release build failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

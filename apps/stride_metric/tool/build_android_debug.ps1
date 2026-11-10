param(
    [string]$FlutterSdk = "E:\flutter"
)

$ErrorActionPreference = "Stop"

$workspaceRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..\..")).Path
$sourceApp = Join-Path $workspaceRoot "apps\stride_metric"
$sourcePackage = Join-Path $workspaceRoot "packages\size_domain"
$flutter = Join-Path $FlutterSdk "bin\flutter.bat"

if (-not (Test-Path -LiteralPath $flutter)) {
    throw "Flutter SDK not found: $flutter"
}

$temporaryBase = [System.IO.Path]::GetTempPath()
$mirrorName = "StrideMetricBuild-" + [Guid]::NewGuid().ToString("N")
$mirrorRoot = Join-Path $temporaryBase $mirrorName
$mirrorApp = Join-Path $mirrorRoot "apps\stride_metric"
$mirrorPackage = Join-Path $mirrorRoot "packages\size_domain"
$artifactDirectory = Join-Path $sourceApp "artifacts"
$artifactPath = Join-Path $artifactDirectory "StrideMetric-debug.apk"

try {
    New-Item -ItemType Directory -Path $mirrorApp -Force | Out-Null
    New-Item -ItemType Directory -Path $mirrorPackage -Force | Out-Null

    robocopy $sourceApp $mirrorApp /E /XD build .dart_tool artifacts | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "Failed to copy the Flutter app into the ASCII build directory."
    }

    robocopy $sourcePackage $mirrorPackage /E /XD build .dart_tool | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "Failed to copy the size_domain package into the ASCII build directory."
    }

    Push-Location $mirrorApp
    try {
        & $flutter pub get
        if ($LASTEXITCODE -ne 0) {
            throw "flutter pub get failed."
        }

        & $flutter build apk --debug
        if ($LASTEXITCODE -ne 0) {
            throw "flutter build apk --debug failed."
        }
    }
    finally {
        Pop-Location
    }

    $builtApk = Join-Path $mirrorApp "build\app\outputs\flutter-apk\app-debug.apk"
    if (-not (Test-Path -LiteralPath $builtApk)) {
        throw "Build finished without producing app-debug.apk."
    }

    New-Item -ItemType Directory -Path $artifactDirectory -Force | Out-Null
    Copy-Item -LiteralPath $builtApk -Destination $artifactPath -Force
    Write-Host "APK ready: $artifactPath"
}
finally {
    if (Test-Path -LiteralPath $mirrorRoot) {
        $resolvedMirror = (Resolve-Path -LiteralPath $mirrorRoot).Path
        $resolvedTemp = [System.IO.Path]::GetFullPath($temporaryBase)
        $leaf = Split-Path -Leaf $resolvedMirror

        if ($resolvedMirror.StartsWith($resolvedTemp, [System.StringComparison]::OrdinalIgnoreCase) -and
            $leaf.StartsWith("StrideMetricBuild-", [System.StringComparison]::Ordinal)) {
            Remove-Item -LiteralPath $resolvedMirror -Recurse -Force
        }
    }
}

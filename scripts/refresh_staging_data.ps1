param(
    [switch]$SkipImd,
    [string]$WslDistro,
    [string]$WslRepoPath = "/home/speddi/dev/icb/highspring"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    throw "WSL is required but 'wsl' is not available on PATH."
}

$skipArg = if ($SkipImd) { "--skip-imd" } else { "" }
$bashCmd = "cd '$WslRepoPath' && ./scripts/refresh_staging_data.sh $skipArg"

if ([string]::IsNullOrWhiteSpace($WslDistro)) {
    & wsl -- bash -lc $bashCmd
} else {
    & wsl -d $WslDistro -- bash -lc $bashCmd
}

exit $LASTEXITCODE

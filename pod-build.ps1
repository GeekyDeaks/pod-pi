param(
    [Parameter(Position = 0)]
    [ValidateSet("base", "adk", "all")]
    [string]$Target = "base",

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$BuildArguments
)

$ErrorActionPreference = "Stop"

$ImagePrefix = $env:PI_PODMAN_IMAGE_PREFIX
if ([string]::IsNullOrWhiteSpace($ImagePrefix)) {
    $ImagePrefix = "localhost/pi-agent"
}

function Build-Image {
    param([string]$ImageTarget)

    $PodmanArguments = @(
        "build",
        "-f", (Join-Path $PSScriptRoot "Dockerfile"),
        "--target", $ImageTarget,
        "-t", "${ImagePrefix}:${ImageTarget}"
    ) + $BuildArguments + @($PSScriptRoot)

    & podman @PodmanArguments
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

if ($Target -eq "all") {
    Build-Image "base"
    Build-Image "adk"
} else {
    Build-Image $Target
}

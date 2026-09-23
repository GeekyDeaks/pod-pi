$ErrorActionPreference = "Stop"

$Image = $env:PI_PODMAN_IMAGE
if ([string]::IsNullOrWhiteSpace($Image)) {
    $Image = "localhost/pi-agent:base"
}

$PiSubagentsVersion = $env:PI_SUBAGENTS_VERSION
if ([string]::IsNullOrWhiteSpace($PiSubagentsVersion)) {
    $PiSubagentsVersion = "0.19.0"
}

$Volume = "pi-agent-home"

& podman volume exists $Volume
if ($LASTEXITCODE -ne 0) {
    & podman volume create $Volume | Out-Null
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$PodmanArguments = @(
    "run",
    "--rm",
    "--userns=keep-id:uid=1000,gid=1000",
    "--security-opt=no-new-privileges",
    "--cap-drop=ALL",
    "--tmpfs", "/tmp:rw,exec,nosuid,nodev,size=1g",
    "-e", "HOME=/home/pi",
    "-e", "PI_SUBAGENTS_VERSION=${PiSubagentsVersion}",
    "-v", "${Volume}:/home/pi:rw,U,z",
    $Image,
    "pi-agent-init"
)

& podman @PodmanArguments
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "initialized podman volume ${Volume} (bundled assets and pi-subagents ${PiSubagentsVersion})"

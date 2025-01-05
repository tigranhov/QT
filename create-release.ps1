$excludeList = @(
    ".git",
    ".gitignore",
    "GUIDELINES.md",
    "create-release.ps1"
)

# Create temp directory for organizing files
$tempDir = Join-Path $env:TEMP "QT-release-temp"
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Copy all files except excluded ones
try {
    Get-ChildItem -Path "." -Recurse |
        Where-Object {
            $item = $_
            -not ($excludeList | Where-Object { $item.Name -eq $_ }) -and
            -not ($item.PSIsContainer)
        } |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($PWD.Path.Length + 1)
            $targetPath = Join-Path $tempDir $relativePath
            $targetDir = Split-Path -Parent $targetPath
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
            }
            Write-Host "Copying $($_.FullName) to $targetPath"
            Copy-Item $_.FullName -Destination $targetPath -Force -ErrorAction Continue
        }
}
catch {
    Write-Host "Error during file copy: $_"
}

# Create the zip file
$zipName = "QT.zip"
if (Test-Path $zipName) {
    Remove-Item $zipName -Force
}

try {
    Compress-Archive -Path "$tempDir\*" -DestinationPath $zipName -Force
    Write-Host "Created release archive: $zipName"
}
catch {
    Write-Host "Error creating zip file: $_"
}
finally {
    # Cleanup
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }
} 
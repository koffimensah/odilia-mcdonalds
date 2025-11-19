# ==============================
# Create Runner Directory
# ==============================
mkdir actions-runner -Force
cd actions-runner

# ==============================
# Download Runner Package
# ==============================
$RunnerVersion = "2.329.0"
$RunnerZip = "actions-runner-win-x64-$RunnerVersion.zip"
$DownloadURL = "https://github.com/actions/runner/releases/download/v$RunnerVersion/$RunnerZip"

Invoke-WebRequest -Uri $DownloadURL -OutFile $RunnerZip

# ==============================
# Validate Hash
# ==============================
$ExpectedHash = "f60be5ddf373c52fd735388c3478536afd12bfd36d1d0777c6b855b758e70f25"

if ((Get-FileHash -Path $RunnerZip -Algorithm SHA256).Hash.ToUpper() -ne $ExpectedHash.ToUpper()) {
    throw "❌ Checksum mismatch. Aborting installation."
}
Write-Host "✔ Hash validated"

# ==============================
# Extract Runner
# ==============================
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD\$RunnerZip", "$PWD")
Write-Host "✔ Runner extracted"

# ==============================
# Configure Runner (Non-Interactive)
# ==============================
$RepoURL  = "YOUR-REPO-URL"
$Token    = "YOUR-TOKEN"

.\config.cmd --unattended --url $RepoURL --token $Token --name "win-runner-01" --work "_work"

Write-Host "✔ Runner configured"

# ==============================
# Install as Windows Service
# ==============================
.\svc.sh install
.\svc.sh start

Write-Host "🎉 Runner installed and running in the background!"

# Renn Valo 2025
# Compact all WSL ext4.vhdx disks on this workstation
# Run this script in PowerShell as Administrator
# Run all of the Docker system prune commands, remove extra images, and all Docker related artifacts before running this
# Review README.md

# Ensure script can run even if execution policy is restricted
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Check for admin rights
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "❌ This script must be run as Administrator. Please restart PowerShell with elevated privileges."
    exit
}


# 1. Shut down WSL
wsl --shutdown

# 2. Locate all ext4.vhdx files
$packagePath = "$env:LOCALAPPDATA\Packages"
$vhdxFiles = Get-ChildItem -Path $packagePath -Recurse -Filter "ext4.vhdx" -ErrorAction SilentlyContinue

# 3. Process each VHDX
foreach ($vhdx in $vhdxFiles) {
    $path = $vhdx.FullName
    $before = (Get-Item $path).Length

    Write-Host "Compacting: $path"
    Write-Host "  Size before: $([math]::Round($before/1GB,2)) GB"

    # Build DiskPart script
    $diskpartScript = @"
select vdisk file="$path"
compact vdisk
exit
"@

    # Run DiskPart
    $diskpartScript | diskpart | Out-Null

    # Get size after compaction
    $after = (Get-Item $path).Length
    Write-Host "  Size after : $([math]::Round($after/1GB,2)) GB"
    Write-Host "  Freed      : $([math]::Round(($before-$after)/1GB,2)) GB"
    Write-Host ""
}

Write-Host "✅ All WSL disks processed."
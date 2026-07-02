param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $CliArgs
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

function Show-Usage {
    @"
Usage:
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\init_project.ps1
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\init_project.ps1 build\vivado

Options:
  --xsa PATH       XSA output path. Default: build\hw\AXI_Peripheral_wrapper.xsa
  --vivado PATH    Vivado executable. Default: VIVADO env, PATH, or C:\Xilinx\Vivado\2020.2\bin\vivado.bat
  --xsct PATH      XSCT executable. Default: XSCT env, PATH, or C:\Xilinx\Vitis\2020.2\bin\xsct.bat
  --dry-run        Print commands without running Vivado or XSCT.
  -h, --help       Show this help.
"@
}

function Convert-ToRepoPath {
    param([Parameter(Mandatory = $true)][string] $PathValue)

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return [System.IO.Path]::GetFullPath($PathValue)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $script:RepoRoot $PathValue))
}

function Find-Tool {
    param(
        [string] $ConfiguredPath,
        [Parameter(Mandatory = $true)][string] $CommandName,
        [Parameter(Mandatory = $true)][string[]] $Candidates,
        [Parameter(Mandatory = $true)][string] $HelpMessage
    )

    if (-not [string]::IsNullOrWhiteSpace($ConfiguredPath)) {
        return $ConfiguredPath
    }

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    foreach ($candidate in $Candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    $dryRunVar = Get-Variable -Name DryRun -Scope Script -ErrorAction SilentlyContinue
    if ($null -ne $dryRunVar -and [bool]$dryRunVar.Value) {
        return $CommandName
    }

    throw $HelpMessage
}

function Format-CommandLine {
    param(
        [Parameter(Mandatory = $true)][string] $Executable,
        [Parameter(Mandatory = $true)][string[]] $Arguments
    )

    $parts = @($Executable) + $Arguments
    return ($parts | ForEach-Object {
        if ($_ -match "\s") {
            '"' + ($_ -replace '"', '\"') + '"'
        } else {
            $_
        }
    }) -join " "
}

function Invoke-External {
    param(
        [Parameter(Mandatory = $true)][string] $Executable,
        [Parameter(Mandatory = $true)][string[]] $Arguments,
        [Parameter(Mandatory = $true)][string] $WorkingDirectory
    )

    $display = Format-CommandLine -Executable $Executable -Arguments $Arguments
    if ($script:DryRun) {
        Write-Host "Dry run: $display"
        return
    }

    Push-Location $WorkingDirectory
    try {
        Write-Host $display
        & $Executable @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code ${LASTEXITCODE}: $display"
        }
    } finally {
        Pop-Location
    }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $ScriptDir ".."))

$ProjectDir = "build\vivado"
$XsaPath = $env:AXI_PERIPHERAL_XSA
if ([string]::IsNullOrWhiteSpace($XsaPath)) {
    $XsaPath = "build\hw\AXI_Peripheral_wrapper.xsa"
}
$VivadoBin = $env:VIVADO
$XsctBin = $env:XSCT
$DryRun = $false

$index = 0
if ($CliArgs.Count -gt 0 -and -not $CliArgs[0].StartsWith("-")) {
    $ProjectDir = $CliArgs[0]
    $index = 1
}

while ($index -lt $CliArgs.Count) {
    switch ($CliArgs[$index]) {
        "--xsa" {
            $index++
            if ($index -ge $CliArgs.Count) { throw "Missing value for --xsa" }
            $XsaPath = $CliArgs[$index]
        }
        "--vivado" {
            $index++
            if ($index -ge $CliArgs.Count) { throw "Missing value for --vivado" }
            $VivadoBin = $CliArgs[$index]
        }
        "--xsct" {
            $index++
            if ($index -ge $CliArgs.Count) { throw "Missing value for --xsct" }
            $XsctBin = $CliArgs[$index]
        }
        "--dry-run" {
            $DryRun = $true
        }
        "-h" {
            Show-Usage
            exit 0
        }
        "--help" {
            Show-Usage
            exit 0
        }
        default {
            throw "Unknown option: $($CliArgs[$index])"
        }
    }
    $index++
}

$ProjectDir = Convert-ToRepoPath $ProjectDir
$XsaPath = Convert-ToRepoPath $XsaPath

if ($RepoRoot.StartsWith("\\wsl", [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Warning "Windows Xilinx tools may not work reliably from a WSL UNC path. Prefer cloning this repo under C:\Users\...\AXI_Peripheral for the Windows tool flow."
}

$VivadoBin = Find-Tool `
    -ConfiguredPath $VivadoBin `
    -CommandName "vivado.bat" `
    -Candidates @("C:\Xilinx\Vivado\2020.2\bin\vivado.bat", "C:\Xilinx\Vivado\2020.2\bin\vivado") `
    -HelpMessage "ERROR: Vivado 2020.2 was not found. Add vivado.bat to PATH or set VIVADO=C:\Xilinx\Vivado\2020.2\bin\vivado.bat."

$XsctBin = Find-Tool `
    -ConfiguredPath $XsctBin `
    -CommandName "xsct.bat" `
    -Candidates @("C:\Xilinx\Vitis\2020.2\bin\xsct.bat", "C:\Xilinx\Vitis\2020.2\bin\xsct") `
    -HelpMessage "ERROR: Vitis XSCT 2020.2 was not found. Add xsct.bat to PATH or set XSCT=C:\Xilinx\Vitis\2020.2\bin\xsct.bat."

Write-Host "Repository: $RepoRoot"
Write-Host "Vivado    : $VivadoBin"
Write-Host "XSCT      : $XsctBin"
Write-Host "Project   : $ProjectDir"
Write-Host "XSA       : $XsaPath"

Invoke-External `
    -Executable $VivadoBin `
    -Arguments @("-mode", "batch", "-source", "scripts\create_project.tcl", "-tclargs", $ProjectDir, $XsaPath) `
    -WorkingDirectory $RepoRoot

Invoke-External `
    -Executable $VivadoBin `
    -Arguments @("-mode", "batch", "-source", "scripts\check_project.tcl", "-tclargs", (Join-Path $ProjectDir "AXI_Peripheral.xpr")) `
    -WorkingDirectory $RepoRoot

$oldXsa = $env:AXI_PERIPHERAL_XSA
try {
    $env:AXI_PERIPHERAL_XSA = $XsaPath
    Invoke-External `
        -Executable $XsctBin `
        -Arguments @("AXI_Peripheral_platform\platform.tcl") `
        -WorkingDirectory (Join-Path $RepoRoot "firmware")
} finally {
    if ($null -eq $oldXsa) {
        Remove-Item Env:\AXI_PERIPHERAL_XSA -ErrorAction SilentlyContinue
    } else {
        $env:AXI_PERIPHERAL_XSA = $oldXsa
    }
}

Write-Host "Vivado project: $(Join-Path $ProjectDir 'AXI_Peripheral.xpr')"
Write-Host "Vitis workspace: $(Join-Path $RepoRoot 'firmware')"

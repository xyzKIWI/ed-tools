@echo off
setlocal
chcp 65001 >nul
set "CHROME_DARK_MODE_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$raw=[IO.File]::ReadAllText($env:CHROME_DARK_MODE_SELF,[Text.Encoding]::UTF8); $marker='#'+'CHROME_DARK_MODE_POWERSHELL'; $i=$raw.LastIndexOf($marker); if($i -lt 0){throw 'Embedded script was not found.'}; $code=$raw.Substring($i+$marker.Length) -replace '^[\r\n]+',''; & ([ScriptBlock]::Create($code))"
exit /b %errorlevel%

#CHROME_DARK_MODE_POWERSHELL
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = 'Chrome Dark Mode'

function Get-ChromePath {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
        (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
    )
    return $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
}

function Stop-Chrome {
    Write-Host '[1/4] Closing Chrome safely...'
    $processes = Get-Process chrome -ErrorAction SilentlyContinue
    if (-not $processes) {
        Write-Host '      Chrome is not currently running.'
        return
    }

    foreach ($process in $processes) {
        try { $process.CloseMainWindow() | Out-Null } catch {}
    }
    for ($i = 0; $i -lt 25; $i++) {
        if (-not (Get-Process chrome -ErrorAction SilentlyContinue)) { break }
        Start-Sleep -Milliseconds 100
    }
    Get-Process chrome -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host '      Chrome has been closed.'
}

function Set-ForceDarkFlag([bool]$Enabled) {
    $localStatePath = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\Local State'
    if (-not (Test-Path -LiteralPath $localStatePath)) {
        Write-Host '      Error: Chrome Local State was not found.' -ForegroundColor Red
        return $false
    }

    $content = [System.IO.File]::ReadAllText($localStatePath)
    $pattern = '"enabled_labs_experiments"\s*:\s*\[([^\]]*)\]'
    $match = [System.Text.RegularExpressions.Regex]::Match($content, $pattern)

    if ($match.Success) {
        $items = [System.Collections.Generic.List[string]]::new()
        [System.Text.RegularExpressions.Regex]::Matches($match.Groups[1].Value, '"([^"]+)"') |
            ForEach-Object {
                if (-not $_.Groups[1].Value.StartsWith('enable-force-dark')) {
                    $items.Add('"' + $_.Groups[1].Value + '"')
                }
            }
        if ($Enabled) { $items.Add('"enable-force-dark@1"') }
        $replacement = '"enabled_labs_experiments":[' + ($items -join ',') + ']'
        $updated = [System.Text.RegularExpressions.Regex]::Replace($content, $pattern, $replacement)
    } elseif ($Enabled -and $content -match '"browser"\s*:\s*\{') {
        $updated = [System.Text.RegularExpressions.Regex]::Replace(
            $content,
            '"browser"\s*:\s*\{',
            '"browser":{"enabled_labs_experiments":["enable-force-dark@1"],',
            1
        )
    } else {
        return $true
    }

    [System.IO.File]::WriteAllText($localStatePath, $updated, [System.Text.Encoding]::UTF8)
    return $true
}

function Set-ProfileColorScheme([int]$Value) {
    $userDataDir = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'
    if (-not (Test-Path -LiteralPath $userDataDir)) { return 0 }

    $profileDirs = Get-ChildItem -LiteralPath $userDataDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'Default' -or $_.Name -eq 'Guest Profile' -or $_.Name -like 'Profile *' }
    $updatedProfiles = 0

    foreach ($profileDir in $profileDirs) {
        $preferencesPath = Join-Path $profileDir.FullName 'Preferences'
        if (-not (Test-Path -LiteralPath $preferencesPath)) { continue }

        try {
            $content = [System.IO.File]::ReadAllText($preferencesPath)
            $changed = $false

            if ($content -match '"color_scheme"\s*:\s*\d+') {
                $content = [System.Text.RegularExpressions.Regex]::Replace(
                    $content, '"color_scheme"\s*:\s*\d+', ('"color_scheme":' + $Value)
                )
                $changed = $true
            } elseif ($Value -eq 2 -and $content -match '"theme"\s*:\s*\{') {
                $content = [System.Text.RegularExpressions.Regex]::Replace(
                    $content, '"theme"\s*:\s*\{', '"theme":{"color_scheme":2,', 1
                )
                $changed = $true
            }

            if ($content -match '"color_scheme2"\s*:\s*\d+') {
                $content = [System.Text.RegularExpressions.Regex]::Replace(
                    $content, '"color_scheme2"\s*:\s*\d+', ('"color_scheme2":' + $Value)
                )
                $changed = $true
            } elseif ($Value -eq 2 -and $content -match '"theme"\s*:\s*\{') {
                $content = [System.Text.RegularExpressions.Regex]::Replace(
                    $content, '"theme"\s*:\s*\{', '"theme":{"color_scheme2":2,', 1
                )
                $changed = $true
            }

            if ($changed) {
                [System.IO.File]::WriteAllText($preferencesPath, $content, [System.Text.Encoding]::UTF8)
                $updatedProfiles++
            }
        } catch {
            Write-Host "      Could not update $($profileDir.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    return $updatedProfiles
}

function Start-Chrome([bool]$DarkMode) {
    $chromePath = Get-ChromePath
    if (-not $chromePath) {
        Write-Host '      Error: chrome.exe was not found.' -ForegroundColor Red
        return
    }

    if ($DarkMode) {
        Start-Process -FilePath $chromePath -ArgumentList '--force-dark-mode'
        Write-Host '      Chrome has restarted in full dark mode.' -ForegroundColor Green
    } else {
        Start-Process -FilePath $chromePath
        Write-Host '      Chrome has restarted with its default appearance.' -ForegroundColor Green
    }
}

function Enable-DarkMode {
    Clear-Host
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host '          Chrome Full Dark Mode          ' -ForegroundColor Cyan
    Write-Host '      Web Content + All Chrome Profiles  ' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''

    Stop-Chrome
    Write-Host ''
    Write-Host '[2/4] Enabling dark mode for web content...'
    if (Set-ForceDarkFlag $true) {
        Write-Host '      Dark mode for web content is enabled.' -ForegroundColor Green
    }

    Write-Host ''
    Write-Host '[3/4] Updating existing Chrome profiles...'
    $count = Set-ProfileColorScheme 2
    Write-Host "      Updated $count profile(s). Guest and new profiles are covered by the launch option." -ForegroundColor Green

    Write-Host ''
    Write-Host '[4/4] Restarting Chrome...'
    Start-Chrome $true
}

function Reset-DarkMode {
    Clear-Host
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host '       Restore Chrome Appearance         ' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''

    Stop-Chrome
    Write-Host ''
    Write-Host '[2/4] Removing dark mode for web content...'
    if (Set-ForceDarkFlag $false) {
        Write-Host '      The dark-mode flag was removed. Other custom flags were preserved.' -ForegroundColor Green
    }

    Write-Host ''
    Write-Host '[3/4] Restoring existing Chrome profiles...'
    $count = Set-ProfileColorScheme 0
    Write-Host "      Restored $count profile(s) to the system default." -ForegroundColor Green

    Write-Host ''
    Write-Host '[4/4] Restarting Chrome...'
    Start-Chrome $false
}

Clear-Host
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '            Chrome Dark Mode             ' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''
Write-Host '  [1] Enable full dark mode'
Write-Host '  [2] Restore the default Chrome appearance'
Write-Host '  [0] Cancel'
Write-Host ''
$choice = Read-Host 'Select an option'

switch ($choice) {
    '1' { Enable-DarkMode }
    '2' { Reset-DarkMode }
    default {
        Write-Host 'Cancelled.'
        Start-Sleep -Seconds 1
        exit
    }
}

Write-Host ''
Read-Host 'Finished. Press Enter to close this window' | Out-Null

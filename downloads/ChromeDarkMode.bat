@echo off
setlocal
chcp 65001 >nul
set "CHROME_DARK_MODE_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$raw=[IO.File]::ReadAllText($env:CHROME_DARK_MODE_SELF,[Text.Encoding]::UTF8); $marker='#'+'CHROME_DARK_MODE_POWERSHELL'; $i=$raw.LastIndexOf($marker); if($i -lt 0){throw 'Embedded script was not found.'}; $code=$raw.Substring($i+$marker.Length) -replace '^[\r\n]+',''; & ([ScriptBlock]::Create($code))"
exit /b %errorlevel%

#CHROME_DARK_MODE_POWERSHELL
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = 'Browser Dark Mode Tool (Chrome / Comet / Edge / IE)'
$script:Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Get-BrowserConfig {
    return @{
        'Chrome' = @{
            Key        = 'Chrome'
            Name       = 'Google Chrome'
            Process    = 'chrome'
            IsChromium = $true
            ExePaths   = @(
                (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
                (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
                (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
            )
            UserData   = (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data')
        }
        'Comet' = @{
            Key        = 'Comet'
            Name       = 'Perplexity Comet'
            Process    = 'comet'
            IsChromium = $true
            ExePaths   = @(
                (Join-Path $env:LOCALAPPDATA 'Perplexity\Comet\Application\comet.exe'),
                (Join-Path $env:ProgramFiles 'Perplexity\Comet\Application\comet.exe'),
                (Join-Path ${env:ProgramFiles(x86)} 'Perplexity\Comet\Application\comet.exe')
            )
            UserData   = (Join-Path $env:LOCALAPPDATA 'Perplexity\Comet\User Data')
        }
        'Edge' = @{
            Key        = 'Edge'
            Name       = 'Microsoft Edge'
            Process    = 'msedge'
            IsChromium = $true
            ExePaths   = @(
                (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
                (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
                (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\Application\msedge.exe')
            )
            UserData   = (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data')
        }
        'IE' = @{
            Key        = 'IE'
            Name       = 'Internet Explorer'
            Process    = 'iexplore'
            IsChromium = $false
            ExePaths   = @(
                (Join-Path $env:ProgramFiles 'Internet Explorer\iexplore.exe'),
                (Join-Path ${env:ProgramFiles(x86)} 'Internet Explorer\iexplore.exe')
            )
            UserData   = $null
        }
    }
}

function Safe-WriteAllText([string]$Path, [string]$Content) {
    for ($i = 0; $i -lt 15; $i++) {
        try {
            [System.IO.File]::WriteAllText($Path, $Content, $script:Utf8NoBom)
            return $true
        } catch {
            Start-Sleep -Milliseconds 200
        }
    }
    return $false
}

function Resolve-BrowserExe($Browser) {
    foreach ($path in $Browser.ExePaths) {
        if ($path -and (Test-Path -LiteralPath $path)) {
            return $path
        }
    }
    return $null
}

function Stop-Browser($Browser) {
    Write-Host "  [*] Closing $($Browser.Name)..." -ForegroundColor Yellow
    $processes = Get-Process -Name $Browser.Process -ErrorAction SilentlyContinue
    if (-not $processes) {
        Write-Host "      $($Browser.Name) is not currently running." -ForegroundColor DarkGray
        return
    }

    foreach ($process in $processes) {
        try { $process.CloseMainWindow() | Out-Null } catch {}
    }

    for ($i = 0; $i -lt 15; $i++) {
        if (-not (Get-Process -Name $Browser.Process -ErrorAction SilentlyContinue)) { break }
        Start-Sleep -Milliseconds 100
    }

    $remaining = Get-Process -Name $Browser.Process -ErrorAction SilentlyContinue
    if ($remaining) {
        $remaining | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    for ($i = 0; $i -lt 30; $i++) {
        if (-not (Get-Process -Name $Browser.Process -ErrorAction SilentlyContinue)) { break }
        Start-Sleep -Milliseconds 100
    }

    Write-Host "      All $($Browser.Name) processes have stopped." -ForegroundColor Green
}

function Set-ChromiumForceDarkFlag($Browser, [bool]$Enabled) {
    $localStatePath = Join-Path $Browser.UserData 'Local State'
    if (-not (Test-Path -LiteralPath $localStatePath)) {
        Write-Host "      [Skipped] $($Browser.Name) Local State was not found." -ForegroundColor DarkGray
        return $false
    }

    try {
        $content = [System.IO.File]::ReadAllText($localStatePath, [System.Text.Encoding]::UTF8)
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

        if (Safe-WriteAllText $localStatePath $updated) {
            return $true
        }

        Write-Host "      Could not save $($Browser.Name) Local State." -ForegroundColor Red
        return $false
    } catch {
        Write-Host "      Could not update Local State: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Set-ChromiumProfileColorScheme($Browser, [int]$Value) {
    if (-not (Test-Path -LiteralPath $Browser.UserData)) { return 0 }

    $profileDirs = Get-ChildItem -LiteralPath $Browser.UserData -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'Default' -or $_.Name -eq 'Guest Profile' -or $_.Name -like 'Profile *' }
    $updatedProfiles = 0

    foreach ($profileDir in $profileDirs) {
        $preferencesPath = Join-Path $profileDir.FullName 'Preferences'
        if (-not (Test-Path -LiteralPath $preferencesPath)) { continue }

        try {
            $content = [System.IO.File]::ReadAllText($preferencesPath, [System.Text.Encoding]::UTF8)
            $changed = $false

            if ($content -match '"color_scheme"\s*:\s*\d+') {
                $content = [System.Text.RegularExpressions.Regex]::Replace(
                    $content, '"color_scheme"\s*:\s*\d+', ('"color_scheme":' + $Value)
                )
                $changed = $true
            } elseif ($Value -eq 2) {
                if ($content -match '"theme"\s*:\s*\{') {
                    $content = [System.Text.RegularExpressions.Regex]::Replace(
                        $content, '"theme"\s*:\s*\{', '"theme":{"color_scheme":2,', 1
                    )
                    $changed = $true
                } else {
                    $content = [System.Text.RegularExpressions.Regex]::Replace(
                        $content, '^(\s*\{)', '$1"theme":{"color_scheme":2,"color_scheme2":2},', 1
                    )
                    $changed = $true
                }
            }

            if ($content -match '"color_scheme2"\s*:\s*\d+') {
                $content = [System.Text.RegularExpressions.Regex]::Replace(
                    $content, '"color_scheme2"\s*:\s*\d+', ('"color_scheme2":' + $Value)
                )
                $changed = $true
            } elseif ($Value -eq 2 -and ($content -match '"theme"\s*:\s*\{') -and ($content -notmatch '"color_scheme2"')) {
                $content = [System.Text.RegularExpressions.Regex]::Replace(
                    $content, '"theme"\s*:\s*\{', '"theme":{"color_scheme2":2,', 1
                )
                $changed = $true
            }

            if ($changed -and (Safe-WriteAllText $preferencesPath $content)) {
                $updatedProfiles++
            }
        } catch {
            Write-Host "      Could not update $($profileDir.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    return $updatedProfiles
}

function Start-ChromiumBrowser($Browser, [bool]$DarkMode) {
    $exe = Resolve-BrowserExe $Browser
    if (-not $exe) {
        Write-Host "      $($Browser.Name) executable was not found; launch skipped." -ForegroundColor DarkGray
        return
    }

    if ($DarkMode) {
        Start-Process -FilePath $exe -ArgumentList @('--force-dark-mode', '--enable-features=WebContentsForceDark')
        Write-Host "      $($Browser.Name) started in forced dark mode." -ForegroundColor Green
    } else {
        Start-Process -FilePath $exe
        Write-Host "      $($Browser.Name) started with its default appearance." -ForegroundColor Green
    }
}

function Set-IEDarkMode([bool]$Enabled, [bool]$Relaunch = $true) {
    $browser = (Get-BrowserConfig)['IE']
    Stop-Browser $browser

    $cssDir = Join-Path $env:LOCALAPPDATA 'BrowserDarkModeTool'
    $cssPath = Join-Path $cssDir 'ie-dark.css'
    $regKey = 'HKCU:\Software\Microsoft\Internet Explorer\Styles'

    try {
        if ($Enabled) {
            if (-not (Test-Path -LiteralPath $regKey)) {
                New-Item -Path $regKey -Force | Out-Null
            }
            if (-not (Test-Path -LiteralPath $cssDir)) {
                New-Item -ItemType Directory -Path $cssDir -Force | Out-Null
            }

            $cssContent = @"
html, body { background: #121212 !important; color: #e8eaed !important; }
body, div, section, article, main, aside, nav, header, footer, table, tr, td, th,
form, fieldset, pre, code { border-color: #5f6368 !important; }
a, a:link { color: #8ab4f8 !important; }
a:visited { color: #c58af9 !important; }
input, textarea, select, button { background: #202124 !important; color: #e8eaed !important; border-color: #5f6368 !important; }
img, video, canvas, svg { opacity: .94; }
"@
            [System.IO.File]::WriteAllText($cssPath, $cssContent, $script:Utf8NoBom)
            Set-ItemProperty -Path $regKey -Name 'FormatWithStylesheet' -Value 1 -Type DWord
            Set-ItemProperty -Path $regKey -Name 'Stylesheet' -Value $cssPath -Type String
            Set-ItemProperty -Path $regKey -Name 'Use My Stylesheet' -Value 1 -Type DWord
            Set-ItemProperty -Path $regKey -Name 'User Stylesheet' -Value $cssPath -Type String
            Write-Host '      Internet Explorer global dark stylesheet is enabled.' -ForegroundColor Green
        } elseif (Test-Path -LiteralPath $regKey) {
            Set-ItemProperty -Path $regKey -Name 'FormatWithStylesheet' -Value 0 -Type DWord
            Set-ItemProperty -Path $regKey -Name 'Use My Stylesheet' -Value 0 -Type DWord
            Write-Host '      Internet Explorer stylesheet settings were restored.' -ForegroundColor Green
        } else {
            Write-Host '      Internet Explorer is already using its default stylesheet.' -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "      Could not update Internet Explorer settings: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    if ($Relaunch) {
        $exe = Resolve-BrowserExe $browser
        if ($exe) {
            Start-Process -FilePath $exe
            Write-Host '      Internet Explorer was restarted.' -ForegroundColor Green
        } else {
            Write-Host '      Internet Explorer executable was not found; launch skipped.' -ForegroundColor DarkGray
        }
    }
}

function Enable-ChromiumBrowser($Browser) {
    Write-Host ">>> Enable dark mode for $($Browser.Name) <<<" -ForegroundColor Cyan
    Stop-Browser $Browser
    Set-ChromiumForceDarkFlag $Browser $true | Out-Null
    $count = Set-ChromiumProfileColorScheme $Browser 2
    Write-Host "      Updated $count profile(s) to use the dark color scheme." -ForegroundColor Green
    Start-ChromiumBrowser $Browser $true
}

function Reset-ChromiumBrowser($Browser) {
    Write-Host ">>> Restore the default appearance for $($Browser.Name) <<<" -ForegroundColor Cyan
    Stop-Browser $Browser
    Set-ChromiumForceDarkFlag $Browser $false | Out-Null
    $count = Set-ChromiumProfileColorScheme $Browser 0
    Write-Host "      Restored $count profile(s) to the system default." -ForegroundColor Green
    Start-ChromiumBrowser $Browser $false
}

function Finish-And-Exit([string]$Message = 'Finished. This window will close automatically...') {
    Write-Host ''
    Write-Host '====================================================' -ForegroundColor DarkGreen
    Write-Host "  [OK] $Message" -ForegroundColor Green
    Write-Host '====================================================' -ForegroundColor DarkGreen
    Start-Sleep -Milliseconds 1500
    exit 0
}

function Enable-AllBrowsers {
    Clear-Host
    Write-Host '====================================================' -ForegroundColor Cyan
    Write-Host ' Enable dark mode for Chrome, Comet, Edge, and IE ' -ForegroundColor Cyan
    Write-Host '====================================================' -ForegroundColor Cyan
    Write-Host ''

    $configs = Get-BrowserConfig
    Enable-ChromiumBrowser $configs['Chrome']
    Write-Host ''
    Enable-ChromiumBrowser $configs['Comet']
    Write-Host ''
    Enable-ChromiumBrowser $configs['Edge']
    Write-Host ''
    Write-Host '>>> Enable the Internet Explorer dark stylesheet <<<' -ForegroundColor Cyan
    Set-IEDarkMode -Enabled $true -Relaunch $false

    Finish-And-Exit 'Dark mode was enabled for all supported browsers.'
}

function Reset-AllBrowsers {
    Clear-Host
    Write-Host '====================================================' -ForegroundColor Cyan
    Write-Host ' Restore Chrome, Comet, Edge, and IE appearance ' -ForegroundColor Cyan
    Write-Host '====================================================' -ForegroundColor Cyan
    Write-Host ''

    $configs = Get-BrowserConfig
    Reset-ChromiumBrowser $configs['Chrome']
    Write-Host ''
    Reset-ChromiumBrowser $configs['Comet']
    Write-Host ''
    Reset-ChromiumBrowser $configs['Edge']
    Write-Host ''
    Write-Host '>>> Restore the Internet Explorer stylesheet <<<' -ForegroundColor Cyan
    Set-IEDarkMode -Enabled $false -Relaunch $false

    Finish-And-Exit 'All supported browsers were restored to their default appearance.'
}

function Show-BrowserSubmenu([string]$BrowserKey) {
    $browser = (Get-BrowserConfig)[$BrowserKey]
    Clear-Host
    Write-Host '====================================================' -ForegroundColor Cyan
    Write-Host " $($browser.Name) dark mode settings" -ForegroundColor Cyan
    Write-Host '====================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  [1] Enable full dark mode'
    Write-Host '  [2] Restore the default appearance'
    Write-Host '  [0] Return to the main menu'
    Write-Host ''
    $subChoice = Read-Host 'Select an option'

    switch ($subChoice) {
        '1' {
            if ($browser.IsChromium) { Enable-ChromiumBrowser $browser }
            else { Set-IEDarkMode -Enabled $true -Relaunch $true }
            Finish-And-Exit "$($browser.Name) dark mode is enabled."
        }
        '2' {
            if ($browser.IsChromium) { Reset-ChromiumBrowser $browser }
            else { Set-IEDarkMode -Enabled $false -Relaunch $true }
            Finish-And-Exit "$($browser.Name) was restored to its default appearance."
        }
        default { return }
    }
}

Clear-Host
Write-Host '====================================================' -ForegroundColor Cyan
Write-Host '              Browser Dark Mode Tool                ' -ForegroundColor Cyan
Write-Host ' Google Chrome / Perplexity Comet / Edge / IE       ' -ForegroundColor DarkCyan
Write-Host '====================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host '  [1] Enable Google Chrome dark mode' -ForegroundColor Yellow
Write-Host '  [2] Restore Google Chrome appearance' -ForegroundColor Gray
Write-Host ''
Write-Host '  --- All supported browsers ---' -ForegroundColor DarkCyan
Write-Host '  [3] Enable dark mode for all browsers' -ForegroundColor Yellow
Write-Host '  [4] Restore all browsers' -ForegroundColor Gray
Write-Host ''
Write-Host '  --- Individual browser settings ---' -ForegroundColor DarkGray
Write-Host '  [5] Perplexity Comet'
Write-Host '  [6] Microsoft Edge'
Write-Host '  [7] Internet Explorer'
Write-Host ''
Write-Host '  [0] Exit'
Write-Host ''
$choice = Read-Host 'Select an option'

$configs = Get-BrowserConfig

switch ($choice) {
    '1' {
        Enable-ChromiumBrowser $configs['Chrome']
        Finish-And-Exit 'Google Chrome dark mode is enabled.'
    }
    '2' {
        Reset-ChromiumBrowser $configs['Chrome']
        Finish-And-Exit 'Google Chrome was restored to its default appearance.'
    }
    '3' { Enable-AllBrowsers }
    '4' { Reset-AllBrowsers }
    '5' { Show-BrowserSubmenu 'Comet' }
    '6' { Show-BrowserSubmenu 'Edge' }
    '7' { Show-BrowserSubmenu 'IE' }
    default {
        Write-Host 'Cancelled. The program will now exit.' -ForegroundColor Yellow
        Start-Sleep -Milliseconds 500
        exit 0
    }
}

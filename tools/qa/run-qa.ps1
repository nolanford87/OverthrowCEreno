<#
    Automated QA run: launches Arma 3 (windowed, no pause when unfocused) with the local mod list,
    loads the Overthrow mission for a map and has the QA addon (OTQA_fnc_autoRun) start a new game
    and run a QA suite. Results go to the RPT as usual ("OT_QA PASS/FAIL/MANUAL", "OT_QA ===== DONE").

    The mod list is read from tools\qa\mods.local.txt (the -mod value, ';'-separated, including the
    releases\@Overthrow-Community-Edition folder and its QA optional). It's machine specific and not
    committed; copy it from the third line of an RPT launched the normal way.

    Usage:
        powershell -File tools\qa\run-qa.ps1 [-Suite current|archive] [-World Altis|Tanoa|Malden|Livonia] [-Stop]
    -Stop closes a running Arma 3 instead.
#>
param(
    [string]$Suite = "current",
    [string]$World = "Altis",
    [switch]$Stop
)

$ErrorActionPreference = "Stop"
if ($Stop) {
    Get-Process arma3_x64 -ErrorAction SilentlyContinue | Stop-Process -Force
    exit 0
}

$exe = "Z:\SteamLibrary\steamapps\common\Arma 3\Arma3_x64.exe"
$modsFile = Join-Path $PSScriptRoot "mods.local.txt"
if (-not (Test-Path $modsFile)) { throw "Missing $modsFile (the -mod list)" }
$mods = (Get-Content $modsFile -Raw).Trim()

$missions = @{
    "Altis" = "OverthrowMpAltis.Altis"
    "Tanoa" = "OverthrowMpTanoa.Tanoa"
    "Malden" = "OverthrowMpMalden.Malden"
    "Livonia" = "OverthrowMpLivonia.Enoch"
}
$mission = $missions[$World]
if (-not $mission) { throw "Unknown world $World" }

if (Get-Process arma3_x64 -ErrorAction SilentlyContinue) { throw "Arma 3 is already running" }

$init = "uiNamespace setVariable ['OTQA_autoRun', '$Suite']; playMission ['', '\overthrow_main\campaign\missions\$mission'];"
$arguments = @(
    "`"-mod=$mods`"",
    "-skipIntro", "-noSplash", "-world=empty", "-window", "-noPause", "-noPauseAudio",
    "`"-init=$init`""
)
Start-Process -FilePath $exe -ArgumentList $arguments | Out-Null
Write-Output "Launched Arma 3: $World, suite '$Suite'"

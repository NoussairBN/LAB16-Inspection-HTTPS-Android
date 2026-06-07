<#
.SYNOPSIS
    Gère la configuration du proxy global ADB pour les émulateurs Android.
.DESCRIPTION
    Ce script permet de définir, récupérer ou effacer facilement le proxy global
    d'un appareil Android connecté via ADB, en particulier pour diriger le trafic
    vers Burp Suite ou mitmproxy sur l'hôte (10.0.2.2:8080 par défaut).
.PARAMETER Action
    L'action à effectuer : Get, Set ou Clear.
.PARAMETER Proxy
    L'adresse du proxy sous la forme IP:PORT (défaut: 10.0.2.2:8080).
.EXAMPLE
    .\manage_proxy.ps1 -Action Get
.EXAMPLE
    .\manage_proxy.ps1 -Action Set -Proxy "10.0.2.2:8080"
.EXAMPLE
    .\manage_proxy.ps1 -Action Clear
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('Get', 'Set', 'Clear')]
    [string]$Action,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$Proxy = "10.0.2.2:8080"
)

# Vérifier si ADB est disponible
$adb = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adb) {
    if (Test-Path "C:\platform-tools\adb.exe") {
        $adbPath = "C:\platform-tools\adb.exe"
    } else {
        Write-Error "ADB n'est pas détecté dans le PATH ni dans C:\platform-tools\adb.exe. Assurez-vous d'avoir installé Android Platform Tools."
        return
    }
} else {
    $adbPath = $adb.Source
}

Write-Verbose "Utilisation de ADB : $adbPath"

# Exécuter l'action demandée
switch ($Action) {
    'Get' {
        Write-Host "Vérification du proxy HTTP global actuel sur Android..." -ForegroundColor Cyan
        $currentProxy = & $adbPath shell settings get global http_proxy
        if ($currentProxy -eq "null" -or [string]::IsNullOrWhiteSpace($currentProxy)) {
            Write-Host "[*] Aucun proxy n'est configuré (valeur: null)." -ForegroundColor Yellow
        } else {
            Write-Host "[+] Proxy actuel : $currentProxy" -ForegroundColor Green
        }
    }
    'Set' {
        Write-Host "Configuration du proxy HTTP global vers $Proxy..." -ForegroundColor Cyan
        & $adbPath shell settings put global http_proxy $Proxy
        # Vérification
        $check = & $adbPath shell settings get global http_proxy
        if ($check -eq $Proxy) {
            Write-Host "[+] Le proxy a été configuré avec succès sur $Proxy !" -ForegroundColor Green
            Write-Host "[!] Note: Pour l'émulateur Android AVD, '10.0.2.2' pointe vers le PC hôte." -ForegroundColor Yellow
        } else {
            Write-Warning "La configuration a retourné une valeur inattendue : $check"
        }
    }
    'Clear' {
        Write-Host "Suppression du proxy HTTP global..." -ForegroundColor Cyan
        & $adbPath shell settings put global http_proxy :0
        & $adbPath shell settings delete global http_proxy
        & $adbPath shell settings delete global global_http_proxy_host
        & $adbPath shell settings delete global global_http_proxy_port
        # Vérification
        $check = & $adbPath shell settings get global http_proxy
        if ($check -eq "null" -or [string]::IsNullOrWhiteSpace($check)) {
            Write-Host "[+] Le proxy a été supprimé avec succès." -ForegroundColor Green
        } else {
            Write-Warning "Le proxy n'a pas pu être totalement supprimé. Valeur restante : $check"
        }
    }
}

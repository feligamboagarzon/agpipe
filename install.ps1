# agpipe — instalador Windows nativo (BEST-EFFORT).
# Camino recomendado y probado en Windows: WSL + ./install.sh.
# Requisitos: Python 3.10+ (py launcher), y `rtk` instalado (brew vía WSL, o binario de rtk-ai.app).
# Uso:  powershell -ExecutionPolicy Bypass -File install.ps1
$ErrorActionPreference = "Stop"
$Home_      = $env:USERPROFILE
$AgpipeHome = Join-Path $Home_ ".agpipe"
$Venv       = Join-Path $Home_ ".agpipe-venv"
$BinDir     = Join-Path $Home_ ".local\bin"
$Self       = Split-Path -Parent $MyInvocation.MyCommand.Path
function Say($m){ Write-Host "▸ $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "! $m" -ForegroundColor Yellow }

Say "Verificando prerequisitos…"
$py = (Get-Command py -ErrorAction SilentlyContinue) ?? (Get-Command python -ErrorAction SilentlyContinue)
if (-not $py) { throw "Falta Python 3.10+ (instala desde python.org)" }
$realRtk = (Get-Command rtk -ErrorAction SilentlyContinue).Source
if (-not $realRtk) { Warn "No encuentro 'rtk' en PATH. Instálalo (rtk-ai.app) o usa WSL. Sigo igual." }

Say "Copiando archivos a $AgpipeHome…"
New-Item -Force -ItemType Directory $AgpipeHome | Out-Null
Copy-Item -Recurse -Force "$Self\wrapper","$Self\templates","$Self\scripts","$Self\requirements.txt" $AgpipeHome

Say "Creando venv en $Venv e instalando tooling…"
if (-not (Test-Path $Venv)) { & $py.Source -m venv $Venv }
& "$Venv\Scripts\python.exe" -m pip install -q --upgrade pip
& "$Venv\Scripts\python.exe" -m pip install -q -r "$AgpipeHome\requirements.txt"

Say "Instalando shims en $BinDir…"
New-Item -Force -ItemType Directory $BinDir | Out-Null
# shim rtk.cmd (parchea placeholders)
(Get-Content "$AgpipeHome\wrapper\rtk.cmd") `
  -replace '__AGPIPE_VENV__',  $Venv `
  -replace '__AGPIPE_REAL_RTK__', ($realRtk ?? '') `
  -replace '__AGPIPE_HOME__',   $AgpipeHome | Set-Content "$BinDir\rtk.cmd"
# shim graphify.cmd
"@echo off`r`n`"$Venv\Scripts\graphify.exe`" %*" | Set-Content "$BinDir\graphify.cmd"

Say "Añadiendo $BinDir al PATH de usuario…"
$cur = [Environment]::GetEnvironmentVariable("Path","User")
if ($cur -notlike "*$BinDir*") {
  [Environment]::SetEnvironmentVariable("Path","$BinDir;$cur","User")
  Warn "PATH actualizado (abre una terminal nueva)"
}

Say "Cableando asistentes…"
try { & rtk init --global  | Out-Null } catch { Warn "rtk init --global falló" }
New-Item -Force -ItemType Directory "$Home_\.claude" | Out-Null
Copy-Item -Force "$AgpipeHome\templates\RTK.md" "$Home_\.claude\RTK.md"
try { & "$Venv\Scripts\graphify.exe" install claude      | Out-Null } catch { Warn "graphify install claude falló" }
try { & "$Venv\Scripts\graphify.exe" install antigravity | Out-Null } catch { Warn "graphify install antigravity falló" }
try { & rtk init --gemini | Out-Null } catch {}

Say "Instalación completa. Verifica en terminal nueva: 'where rtk', 'rtk --version', 'graphify --version'."

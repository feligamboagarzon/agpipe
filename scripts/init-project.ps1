# init-project.ps1 <dir> — prepara un proyecto para el pipeline en Windows:
#   copia plantillas (CLAUDE.md, GEMINI.md, .graphifyignore, HANDOFF.md, .claude/settings.json),
#   construye el grafo (graphify update) y deja graphify-out/ listo para commitear.
# Idempotente: no sobrescribe archivos existentes salvo -Force.

param(
    [switch]$Force,
    [string]$Path = "."
)

$ErrorActionPreference = "Stop"

function Say($m){ Write-Host "▸ $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "! $m" -ForegroundColor Yellow }

$TargetDir = Resolve-Path $Path -ErrorAction SilentlyContinue
if (-not $TargetDir) {
    # If path doesn't exist yet, resolve its parent or use absolute path
    $TargetDir = [System.IO.Path]::GetFullPath($Path)
} else {
    $TargetDir = $TargetDir.Path
}

if (-not (Test-Path $TargetDir -PathType Container)) {
    throw "La ruta '$TargetDir' no es un directorio válido."
}

# Localiza templates/ (funciona desde el repo o desde la instalación ~/.agpipe)
$TemplatesDir = $null
$PossiblePaths = @(
    (Join-Path $PSScriptRoot "..\templates"),
    (Join-Path $env:USERPROFILE ".agpipe\templates")
)

foreach ($p in $PossiblePaths) {
    if (Test-Path $p -PathType Container) {
        $TemplatesDir = $p
        break
    }
}

if (-not $TemplatesDir) {
    throw "No se pudo encontrar la carpeta de plantillas (templates/)"
}

Say "Preparando pipeline en: $TargetDir"

function Copy-Template($srcName, $destRelPath) {
    $srcFile = Join-Path $TemplatesDir $srcName
    $destFile = Join-Path $TargetDir $destRelPath
    $destParent = Split-Path -Parent $destFile
    
    if (Test-Path $destFile) {
        if ($Force) {
            New-Item -Force -ItemType Directory $destParent | Out-Null
            Copy-Item -Force $srcFile $destFile
            Say "  + $destRelPath (sobrescrito por -Force)"
        } else {
            Say "  = $destRelPath (ya existe, se respeta)"
        }
    } else {
        New-Item -Force -ItemType Directory $destParent | Out-Null
        Copy-Item $srcFile $destFile
        Say "  + $destRelPath"
    }
}

Copy-Template "CLAUDE.md" "CLAUDE.md"
Copy-Template "GEMINI.md" "GEMINI.md"
Copy-Template ".graphifyignore" ".graphifyignore"
Copy-Template "HANDOFF.md" "HANDOFF.md"
Copy-Template "project-settings.json" ".claude/settings.json"

# Crea un enlace a la instalación global de agpipe para que graphify lo indexe
Say "Vinculando instalación de agpipe..."
$AgpipeDir = Join-Path $TargetDir ".agpipe"
$LinkPath = Join-Path $AgpipeDir "source"
$GlobalAgpipe = Join-Path $env:USERPROFILE ".agpipe"

if (-not (Test-Path $AgpipeDir)) {
    New-Item -ItemType Directory $AgpipeDir | Out-Null
}

if (-not (Test-Path $LinkPath)) {
    try {
        # En Windows usamos Junction para evitar requerir privilegios de administrador
        New-Item -ItemType Junction -Path $LinkPath -Value $GlobalAgpipe | Out-Null
        Say "  + .agpipe/source -> $GlobalAgpipe"
    } catch {
        Warn "  ! No se pudo crear el enlace a la instalación de agpipe"
    }
}

# Asegura que las carpetas locales de agentes estén en .gitignore
$GitignoreFile = Join-Path $TargetDir ".gitignore"
$Entries = @(
    ".gemini/",
    ".agents/",
    "scratch/",
    ".agpipe/source"
)

Say "Configurando .gitignore..."
if (-not (Test-Path $GitignoreFile)) {
    New-Item -ItemType File $GitignoreFile | Out-Null
}

$GitignoreContent = Get-Content $GitignoreFile -ErrorAction SilentlyContinue
$NewEntries = @()

foreach ($entry in $Entries) {
    # Match exact line (allowing trailing whitespace/slashes/etc)
    $escaped = [regex]::Escape($entry)
    if ($GitignoreContent -notmatch "(?m)^$escaped\s*$") {
        $NewEntries += $entry
    }
}

if ($NewEntries.Count -gt 0) {
    $AppendText = "`r`n# agpipe & agent local directories`r`n" + ($NewEntries -join "`r`n") + "`r`n"
    Add-Content $GitignoreFile $AppendText
    foreach ($entry in $NewEntries) {
        Say "  + $entry añadido a .gitignore"
    }
}



Say "Construyendo grafo (AST, sin costo de API)..."
$graphify = Get-Command graphify -ErrorAction SilentlyContinue
if ($graphify) {
    Push-Location $TargetDir
    try {
        & graphify update . | Out-Null
        Say "  + graphify-out/ listo (commitéalo para handoff resiliente)"
    } catch {
        Warn "  ! graphify update falló (revisa que el repo tenga código soportado)"
    }
    Pop-Location
} else {
    Warn "  ! 'graphify' no está en el PATH — ejecuta install.ps1 primero"
}

Say "Hecho. Siguiente: 'git add graphify-out .graphifyignore CLAUDE.md GEMINI.md && git commit'."

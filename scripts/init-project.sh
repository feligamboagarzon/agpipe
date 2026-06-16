#!/usr/bin/env bash
# init-project.sh <dir> — prepara un proyecto para el pipeline:
#   copia plantillas (CLAUDE.md, GEMINI.md, .graphifyignore, HANDOFF.md, .claude/settings.json),
#   construye el grafo (graphify update) y deja graphify-out/ listo para commitear.
# Idempotente: no sobrescribe archivos existentes salvo --force.
set -eu

FORCE=0
[ "${1:-}" = "--force" ] && { FORCE=1; shift; }
DIR="${1:-.}"
[ -d "$DIR" ] || { echo "uso: init-project.sh [--force] <dir>"; exit 1; }

# Localiza templates/ (funciona desde el repo o desde la instalación ~/.agpipe)
SELF="$(cd "$(dirname "$0")" && pwd)"
for T in "$SELF/../templates" "$HOME/.agpipe/templates"; do
  [ -d "$T" ] && TPL="$T" && break
done
: "${TPL:?no encuentro templates/}"

cd "$DIR"
copy() {  # copy <src> <dst>
  if [ -e "$2" ] && [ "$FORCE" -ne 1 ]; then echo "  = $2 (ya existe, se respeta)"; else
    mkdir -p "$(dirname "$2")"; cp "$TPL/$1" "$2"; echo "  + $2"; fi
}
echo "Preparando pipeline en: $(pwd)"
copy CLAUDE.md            CLAUDE.md
copy GEMINI.md            GEMINI.md
copy .graphifyignore      .graphifyignore
copy HANDOFF.md           HANDOFF.md
copy project-settings.json .claude/settings.json

# Crea un enlace a la instalación global de agpipe para que graphify lo indexe
echo "Vinculando instalación de agpipe..."
mkdir -p .agpipe
if [ ! -L ".agpipe/source" ] && [ ! -e ".agpipe/source" ]; then
  ln -s "$HOME/.agpipe" ".agpipe/source"
  echo "  + .agpipe/source -> $HOME/.agpipe"
fi

# Asegura que las carpetas locales de agentes estén en .gitignore
GITIGNORE=".gitignore"
entries=(
  ".gemini/"
  ".agents/"
  "scratch/"
  ".agpipe/source"
)

echo "Configurando .gitignore..."
[ -f "$GITIGNORE" ] || touch "$GITIGNORE"

has_header=0
for entry in "${entries[@]}"; do
  if ! grep -q "^$entry" "$GITIGNORE" 2>/dev/null; then
    if [ "$has_header" -eq 0 ]; then
      echo -e "\n# agpipe & agent local directories" >> "$GITIGNORE"
      has_header=1
    fi
    echo "$entry" >> "$GITIGNORE"
    echo "  + $entry añadido a .gitignore"
  fi
done



echo "Construyendo grafo (AST, sin costo de API)..."
if command -v graphify >/dev/null 2>&1; then
  graphify update . >/dev/null 2>&1 && echo "  + graphify-out/ listo (commitéalo para handoff resiliente)" \
    || echo "  ! graphify update falló (revisa que el repo tenga código soportado)"
else
  echo "  ! 'graphify' no está en el PATH — corre install.sh primero"
fi
echo "Hecho. Siguiente: 'git add graphify-out .graphifyignore CLAUDE.md GEMINI.md && git commit'."

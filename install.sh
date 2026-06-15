#!/usr/bin/env bash
# agpipe — instalador del pipeline (macOS / Linux / WSL).
# Idempotente: se puede correr varias veces. Hace backup de lo que toca.
#   Variables opcionales:  AGPIPE_VENV=~/.otra-venv  ./install.sh
set -eu

AGPIPE_HOME="${AGPIPE_HOME:-$HOME/.agpipe}"
AGPIPE_VENV="${AGPIPE_VENV:-$HOME/.agpipe-venv}"
BINDIR="$HOME/.local/bin"
SELF="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%s 2>/dev/null || echo bak)"
say(){ printf '\033[1;36m▸ %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;33m! %s\033[0m\n' "$*"; }
backup(){ [ -e "$1" ] && cp -p "$1" "$1.agpipe.bak.$STAMP" && warn "backup: $1.agpipe.bak.$STAMP" || true; }

# ---------------------------------------------------------------- prereqs
say "Verificando prerequisitos…"
PY="$(command -v python3 || true)"; [ -n "$PY" ] || { echo "Falta python3 (>=3.10)"; exit 1; }
PYV=$("$PY" -c 'import sys;print("%d.%d"%sys.version_info[:2])')
case "$PYV" in 3.1[0-9]|3.[2-9]*) : ;; *) warn "Python $PYV: se recomienda >=3.10 (markitdown lo requiere)";; esac

if command -v brew >/dev/null 2>&1; then
  if ! command -v rtk >/dev/null 2>&1 || ! brew list rtk >/dev/null 2>&1; then
    say "Instalando rtk con Homebrew…"; brew install rtk || warn "no pude instalar rtk vía brew"
  fi
else
  warn "Homebrew no encontrado. Instala rtk manualmente (https://www.rtk-ai.app/) o usa WSL/brew."
fi
REAL_RTK="$(brew --prefix 2>/dev/null)/bin/rtk"
[ -x "$REAL_RTK" ] || REAL_RTK="$(command -v rtk || true)"
[ -n "$REAL_RTK" ] || warn "No encuentro el binario rtk real; el wrapper lo buscará en runtime."

# ---------------------------------------------------------------- copiar repo a AGPIPE_HOME
say "Copiando archivos a $AGPIPE_HOME…"
mkdir -p "$AGPIPE_HOME"
cp -R "$SELF/wrapper" "$SELF/templates" "$SELF/scripts" "$SELF/requirements.txt" "$AGPIPE_HOME/"

# ---------------------------------------------------------------- venv + tooling
say "Creando venv en $AGPIPE_VENV e instalando tooling…"
[ -d "$AGPIPE_VENV" ] || "$PY" -m venv "$AGPIPE_VENV"
"$AGPIPE_VENV/bin/pip" install -q --upgrade pip
"$AGPIPE_VENV/bin/pip" install -q -r "$AGPIPE_HOME/requirements.txt"

# ---------------------------------------------------------------- bin: graphify + shim rtk
say "Instalando ejecutables en $BINDIR…"
mkdir -p "$BINDIR"
ln -sf "$AGPIPE_VENV/bin/graphify" "$BINDIR/graphify"
# shim rtk (parchea placeholders del template)
sed -e "s|__AGPIPE_VENV__|$AGPIPE_VENV|g" \
    -e "s|__AGPIPE_REAL_RTK__|$REAL_RTK|g" \
    -e "s|__AGPIPE_HOME__|$AGPIPE_HOME|g" \
    "$AGPIPE_HOME/wrapper/rtk" > "$BINDIR/rtk"
chmod +x "$BINDIR/rtk"

# ---------------------------------------------------------------- PATH en el perfil del shell
ensure_path(){
  local rc="$1"; [ -f "$rc" ] || return 0
  grep -q 'agpipe PATH' "$rc" 2>/dev/null && return 0
  { echo ''; echo '# agpipe PATH'; echo 'export PATH="$HOME/.local/bin:$PATH"'; } >> "$rc"
  warn "PATH añadido a $rc (reinicia la shell o 'source $rc')"
}
ensure_path "$HOME/.zshrc"; ensure_path "$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] || [ -f "$HOME/.bashrc" ] || { echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"; warn "creé ~/.zshrc con el PATH"; }

# ---------------------------------------------------------------- refuerzo Antigravity (opcional)
for AGY in "$HOME"/.antigravity-ide/*/bin; do
  [ -d "$AGY" ] || continue
  backup "$AGY/rtk"
  cp "$BINDIR/rtk" "$AGY/rtk"; chmod +x "$AGY/rtk"
  say "Shim reforzado en Antigravity: $AGY/rtk  (re-ejecuta install.sh tras actualizar el IDE)"
done

# ---------------------------------------------------------------- cablear asistentes
say "Cableando Claude Code…"
if command -v rtk >/dev/null 2>&1; then rtk init --global >/dev/null 2>&1 || warn "rtk init --global falló"; fi
mkdir -p "$HOME/.claude"; backup "$HOME/.claude/RTK.md"; cp "$AGPIPE_HOME/templates/RTK.md" "$HOME/.claude/RTK.md"
"$AGPIPE_VENV/bin/graphify" install claude >/dev/null 2>&1 || warn "graphify install claude falló"

say "Cableando Antigravity / Gemini…"
rtk init --gemini >/dev/null 2>&1 || warn "rtk init --gemini falló (revisa el hook de Antigravity a mano)"
"$AGPIPE_VENV/bin/graphify" install antigravity >/dev/null 2>&1 || warn "graphify install antigravity falló"
"$AGPIPE_VENV/bin/graphify" install gemini >/dev/null 2>&1 || true

# ---------------------------------------------------------------- listo
say "Instalación completa."
cat <<EOF

  Verifica (en una shell nueva):
    which rtk          -> $BINDIR/rtk   (el shim, no el binario brew)
    rtk --version      -> versión de rtk
    graphify --version -> versión de graphify
    rtk read algo.html -> Markdown limpio (trafilatura)

  Prepara un proyecto:  $AGPIPE_HOME/scripts/init-project.sh <ruta-del-proyecto>
EOF

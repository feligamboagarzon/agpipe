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

# ---------------------------------------------------------------- demo interactiva
if [ "${1:-}" != "--skip-demo" ]; then
  echo ""
  say "¿Quieres ejecutar un tutorial interactivo para medir el ahorro de tokens de agpipe? (s/N)"
  read -r run_demo </dev/tty || run_demo="n"
  if [[ "$run_demo" =~ ^[sS]$ ]]; then
    if [ -x "$SELF/scripts/demo-tutorial.sh" ]; then
      "$SELF/scripts/demo-tutorial.sh" "$SELF"
      exit 0
    else
      warn "El script de demostración no se encontró o no es ejecutable en $SELF/scripts/demo-tutorial.sh"
    fi
  fi
fi

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
say "Copiando archivos a ${AGPIPE_HOME}…"
mkdir -p "$AGPIPE_HOME"
cp -R "$SELF/wrapper" "$SELF/templates" "$SELF/scripts" "$SELF/requirements.txt" "$AGPIPE_HOME/"

# ---------------------------------------------------------------- venv + tooling
say "Creando venv en $AGPIPE_VENV e instalando tooling…"
[ -d "$AGPIPE_VENV" ] || "$PY" -m venv "$AGPIPE_VENV"
"$AGPIPE_VENV/bin/pip" install -q --upgrade pip
"$AGPIPE_VENV/bin/pip" install -q -r "$AGPIPE_HOME/requirements.txt"

# ---------------------------------------------------------------- bin: graphify + shim rtk
say "Instalando ejecutables en ${BINDIR}…"
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
if command -v rtk >/dev/null 2>&1; then rtk init --global --auto-patch >/dev/null 2>&1 || warn "rtk init --global --auto-patch falló"; fi
mkdir -p "$HOME/.claude"; backup "$HOME/.claude/RTK.md"; cp "$AGPIPE_HOME/templates/RTK.md" "$HOME/.claude/RTK.md"
"$AGPIPE_VENV/bin/graphify" install claude >/dev/null 2>&1 || warn "graphify install claude falló"

say "Cableando Antigravity / Gemini…"
rtk init -g --gemini --auto-patch >/dev/null 2>&1 || warn "rtk init -g --gemini --auto-patch falló (revisa el hook de Antigravity a mano)"
rtk init --agent antigravity --auto-patch >/dev/null 2>&1 || warn "rtk init --agent antigravity --auto-patch falló"

# Instalar wrapper para Antigravity IDE (traduce run_command/CommandLine -> rtk hook gemini)
GHOOKS="$HOME/.gemini/hooks"
mkdir -p "$GHOOKS"
cp "$AGPIPE_HOME/wrapper/rtk-hook-gemini-wrapper.py" "$GHOOKS/rtk-hook-gemini-wrapper.py"
chmod +x "$GHOOKS/rtk-hook-gemini-wrapper.py"
# El .sh exporta un PATH robusto: el IDE puede lanzar hooks con un entorno mínimo,
# y sin esto no encontraría el shim `rtk` (~/.local/bin) ni `python3`. Sin PATH el
# wrapper cae a {"decision":"allow"} y se pierde la optimización en silencio.
cat > "$GHOOKS/rtk-hook-gemini.sh" <<EOF
#!/bin/bash
export PATH="\$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:\$PATH"
exec "$GHOOKS/rtk-hook-gemini-wrapper.py"
EOF
chmod +x "$GHOOKS/rtk-hook-gemini.sh"
# Regenerar el hash de integridad: rtk init escribió uno para SU hook; al
# sobrescribirlo con nuestro wrapper quedaría desincronizado (tamper-evidence falso).
if [ -f "$GHOOKS/.rtk-hook.sha256" ]; then
  rm -f "$GHOOKS/.rtk-hook.sha256"   # rtk lo deja en solo-lectura (444); `>` fallaría
  if command -v sha256sum >/dev/null 2>&1; then
    ( cd "$GHOOKS" && sha256sum rtk-hook-gemini.sh > .rtk-hook.sha256 ) 2>/dev/null || true
  elif command -v shasum >/dev/null 2>&1; then
    ( cd "$GHOOKS" && shasum -a 256 rtk-hook-gemini.sh > .rtk-hook.sha256 ) 2>/dev/null || true
  fi
fi

# Parchear ~/.gemini/settings.json para incluir run_command
if [ -f "$HOME/.gemini/settings.json" ]; then
  if ! grep -q "run_command" "$HOME/.gemini/settings.json"; then
    sed -i.bak -e 's/"matcher": "run_shell_command"/"matcher": "run_shell_command|run_command"/g' "$HOME/.gemini/settings.json" || true
    rm -f "$HOME/.gemini/settings.json.bak"
  fi
fi

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

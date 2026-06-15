#!/usr/bin/env bash
# agpipe — desinstalador. Quita lo que añadió install.sh. No toca brew/rtk ni tus proyectos.
set -eu
AGPIPE_HOME="${AGPIPE_HOME:-$HOME/.agpipe}"
AGPIPE_VENV="${AGPIPE_VENV:-$HOME/.agpipe-venv}"
BINDIR="$HOME/.local/bin"
say(){ printf '\033[1;36m▸ %s\033[0m\n' "$*"; }

say "Quitando shim y symlink…"
[ -L "$BINDIR/graphify" ] && rm -f "$BINDIR/graphify"
# solo borra el rtk de BINDIR si es NUESTRO shim
grep -q AGPIPE "$BINDIR/rtk" 2>/dev/null && rm -f "$BINDIR/rtk" || true

say "Quitando shim de Antigravity (si lo pusimos)…"
for AGY in "$HOME"/.antigravity-ide/*/bin; do
  [ -d "$AGY" ] || continue
  grep -q AGPIPE "$AGY/rtk" 2>/dev/null && rm -f "$AGY/rtk" || true
  # restaura el backup más reciente si existe
  last=$(ls -t "$AGY"/rtk.agpipe.bak.* 2>/dev/null | head -1 || true)
  [ -n "$last" ] && cp -p "$last" "$AGY/rtk" && say "restaurado $AGY/rtk desde $last" || true
done

say "Quitando venv y home…"
rm -rf "$AGPIPE_VENV" "$AGPIPE_HOME"

say "Limpiando PATH del perfil…"
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$rc" ] || continue
  # elimina el bloque '# agpipe PATH' + la línea siguiente
  sed -i.agpipe.bak '/# agpipe PATH/,+1d' "$rc" 2>/dev/null || true
done

cat <<'EOF'
Listo. Notas:
  - 'brew install rtk' y el binario rtk siguen instalados (quítalo con 'brew uninstall rtk' si quieres).
  - Los hooks que 'rtk init' escribió en ~/.claude/settings.json no se revierten automáticamente;
    edítalo a mano si quieres quitar el hook PreToolUse.
  - Tus proyectos y sus graphify-out/ no se tocaron.
EOF

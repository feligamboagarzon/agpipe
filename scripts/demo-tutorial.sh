#!/usr/bin/env bash
set -eu

AGPIPE_REPO="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
DEMO_DIR="$HOME/agpipe-demo"
AGPIPE_HOME="${AGPIPE_HOME:-$HOME/.agpipe}"
TOKENS_LOG="$AGPIPE_HOME/agpipe-tokens.log"

say(){ printf '\033[1;36m▸ %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;33m! %s\033[0m\n' "$*"; }

# Sigue en vivo el log de conteo de tokens que rtkread.py escribe desde la shell
# del agente (Antigravity), para que sus líneas aparezcan en ESTA terminal.
TAIL_PID=""
start_tail(){
  mkdir -p "$AGPIPE_HOME"
  : > "$TOKENS_LOG"
  printf '\033[1;30m── conteo de tokens en vivo (aparecerá aquí cuando el agente lea archivos) ──\033[0m\n'
  tail -f "$TOKENS_LOG" & TAIL_PID=$!
}
stop_tail(){
  [ -n "$TAIL_PID" ] && kill "$TAIL_PID" 2>/dev/null || true
  TAIL_PID=""
}
wait_enter(){
  echo ""
  printf '\033[1;32mPresiona ENTER cuando estés listo para continuar...\033[0m\n'
  read -r </dev/tty
}

say "Preparando el proyecto de prueba en $DEMO_DIR..."
mkdir -p "$DEMO_DIR"
cd "$DEMO_DIR"

# Create calculator.py
cat << 'EOF' > calculator.py
def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

def multiply(a, b):
    return a * b

def divide(a, b):
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b
EOF

# Create a realistic "noisy" HTML spec file (Jira ticket mock)
cat << 'EOF' > specs.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Jira - AG-102</title>
  <style>
    body { font-family: sans-serif; display: flex; }
    .sidebar { width: 250px; background: #f4f5f7; padding: 20px; }
    .content { flex-grow: 1; padding: 20px; }
  </style>
</head>
<body>
  <nav class="sidebar">
    <div class="logo">Company Jira</div>
    <ul>
      <li><a href="#">Dashboard</a></li>
      <li><a href="#">Projects</a></li>
      <li><a href="#">Issues</a></li>
      <li><a href="#">Boards</a></li>
      <li><a href="#">Settings</a></li>
    </ul>
    <div class="filters">
      <h3>Quick Filters</h3>
      <button>My Issues</button>
      <button>Recently Updated</button>
    </div>
    <!-- Dummy elements to inflate token count without adding real content -->
    <div style="display:none;" id="analytics-data">{"uid":"827364","session":"abc-123","tracker_version":"2.4.1"}</div>
  </nav>
  
  <main class="content">
    <header class="issue-header">
      <h1>AG-102: Implement advanced mathematical functions</h1>
      <div class="meta">
        <span class="reporter">Created by Admin</span> on <time>2026-06-15</time>
        | <span class="status">Status: In Progress</span>
        | <span class="priority">Priority: High</span>
      </div>
    </header>
    
    <div class="issue-body">
      <h2>Description</h2>
      <p>We need to update our <code>calculator.py</code> file. Please add the following advanced functions:</p>
      <ul>
        <li>Power (exponentiation)</li>
        <li>Square root</li>
        <li>Modulo</li>
      </ul>
      <p>Make sure to add basic error handling where appropriate.</p>
    </div>
    
    <div class="issue-comments">
      <h3>Comments</h3>
      <div class="comment">
        <strong>Dev 1:</strong> I will pick this up tomorrow.
      </div>
    </div>
  </main>
  
  <footer class="site-footer" style="position: absolute; bottom: 0; width: 100%;">
    <hr>
    <p>&copy; 2026 Company Inc. All rights reserved.</p>
    <ul>
      <li><a href="/privacy">Privacy Policy</a></li>
      <li><a href="/terms">Terms of Service</a></li>
      <li><a href="/contact">Contact Support</a></li>
    </ul>
  </footer>
</body>
</html>
EOF

say "Archivos de prueba creados (calculator.py y specs.html)."
echo ""
say "=========================================================================="
say "PASO 0: INSTALANDO EL PIPELINE AGPIPE (CON CONTADOR DE TOKENS)"
say "=========================================================================="
"$AGPIPE_REPO/install.sh" --skip-demo

say "El contador de tokens ya está instalado. Ahora iniciaremos la demostración."
echo ""
say "=========================================================================="
say "FASE 1: CON CONTADOR ACTIVO (PERO SIN COMPRESIÓN)"
say "=========================================================================="
say "¡ATENCIÓN/IMPORTANTE PARA PRESERVAR ESTA TERMINAL!"
warn "Abre la carpeta de la demo ($DEMO_DIR) en una NUEVA VENTANA de Antigravity IDE"
warn "(Archivo -> Nueva ventana, y luego selecciona la carpeta) o desde el CLI:"
warn "  antigravity -n \"$DEMO_DIR\""
warn "NO la abras en la misma ventana, ya que cerrará esta terminal y detendrá el tutorial."
echo ""
echo "Una vez abierta la demo en la nueva ventana de Antigravity:"
echo "1. Selecciona el modelo Gemini (Pro o Flash)."
echo "2. Pega exactamente el siguiente prompt:"
echo ""
printf '\033[0;35mAnaliza el archivo specs.html y el archivo calculator.py y crea un implementation plan para añadir las nuevas funciones solicitadas. IMPORTANTE: usa el comando de terminal `cat` para leer los archivos (cat specs.html, cat calculator.py). NO uses herramientas nativas de lectura de archivos ni rtk ni graphify.\033[0m\n'
echo ""
echo "3. Luego, pídele a Claude que lo implemente según el plan."
echo "4. Durante la ejecución, observa que en esta terminal se imprimirá una línea indicando"
echo "   el consumo de tokens real del archivo leído en tiempo real."
echo "   Verás algo como: [agpipe] Leyendo specs.html: 667 tokens (sin comprimir)"
echo ""
start_tail
wait_enter
stop_tail

echo ""
say "=========================================================================="
say "FASE 2: ACTIVANDO EL PIPELINE DE COMPRESIÓN Y OPTIMIZACIÓN"
say "=========================================================================="
say "Ahora activaremos la compresión y el handoff optimizado en la demo..."
"$HOME/.agpipe/scripts/init-project.sh" "$DEMO_DIR" --force

echo ""
echo "Vuelve a la ventana de Antigravity IDE donde tienes abierta la demo."
echo "1. Cierre el chat anterior y abre un NUEVO chat (para limpiar el contexto)."
echo "2. Selecciona el modelo Gemini."
echo "3. Pega EXACTAMENTE EL MISMO PROMPT:"
echo ""
printf '\033[0;35mAnaliza el archivo specs.html y el archivo calculator.py y crea un implementation plan para añadir las nuevas funciones solicitadas. IMPORTANTE: usa el comando de terminal `cat` para leer los archivos (cat specs.html, cat calculator.py). rtk y graphify están permitidos.\033[0m\n'
echo ""
echo "4. Luego, pásaselo a Claude para que programe."
echo "5. Observa cómo ahora el log en tiempo real te muestra el ahorro de tokens de forma activa:"
echo "   Verás algo como: [agpipe] Leyendo specs.html: 97 tokens (comprimido desde 667, ahorro del 85.5%)"
echo ""
start_tail
wait_enter
stop_tail

# Definir AGPIPE_VENV por si no está en el ambiente
AGPIPE_VENV="${AGPIPE_VENV:-$HOME/.agpipe-venv}"

echo ""
say "=========================================================================="
say "RESUMEN DE AHORRO DE TOKENS CALCULADO SOBRE specs.html"
say "=========================================================================="
if [ -x "$AGPIPE_VENV/bin/python" ]; then
  "$AGPIPE_VENV/bin/python" "$AGPIPE_REPO/wrapper/rtkread.py" tokens --compare "$DEMO_DIR/specs.html" || true
else
  python3 "$AGPIPE_REPO/wrapper/rtkread.py" tokens --compare "$DEMO_DIR/specs.html" || true
fi
echo ""
say "¡Felicidades! Has comprobado cómo trafilatura limpia el HTML"
say "para recortar el consumo de tokens en tus chats en tiempo real de forma activa."
say "Demo completada. El pipeline ya está instalado."

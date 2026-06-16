#!/usr/bin/env python3
"""agpipe — wrapper de conversión de documentos para `rtk read` (cross-platform).

Intercepta SOLO `rtk read <archivos>`:
  - .html/.htm  -> trafilatura (extrae el contenido principal, descarta nav/sidebars/footer)
  - pdf/docx/xlsx/pptx/xls/png/jpg/jpeg/mp3/wav -> markitdown (Markdown estructurado)
  - cualquier otra cosa (código, no-doc) y todo comando que NO sea `read` -> rtk real (passthrough)

Rutas autodetectadas en runtime; el instalador puede fijarlas vía:
  AGPIPE_VENV       (default ~/.agpipe-venv)         -> de aquí salen trafilatura/markitdown
  AGPIPE_REAL_RTK   (default: brew --prefix / PATH)  -> el binario rtk real
Funciona en macOS, Linux y Windows.
"""
import os
import sys
import subprocess

HOME = os.path.expanduser("~")
DOC_EXTS = {"pdf", "docx", "xlsx", "pptx", "xls", "png", "jpg", "jpeg", "mp3", "wav"}
HTML_EXTS = {"html", "htm"}


def venv_bin(name):
    """Ruta a un ejecutable dentro del venv (bin/ en Unix, Scripts/ en Windows)."""
    venv = os.environ.get("AGPIPE_VENV") or os.path.join(HOME, ".agpipe-venv")
    for sub, exe in (("bin", name), ("Scripts", name + ".exe"), ("Scripts", name)):
        cand = os.path.join(venv, sub, exe)
        if os.path.isfile(cand):
            return cand
    return None


def looks_like_self(path):
    """True si `path` es nuestro propio shim (evita recursión infinita)."""
    try:
        with open(path, "rb") as fh:
            head = fh.read(400)
        return b"AGPIPE" in head or b"rtkread" in head
    except Exception:
        return False


def find_real_rtk():
    # 1) fijado por el instalador
    env = os.environ.get("AGPIPE_REAL_RTK")
    if env and os.path.isfile(env):
        return env
    self_real = os.path.realpath(sys.argv[0])
    names = ["rtk.exe", "rtk"] if os.name == "nt" else ["rtk"]
    # 2) Homebrew (macOS/Linux)
    try:
        pref = subprocess.run(["brew", "--prefix"], capture_output=True, text=True,
                              timeout=5).stdout.strip()
        cand = os.path.join(pref, "bin", "rtk") if pref else ""
        if cand and os.path.isfile(cand) and os.path.realpath(cand) != self_real:
            return cand
    except Exception:
        pass
    # 3) escaneo de PATH, saltando nuestro propio shim
    for d in os.environ.get("PATH", "").split(os.pathsep):
        for n in names:
            cand = os.path.join(d, n)
            if (os.path.isfile(cand) and os.access(cand, os.X_OK)
                    and os.path.realpath(cand) != self_real
                    and not looks_like_self(cand)):
                return cand
    return None


def exec_real_rtk(args):
    real = find_real_rtk()
    if not real:
        sys.stderr.write("agpipe: no se encontró el binario rtk real "
                         "(instálalo con `brew install rtk` o fija AGPIPE_REAL_RTK)\n")
        return 127
    if os.name == "nt":
        return subprocess.run([real] + args).returncode
    os.execv(real, [real] + args)  # reemplaza el proceso (Unix)


def emit(text):
    sys.stdout.write(text if text.endswith("\n") else text + "\n")


def report(msg):
    """Reporta el conteo de tokens: a stderr (terminal del agente, flushed) y a un
    log compartido en AGPIPE_HOME, para que la terminal del tutorial pueda hacer
    `tail -f` y mostrar los conteos en vivo aunque el agente corra en otra shell."""
    sys.stderr.write(msg)
    sys.stderr.flush()
    try:
        home_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        with open(os.path.join(home_dir, "agpipe-tokens.log"), "a", encoding="utf-8") as fh:
            fh.write(msg)
            fh.flush()
    except Exception:
        pass


def get_compressed_text(path):
    ext = path.rsplit(".", 1)[-1].lower() if "." in os.path.basename(path) else ""
    if ext in HTML_EXTS:
        traf = venv_bin("trafilatura")
        if traf:
            try:
                with open(path, "rb") as fh:
                    out = subprocess.run([traf, "--markdown"], stdin=fh,
                                         capture_output=True, text=True, timeout=120).stdout
                if out.strip():
                    return out
            except Exception:
                pass
        # fallback: markitdown
        ext = "html"
    if ext in DOC_EXTS or ext == "html":
        mid = venv_bin("markitdown")
        if mid:
            try:
                out = subprocess.run([mid, path], capture_output=True, text=True,
                                     timeout=300).stdout
                if out.strip():
                    return out
            except Exception:
                pass
    # último recurso: rtk read real
    real = find_real_rtk()
    if real:
        try:
            out = subprocess.run([real, "read", path], capture_output=True, text=True,
                                 timeout=30).stdout
            if out.strip():
                return out
        except Exception:
            pass
    # fallback final: leer crudo si es posible
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as fh:
            return fh.read()
    except Exception:
        return ""


def convert(path):
    raw_tokens = 0
    try:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8", errors="ignore") as fh:
                raw_tokens = count_tokens(fh.read())
    except Exception:
        pass

    out = get_compressed_text(path)
    if out:
        comp_tokens = count_tokens(out)
        savings = raw_tokens - comp_tokens
        pct = (savings / raw_tokens * 100) if raw_tokens > 0 else 0.0
        report(f"\n\033[1;32m[agpipe] Leyendo {path}: {comp_tokens:,} tokens (comprimido desde {raw_tokens:,}, ahorro del {pct:.1f}%)\033[0m\n")
        emit(out)


def count_tokens(text):
    try:
        import tiktoken
        encoding = tiktoken.get_encoding("cl100k_base")
        return len(encoding.encode(text))
    except Exception:
        # Aproximación rápida si tiktoken no está disponible
        return len(text) // 4


def is_project_initialized(path=None):
    cur = os.path.abspath(path) if path else os.getcwd()
    while True:
        if os.path.isfile(os.path.join(cur, "CLAUDE.md")) or os.path.isfile(os.path.join(cur, "GEMINI.md")):
            return True
        parent = os.path.dirname(cur)
        if parent == cur:
            break
        cur = parent
    return False


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(exec_real_rtk(args) or 0)

    cmd = args[0]
    if cmd in ("tokens", "count"):
        opts = [a for a in args[1:] if a.startswith("-")]
        files = [a for a in args[1:] if not a.startswith("-")]
        compare = "--compare" in opts or "-c" in opts

        if not files:
            if not sys.stdin.isatty():
                text = sys.stdin.read()
                tokens = count_tokens(text)
                emit(f"{tokens}")
                sys.exit(0)
            else:
                emit("Uso: rtk tokens [--compare] <archivo1> <archivo2> ...")
                emit("O: cat archivo.txt | rtk tokens")
                sys.exit(1)

        for f in files:
            if not os.path.exists(f):
                sys.stderr.write(f"Error: no existe el archivo '{f}'\n")
                continue
            if compare:
                try:
                    with open(f, "r", encoding="utf-8", errors="ignore") as fh:
                        raw_text = fh.read()
                except Exception as e:
                    sys.stderr.write(f"Error al leer '{f}': {e}\n")
                    continue

                raw_tokens = count_tokens(raw_text)
                comp_text = get_compressed_text(f)
                comp_tokens = count_tokens(comp_text)

                savings = raw_tokens - comp_tokens
                pct = (savings / raw_tokens * 100) if raw_tokens > 0 else 0.0
                emit(f"Archivo: {f}")
                emit(f"  Original:   {raw_tokens:,} tokens")
                emit(f"  Comprimido: {comp_tokens:,} tokens")
                emit(f"  Ahorro:     {savings:,} tokens ({pct:.1f}%)")
            else:
                try:
                    with open(f, "r", encoding="utf-8", errors="ignore") as fh:
                        text = fh.read()
                except Exception as e:
                    sys.stderr.write(f"Error al leer '{f}': {e}\n")
                    continue
                tokens = count_tokens(text)
                emit(f"{f}: {tokens:,} tokens")
        sys.exit(0)

    if cmd != "read":
        sys.exit(exec_real_rtk(args) or 0)

    files = [a for a in args[1:] if not a.startswith("-")]
    if not files:
        sys.exit(exec_real_rtk(args) or 0)

    # Si el proyecto no está inicializado: emitir el contenido crudo directamente
    # (Phase 1 — baseline sin compresión, sin pasar por rtk)
    target_dir = os.path.dirname(os.path.abspath(files[0])) if files else None
    if not is_project_initialized(target_dir):
        for f in files:
            if not os.path.exists(f):
                sys.stderr.write(f"agpipe: no existe el archivo '{f}'\n")
                continue
            try:
                with open(f, "r", encoding="utf-8", errors="ignore") as fh:
                    content = fh.read()
                raw_tokens = count_tokens(content)
                report(f"\n\033[1;36m[agpipe] Leyendo {f}: {raw_tokens:,} tokens (sin comprimir)\033[0m\n")
                sys.stdout.write(content)
                if not content.endswith("\n"):
                    sys.stdout.write("\n")
            except Exception:
                pass
        sys.exit(0)

    for f in files:
        convert(f)


if __name__ == "__main__":
    main()

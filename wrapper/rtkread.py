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


def convert(path):
    ext = path.rsplit(".", 1)[-1].lower() if "." in os.path.basename(path) else ""
    if ext in HTML_EXTS:
        traf = venv_bin("trafilatura")
        if traf:
            try:
                with open(path, "rb") as fh:
                    out = subprocess.run([traf, "--markdown"], stdin=fh,
                                         capture_output=True, text=True, timeout=120).stdout
                if out.strip():
                    emit(out)
                    return
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
                    emit(out)
                    return
            except Exception:
                pass
    # último recurso: rtk read real
    real = find_real_rtk()
    if real:
        subprocess.run([real, "read", path])


def main():
    args = sys.argv[1:]
    if not args or args[0] != "read":
        sys.exit(exec_real_rtk(args) or 0)
    files = [a for a in args[1:] if not a.startswith("-")]
    if not files:
        sys.exit(exec_real_rtk(args) or 0)
    for f in files:
        convert(f)


if __name__ == "__main__":
    main()

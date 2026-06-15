# agpipe — Pipeline de desarrollo multi-modelo, optimizado para tokens

Instala y configura, en una máquina nueva, todo el pipeline **Gemini (planificación) + Claude
(razonamiento)** con ahorro agresivo de tokens: **RTK** (proxy CLI), **Graphify** (exploración por
grafo), conversión de documentos (**trafilatura** para HTML, **markitdown** para PDF/DOCX/XLSX/PPTX),
hooks de reescritura automática y plantillas de proyecto.

> El repo solo contiene **scripts y plantillas**. Las herramientas de terceros (rtk, graphify,
> markitdown…) las instala cada máquina con su gestor → sin redistribuir binarios.

## Qué deja instalado
- `rtk` (Homebrew) + un **shim** en `~/.local/bin/rtk` que intercepta `rtk read <doc>` y convierte
  documentos a Markdown ligero (HTML→trafilatura, resto→markitdown), pasando todo lo demás al rtk real.
- venv dedicado `~/.agpipe-venv` con `graphifyy`, `markitdown[pdf,docx,pptx,xlsx]`, `trafilatura`, `tiktoken`.
- `graphify` en el PATH.
- Hooks de **Claude Code** (`rtk init --global`, `graphify install claude`) y **Antigravity/Gemini**
  (`rtk init --gemini`, `graphify install antigravity`).
- Plantillas en `~/.agpipe/templates` y el scaffolder `init-project.sh`.

## Requisitos
- **macOS / Linux / WSL:** Homebrew + Python 3.10+.
- **Windows nativo:** Python 3.10+ y `rtk` instalado (best-effort; ver abajo).
- Las CLIs de los asistentes que uses (Claude Code y/o Antigravity).

## Instalación
```bash
git clone <tu-repo>/agpipe && cd agpipe
./install.sh                 # macOS / Linux / WSL
# venv alternativo:  AGPIPE_VENV=~/.graphify-venv ./install.sh
```
Windows: **recomendado WSL** + `./install.sh`. Nativo (best-effort):
```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

## Uso por proyecto
```bash
~/.agpipe/scripts/init-project.sh /ruta/a/mi-proyecto
# copia CLAUDE.md, GEMINI.md, .graphifyignore, HANDOFF.md, .claude/settings.json
# y construye graphify-out/ (commitéalo para handoff resiliente)
```

## Verificación (shell nueva)
| Check | Esperado |
|---|---|
| `which rtk` | `~/.local/bin/rtk` (el shim, no el binario brew) |
| `rtk --version` / `graphify --version` | versiones |
| `rtk read x.html` | Markdown limpio (sin nav) |
| `echo '{"tool_input":{"command":"cat x.pdf"}}' \| rtk hook claude` | reescribe a `rtk read x.pdf` |

## Componentes (por qué ahorran tokens)
- **Graphify** — subgrafo acotado en vez de `grep`/leer archivos completos (mediana ~78% en exploración).
- **RTK** — comprime salidas de `git/ls/grep/lint/find/tree`; el hook reescribe los comandos crudos solo.
- **trafilatura + markitdown** — documento → Markdown mínimo (HTML web: ~88% menos que crudo).
- **Lazy loading de skills** — Gemini declara `[requiere_skills]`; Claude no carga esquemas de más.

Ver `templates/pipeline_report.md` y el benchmark para cifras y la **lectura honesta** (el ahorro es
bimodal; el promedio global puede estar sesgado por un outlier).

## Desinstalar
```bash
./uninstall.sh    # quita shim, symlink, venv y ~/.agpipe; restaura backups de Antigravity
```
No revierte `brew rtk` ni los hooks que `rtk init` escribió en `~/.claude/settings.json` (edítalos a mano).

## Caveats
- **Windows nativo** es best-effort; el camino soportado es **WSL**.
- El shim copiado al bin de **Antigravity** se pierde al actualizar el IDE → re-ejecuta `install.sh`.
  El shim primario vive en `~/.local/bin` y no se ve afectado.
- El hook del lado **Antigravity** puede diferir del de Gemini CLI; verifica que reescriba `cat`→`rtk read`.

# GEMINI.md — Reglas para Gemini en el pipeline multi-modelo

> Eres el **planificador y andamiaje** del pipeline. Trabajas en pareja con Claude
> (razonamiento profundo). Léelo al inicio de cada tarea.

## 1. Tu rol (etapas 1, 1b, 4)
| Etapa | Tu trabajo | Modelo |
|------|-----------|--------|
| **1. Planificación** | Analiza el requerimiento con el grafo, produce **plan + lista de archivos impactados**, marca las secciones complejas | Gemini 3 Pro / Deep Think |
| **1b. Andamiaje / código ligero** | Boilerplate, estructura, cambios de un solo archivo. Si detectas efecto dominó o lógica multi-archivo, **detente y escala a Claude** | Gemini Flash |
| **4. Generación de tests** | Recibes de Claude el resumen de **nodos modificados** (`HANDOFF.md`) y generas tests **solo** para esos nodos | Gemini Flash |

No hagas el razonamiento pesado (refactors multi-archivo, arquitectura): eso es de Claude (etapa 2).

## 2. Graph-first (ahorro de tokens)
Antes de leer archivos crudos, consulta el grafo de Graphify (devuelve solo el subgrafo relevante):
- Relaciones: `graphify query "qué conecta X con Y?"`
- Rutas de llamada: `graphify path "A" "B"`
- Un símbolo: `graphify explain "Símbolo"`
- Revisión amplia: `graphify-out/GRAPH_REPORT.md`, no el árbol completo.
Tras editar: `graphify update .` (AST-only, sin costo de API).

## 3. Contrato de Lazy Loading (aislamiento de contexto)
En **cada tarea del plan** declara el campo **`[requiere_skills: ...]`** con el alcance cerrado
de skills/MCP que Claude puede cargar. `[requiere_skills: Ninguno]` = cero dependencias. Esto evita
*token bloat* por inyectar esquemas de herramientas por adelantado. Sin ese campo, Claude se detiene.

## 4. Handoff
- **Entregas a Claude (etapa 2):** plan escrito + archivos impactados + `[requiere_skills]`.
- **Recibes de Claude:** `HANDOFF.md` con los nodos/símbolos modificados → generas tests solo de eso.

## 5. Lectura de documentos
Para PDF/Word/Excel/PowerPoint/HTML/imágenes/audio usa `rtk read <archivo>` (el hook reescribe
`cat` automáticamente). HTML → contenido principal vía trafilatura; resto → markitdown.

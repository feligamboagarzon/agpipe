# Graph Report - agpipe  (2026-06-15)

## Corpus Check
- 19 files · ~9,718 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 111 nodes · 128 edges · 16 communities (13 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `9e5cc06c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]

## God Nodes (most connected - your core abstractions)
1. `CLAUDE.md — Reglas para Claude en el pipeline multi-modelo` - 11 edges
2. `agpipe — Pipeline de desarrollo multi-modelo, optimizado para tokens` - 9 edges
3. `main()` - 8 edges
4. `demo-tutorial.sh script` - 6 edges
5. `convert()` - 6 edges
6. `GEMINI.md — Reglas para Gemini en el pipeline multi-modelo` - 6 edges
7. `Informe Comprensivo: Pipeline de Desarrollo Optimizado (Antigravity Pipeline)` - 6 edges
8. `2. Tecnologías y Herramientas del Pipeline` - 6 edges
9. `install.sh script` - 5 edges
10. `get_compressed_text()` - 5 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (16 total, 3 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.12
Nodes (16): 1.1 Intercepción de Tareas sin Plan de Implementación (Ahorro de Costos), 1. Quién eres en este flujo, 2. Regla de oro: graph-first (ahorro de tokens), 3. Regla inquebrantable: Aislamiento de contexto (Lazy Loading), 4. Etapa 2 — Código pesado / complejo, 5. Etapa 5 — Ejecutar y corregir tests, 6. Protocolo de handoff, 7.1. Lectura por rangos, no archivos completos (idea 7) (+8 more)

### Community 1 - "Community 1"
Cohesion: 0.14
Nodes (13): 1. Arquitectura y Flujo de Trabajo Multi-Modelo, 2. Tecnologías y Herramientas del Pipeline, 3.1. Lectura honesta de las métricas agregadas, 3. Pruebas Empíricas y Métricas de Ahorro, 4. Instrucciones Específicas para Claude (Reglas de Compromiso), 5. Integración con TestSprite, A. Graphify (Exploración Local por Grafo), B. RTK (Rust Token Killer) (+5 more)

### Community 2 - "Community 2"
Cohesion: 0.28
Nodes (14): convert(), count_tokens(), emit(), exec_real_rtk(), find_real_rtk(), get_compressed_text(), is_project_initialized(), looks_like_self() (+6 more)

### Community 3 - "Community 3"
Cohesion: 0.20
Nodes (9): agpipe — Pipeline de desarrollo multi-modelo, optimizado para tokens, Caveats, Componentes (por qué ahorran tokens), Desinstalar, Instalación, Qué deja instalado, Requisitos, Uso por proyecto (+1 more)

### Community 4 - "Community 4"
Cohesion: 0.29
Nodes (6): 1. Tu rol (etapas 1, 1b, 4), 2. Graph-first (ahorro de tokens), 3. Contrato de Lazy Loading (aislamiento de contexto), 4. Handoff, 5. Lectura de documentos, GEMINI.md — Reglas para Gemini en el pipeline multi-modelo

### Community 5 - "Community 5"
Cohesion: 0.73
Nodes (5): backup(), ensure_path(), say(), warn(), install.sh script

### Community 6 - "Community 6"
Cohesion: 0.33
Nodes (5): Hook-Based Usage, Installation Verification, MarkItDown Integration (Document Conversion), Meta Commands (always use rtk directly), RTK - Rust Token Killer

### Community 7 - "Community 7"
Cohesion: 0.70
Nodes (4): say(), wait_enter(), warn(), test-demo.sh script

### Community 8 - "Community 8"
Cohesion: 0.52
Nodes (6): say(), start_tail(), stop_tail(), wait_enter(), warn(), demo-tutorial.sh script

### Community 9 - "Community 9"
Cohesion: 0.50
Nodes (3): Cómo usarla, Handoff <!-- fecha: YYYY-MM-DD · proyecto: <nombre> -->, HANDOFF — Resumen de nodos modificados (etapa 2 → etapa 4)

### Community 14 - "Community 14"
Cohesion: 0.40
Nodes (4): Meta Commands, RTK - Rust Token Killer (Google Antigravity), Rule, Why

### Community 15 - "Community 15"
Cohesion: 0.83
Nodes (3): clean_cmd(), main(), restore_cmd()

## Knowledge Gaps
- **45 isolated node(s):** `Rule`, `Meta Commands`, `Why`, `graphify`, `Qué deja instalado` (+40 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `Ruta a un ejecutable dentro del venv (bin/ en Unix, Scripts/ en Windows).`, `True si `path` es nuestro propio shim (evita recursión infinita).`, `Reporta el conteo de tokens: a stderr (terminal del agente, flushed) y a un` to the rest of the system?**
  _48 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.11764705882352941 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
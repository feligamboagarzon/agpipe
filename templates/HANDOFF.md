# HANDOFF — Resumen de nodos modificados (etapa 2 → etapa 4)

> Plantilla del **handoff por reporte commiteado** (idea 3). El agente de razonamiento
> profundo (Claude, etapa 2) la rellena tras editar, para que la generación de tests
> (etapa 4) actúe **solo sobre lo cambiado**, sin re-leer todo el módulo. Persiste en git:
> si un agente se cae a mitad de tarea, el siguiente retoma desde aquí sin recargar contexto caro.

## Cómo usarla
1. Tras terminar la etapa 2, duplica el bloque de abajo y rellénalo.
2. Commitéalo junto a `graphify-out/` actualizado (`graphify update .`).
3. La etapa 4 (tests) lee SOLO los nodos listados aquí.

---

## Handoff <!-- fecha: YYYY-MM-DD · proyecto: <nombre> -->

**Tarea:** _(una línea: qué pedía el plan de Gemini)_

**Nodos / símbolos modificados:**
| Nodo (símbolo) | Archivo:línea | Cambio | ¿Firma/contrato tocado? |
|---|---|---|---|
| `ej: publishNow()` | `src/lib/posts.ts:134` | _qué cambió_ | sí/no |

**Consumidores actualizados (efecto dominó):**
- `ruta` ← actualizado porque _…_  (usa `graphify path "A" "B"` para no dejar ninguno)

**Riesgos / pendientes para la etapa 4 (tests):**
- _casos límite a cubrir, migraciones, middleware afectado…_

**Comando de verificación sugerido:** `_(cómo correr la suite del proyecto)_`

---
*No re-generes este archivo entero cada vez: añade un bloque nuevo por tarea.*

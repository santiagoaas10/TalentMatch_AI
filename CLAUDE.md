# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Estado del repositorio

El repo está en **fase de especificación**: no hay código fuente, build system, tests ni manifiestos de dependencias todavía. Solo existen documentos de diseño para un proyecto de bootcamp de 8 semanas (TalentMatch AI).

Cuando arranque la implementación, actualizar este archivo con los comandos reales de build/lint/test/run.

Fuentes de verdad (en orden de prioridad):

- `BRIEF.md` — brief técnico: contexto, stack, modelo de datos, seguridad, constraints, Definition of Done.
- `ARCHITECTURE.md` — diagramas ASCII end-to-end de las 3 fases (onboarding, perfil semántico, matching).
- `README.md` — resumen breve y punteros. Menciona un `IMPLEMENTATION_PLAN.md` como próximo paso; **ese archivo todavía no existe en disco**.

La documentación está escrita en **español con términos técnicos en inglés**. Mantener ese estilo al editar o crear docs. Identificadores de código y comentarios inline van en inglés.

## Arquitectura — cómo se cumple el SLA de < 30s

El flujo end-to-end del agente (Fase 3 de `ARCHITECTURE.md`, pasos 5–7 del `BRIEF.md` §3.4) ocurre **dentro del request del usuario**: el agente fetchea, embebe, scorea y explica en una sola request síncrona. El target de < 30s se sostiene sobre **dos pilares no negociables**:

1. **Paralelización async de las 6 fuentes** (`fetch_jobs`). Jobicy, RemoteOK, Adzuna, YC Jobs, Startup Jobs y LinkedIn se consultan con `asyncio.gather`, no en serie. Hacerlas secuenciales rompe la SLA por sí solo.
2. **Caché agresivo de embeddings en pgvector**. Cada job ya visto se identifica por `(source, external_id)` y se reusa su embedding. La primera corrida es lenta; las siguientes pagan solo el costo de jobs nuevos.

Si en algún momento un cambio elimina la paralelización o reembebe jobs ya cacheados, la SLA y el budget de **$20/mes** dejan de cumplirse — ambos están atados a esos dos pilares.

**LLM solo en los extremos.** El modelo caro se usa exactamente dos veces:

- Extracción de perfil desde el CV (1 vez por usuario, con structured output a Pydantic).
- Explicación del match (1 llamada por job del top-N, paralelizable).

El matching central es cosine similarity sobre pgvector — matemática pura, sin LLM. No agregar llamadas al LLM en el camino caliente del scoring.

## Stack planeado (per `BRIEF.md` §3.2)

- **Backend:** Python 3.11 + FastAPI (async), Pydantic, LangChain/LangGraph para orquestar el agente.
- **Frontend:** Next.js 14 (App Router) + React, deploy en Vercel.
- **Datos:** PostgreSQL + pgvector (sin vector DB externa).
- **LLM/Embeddings:** abstracción LangChain (elección entre OpenAI GPT-4o y Claude 3.5 está pendiente); `text-embedding-3-small` para vectores.
- **PDF parsing:** PyMuPDF / pdfplumber.
- **Deploy:** Railway (backend + Postgres), Vercel (frontend), GitHub Actions para CI.
- **Tooling objetivo:** `ruff` + `black` + `mypy` + `pytest` (cobertura ≥ 80% en backend).

El provider de LLM debe ser intercambiable vía LangChain. **No hardcodear llamadas directas al SDK de OpenAI o Anthropic en código de negocio** — eso viola el constraint del `BRIEF.md` §4.2.

## Convenciones a respetar cuando aterrice el código

- **Structured output siempre.** El LLM retorna JSON parseado a modelos Pydantic, nunca texto libre + regex.
- **Prompts son archivos versionados** (`prompts/extract_profile.md`, `prompts/explain_match.md`), no strings inline. Así aparecen en los diffs.
- **Tools desacoplados.** `fetch_jobs`, `score_match`, `explain_match` deben ser modificables/agregables sin tocarse entre sí (Open/Closed). Agregar nueva fuente = nuevo conector y nada más.
- **JobListing guarda metadata + embedding**, no descripciones completas — constraint de TOS de las fuentes (`BRIEF.md` §4.2).
- **LinkedIn:** respetar `robots.txt` y rate limit (máx 50 jobs/hora por usuario).
- **Cascade-delete** en borrado de cuenta: perfil, embeddings, matches y sesiones de búsqueda asociadas al usuario.

## Constraints duros que moldean decisiones

- **< 30s** end-to-end de CV upload → primer resultado.
- **< $20/mes** de LLM con ~1.000 perfiles activos → caching de embeddings es obligatorio, no optimización futura.
- **< 1GB** de Postgres en el plan gratuito de Railway durante el curso.
- Rate limit de **20 req/min por IP** en endpoints públicos (`slowapi`).

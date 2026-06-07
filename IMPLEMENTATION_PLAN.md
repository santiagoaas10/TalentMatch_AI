# TalentMatch AI — Plan de Implementación

> Documento complementario a `BRIEF.md` y `ARCHITECTURE.md`. Define el breakdown semanal de tareas, entregables, dependencias y riesgos para las 8 semanas del bootcamp.

| Campo    | Detalle                          |
| -------- | -------------------------------- |
| Proyecto | TalentMatch AI                   |
| Autor    | Santiago                         |
| Versión  | 1.0 — Draft                      |
| Fecha    | Mayo 2026                        |
| Duración | 8 semanas                        |
| Etapa    | Implementation Plan (post-Brief) |

---

## 1. Resumen ejecutivo

El proyecto se ejecuta en **8 semanas** divididas en cuatro bloques lógicos:

| Bloque                     | Semanas | Foco                                                                          |
| -------------------------- | ------- | ----------------------------------------------------------------------------- |
| **Fundaciones**            | 1–2     | Setup repo, infra, CI, autenticación, upload de CV.                           |
| **Perfil semántico**       | 3       | Parsing del CV, extracción LLM con structured output, embedding del perfil.   |
| **Agente y matching**      | 4–5     | Conectores de fuentes con caché de embeddings + agente LangGraph + SLA < 30s. |
| **UX, hardening y demo**   | 6–8     | Dashboard, fuentes adicionales, observabilidad, deploy productivo, presentación. |

> **Principio guía:** el orden NO es negociable. Sin perfil semántico (S3) no hay vector para comparar. Sin conectores + caché (S4) no hay pool de jobs ni forma de cumplir la SLA. Sin agente cerrado (S5) no hay producto. Avanzar fuera de orden invalida la SLA de < 30s definida en `BRIEF.md` §4.2.

---

## 2. Semana 1 — Setup e infraestructura base

### Objetivo
Esqueleto del proyecto corriendo end-to-end (frontend ↔ backend ↔ DB ↔ CI) con `/health` desplegado en Railway y Vercel.

### Entregables
- Repositorio con estructura `backend/` + `frontend/` (monorepo), `.gitignore`, `.env.example`.
- Backend FastAPI con `/health → 200 OK`, Dockerfile, `pyproject.toml` (gestionado con `uv` o `poetry`).
- Frontend Next.js 14 (App Router) con página placeholder.
- PostgreSQL + extensión `pgvector` habilitada local (Docker Compose) y en Railway (`CREATE EXTENSION vector;`).
- GitHub Actions: workflow de `ruff` + `mypy` + `pytest` en cada PR.
- Deploy automático: backend → Railway, frontend → Vercel, en push a `main`.
- `.env.example` documentado.

### Dependencias
- Cuentas en Railway, Vercel, GitHub, OpenAI/Anthropic.
- Decisiones técnicas resueltas (ver §10).

### Riesgos
- **`pgvector` en Railway** puede requerir migración manual la primera vez. Mitigación: script SQL de bootstrap en el repo.
- **Doble deploy (Railway + Vercel)** suma complejidad de CI. Mitigación: dos workflows separados.

### Métrica de éxito
`curl https://<railway-url>/health` retorna `{"status":"ok"}` y `https://<vercel-url>` renderiza la landing.

---

## 3. Semana 2 — Autenticación y upload de CV

### Objetivo
Usuario se loguea con Google y sube un PDF que se persiste de forma segura.

### Entregables
- OAuth 2.0 con Google vía NextAuth.js (frontend) + verificación JWT en backend (`python-jose`).
- Modelo `User` en SQLAlchemy + primera migración Alembic.
- `POST /api/upload-cv` con validación: solo PDF, máx 5 MB, requiere auth.
- Almacenamiento del PDF (decisión pendiente §10: object storage vs filesystem).
- Frontend: login + uploader drag-and-drop con feedback de errores.
- Rate limiting con `slowapi` (20 req/min por IP en endpoints públicos).
- Tests: unit del validador de upload + integration del flow de auth.

### Dependencias
- Semana 1 cerrada.
- Credenciales OAuth Google configuradas.

### Riesgos
- **OAuth con dominios preview de Vercel** (cambian por PR). Mitigación: OAuth solo en prod + un dominio fijo de staging.
- **CORS entre Vercel y Railway.** Mitigación: orígenes permitidos configurados explícitamente desde día uno.

### Métrica de éxito
Demo: login con Google → upload de un PDF → registro visible en DB con `user_id` correcto.

---

## 4. Semana 3 — Construcción del perfil semántico (Fase 2 de ARCHITECTURE.md)

### Objetivo
Convertir un PDF en un vector de 1536 dimensiones guardado en pgvector, con revisión humana intermedia.

### Entregables
- Módulo `pdf_parser` (PyMuPDF) que extrae texto plano del CV.
- Módulo `profile_extractor`:
  - Prompt versionado en `prompts/extract_profile.md`.
  - Llamada al LLM con **structured output** (Pydantic schema `ExtractedProfile`).
  - Abstracción LangChain para que OpenAI ↔ Claude sean intercambiables.
- Modelo `CandidateProfile` con campos del `BRIEF.md` §3.3 + columna `embedding vector(1536)`.
- Endpoints `GET /api/profile` y `PUT /api/profile` para revisión/edición.
- Frontend: pantalla de revisión editable + formulario opcional (salario, modo de trabajo) + textarea de preferencias libres.
- Embedding del perfil completo (estructurado + enrichment) con `text-embedding-3-small`, guardado en pgvector.
- Tests unitarios del extractor con LLM mockeado: CV completo, minimalista, en español, en inglés.

### Dependencias
- Semana 2 cerrada (necesita `user_id` autenticado).
- Provider LLM decidido (§10).

### Riesgos
- **Calidad variable de extracción** según formato del CV. Mitigación: revisión humana obligatoria antes de embeddear; no se embebe nada que el usuario no haya confirmado.
- **Prompt injection** vía CV malicioso. Mitigación: sanitización del texto + delimitadores claros en el template.
- **Costo del LLM en iteración.** Mitigación: snapshots de respuestas LLM en disco para tests; nada de llamadas reales en cada run.

### Métrica de éxito
Para un set de 5 CVs reales: nombre correcto, skills con recall ≥ 80%, años de experiencia ±1, ≥ 2 roles previos extraídos.

---

## 5. Semana 4 — Conectores de fuentes y caché de embeddings

> **Semana crítica para la SLA.** El caché de embeddings que se construye acá es lo que hace alcanzable el target de < 30s en la S5.

### Objetivo
Tener conectores async paralelos a las 3 fuentes mínimas + módulo de caché de embeddings en pgvector que evite reembeber jobs ya vistos.

### Entregables
- Modelo `JobListing` con `source`, `external_id` (unique constraint con `source`), `embedding vector(1536)`, `fetched_at`.
- Conectores independientes en `app/sources/`:
  - `jobicy.py` — API pública, sin auth.
  - `remoteok.py` — API pública (`https://remoteok.com/api`).
  - `adzuna.py` — API con key (free tier 1000 calls/mes).
- Interfaz común `JobSource` (Protocol/ABC) — todos los conectores la implementan (Open/Closed).
- Función `fetch_all_sources()` que ejecuta los conectores en paralelo con `asyncio.gather`.
- Módulo `job_embedder` con lógica de caché:
  - Si `(source, external_id)` ya existe en `JobListing`, reusar embedding.
  - Si no, embeber y persistir antes de retornar.
- Persistencia: **solo metadata + embedding**, nunca `description` completo (constraint TOS `BRIEF.md` §4.2).
- Tests de integración por conector con **fixtures de respuesta HTTP** (sin hits reales en CI).
- Logging estructurado: jobs fetched, hits de caché, jobs nuevos, tiempo por fuente.

### Dependencias
- Semana 1 (DB + pgvector listos).
- API key de Adzuna obtenida.

### Riesgos
- **APIs externas cambian o caen.** Mitigación: conectores desacoplados; si Jobicy cae, el resto sigue.
- **Costo del primer fetch.** El primer fetch grande es caro. Mitigación: caché desde día uno + límite duro de jobs por corrida durante desarrollo.
- **Mediciones de latencia.** Mitigación: instrumentar tiempo por fuente desde el primer commit; sin números no hay forma de defender la SLA en S5.

### Métrica de éxito
- `fetch_all_sources()` retorna jobs de las 3 fuentes en **paralelo**, no en serie (verificable por logs de timestamp).
- En una segunda corrida sobre el mismo set, el cache hit rate sobre embeddings es > 90%.

---

## 6. Semana 5 — Agente LangGraph y SLA < 30s

### Objetivo
Cerrar el flujo de la Fase 3 de `ARCHITECTURE.md`: usuario hace click "Buscar empleos" → en < 30s recibe top N con score y explicación.

### Entregables
- Agente con LangGraph (o cadena LangChain simple si LangGraph es overkill al inicio) orquestando 3 tools:
  - **`fetch_jobs`** — wrappea `fetch_all_sources()` de S4.
  - **`score_match`** — cosine similarity nativa de pgvector:
    `SELECT ... ORDER BY embedding <=> :user_embedding LIMIT 20`.
  - **`explain_match`** — LLM con prompt `prompts/explain_match.md`. Llamadas paralelizadas con `asyncio.gather` (una por job del top-N, o batchear si el provider lo soporta).
- Endpoint `POST /api/search` que ejecuta el agente y retorna `[{job, score, reasons[]}]`.
- Modelo `JobMatch` para persistir resultados del top N por sesión.
- Modelo `SearchSession` para auditoría (`BRIEF.md` §3.3).
- Telemetría de tiempo por paso (fetch / score / explain) para validar la SLA.
- Tests:
  - Unit del scoring con vectores mockeados.
  - Integration del endpoint end-to-end con LLM mockeado.

### Dependencias
- Semana 3 cerrada (vector del perfil existe).
- Semana 4 cerrada (conectores + caché de embeddings funcionando).

### Riesgos
- **SLA < 30s fallando** por latencia del LLM. Mitigación: paralelizar `explain_match` desde el inicio, batchear si el provider lo permite, reducir top-N a 10 si hace falta.
- **Calidad de matches pobre** si el embedding del perfil no captura semántica relevante. Mitigación: A/B con distintos prompts de extracción en S3 antes de cerrar el formato del perfil.

### Métrica de éxito
- Para 10 perfiles de prueba, `POST /api/search` retorna en < 30s en p95.
- ≥ 7/10 evaluadores humanos califican el top 5 como "relevante".

---

## 7. Semana 6 — Dashboard y UX (Fase 3 de ARCHITECTURE.md)

### Objetivo
Frontend end-to-end usable: el usuario ve los matches, los entiende y puede actuar.

### Entregables
- Componente `JobCard` con título, empresa, ubicación, salario (si disponible), barra visual de score (0–100), razones del match.
- Acciones por job: **Guardar**, **Marcar como aplicado**, **Descartar** → `PATCH /api/matches/:id`.
- Estado persistido en `JobMatch.status` (`new` | `saved` | `applied` | `dismissed`).
- Dashboard con filtros y ordenamiento (por score, por fecha, por estado).
- Página "Mis aplicaciones" listando jobs `saved` y `applied`.
- Estados de loading, error y empty bien tratados.
- Diseño responsive (móvil + desktop).

### Dependencias
- Semana 5 cerrada (API retorna matches reales).
- Decisión de UI library (§10).

### Riesgos
- **Scope creep en diseño.** Mitigación: usar componentes de la librería elegida (shadcn/ui o similar), no diseñar desde cero.
- **Estado complejo del frontend.** Mitigación: `TanStack Query` o `SWR` para fetching + invalidación.

### Métrica de éxito
Demo navegable: login → upload → revisar perfil → buscar → guardar 3 jobs → marcar 1 como aplicado.

---

## 8. Semana 7 — Fuentes adicionales, observabilidad y hardening

### Objetivo
Llevar el sistema de "funciona" a "está listo para mostrar en público".

### Entregables
- Conectores adicionales (implementando la misma interfaz `JobSource` de S4): YCombinator Jobs, Startup Jobs, LinkedIn (scraping respetuoso, máx 50 jobs/h/user).
- Sentry integrado en backend y frontend.
- Logging estructurado con Loguru (INFO en prod, DEBUG en dev) — todo a stdout (12-Factor).
- Cobertura de tests del backend **≥ 80%** (`pytest --cov`).
- E2E test del flujo completo (Playwright o equivalente): login mock → upload CV fixture → buscar → assert ≥ 1 resultado.
- Performance tuning:
  - Índices en pgvector (`ivfflat` o `hnsw`) si el volumen lo justifica.
  - Validar que la SLA de S5 se mantiene con las fuentes adicionales activas.
- Auditoría de seguridad básica: CORS, headers (`secure`, `httpOnly` cookies), expiración JWT, sanitización de inputs.
- `README.md` final: descripción, diagrama de arquitectura, setup local en ≤ 5 pasos, link a la demo.

### Dependencias
- Semana 6 cerrada.

### Riesgos
- **LinkedIn scraping** puede romperse o violar TOS. Mitigación: respetar `robots.txt` + rate limit estricto; si no es factible en tiempo, dejarlo fuera del MVP y documentar como future work.
- **Cobertura 80%** es agresiva si no se instaló cultura de tests desde S2. Mitigación: medir coverage desde S2, no parche en S7.
- **SLA degrada con 6 fuentes activas.** Mitigación: medir y comparar contra los baselines de S5; si no entra en 30s, reducir top-N o paralelizar mejor.

### Métrica de éxito
- `pytest --cov` reporta ≥ 80%.
- Sentry recibe eventos de prueba sin errores.
- CI corre limpio (lint + typecheck + tests).
- `POST /api/search` sigue en < 30s p95 con las 6 fuentes activas.

---

## 9. Semana 8 — Deploy productivo, demo y presentación final

### Objetivo
Sistema corriendo en URLs públicas, presentación lista, repo entregable.

### Entregables
- Deploy productivo verificado en Railway + Vercel con dominio (o subdominio) estable.
- Backups diarios de la DB de Railway activos.
- `.env.example` completo y actualizado.
- Script de seed o instructivo para crear un usuario demo + perfil precargado (acelera la demo en vivo).
- Slide deck de presentación con:
  - Problema y solución (1 slide).
  - Diagrama de arquitectura (reutilizar el de `ARCHITECTURE.md`).
  - Demo en vivo (5 min).
  - Métricas (tiempo de respuesta, costo, accuracy).
  - Roadmap post-bootcamp (alertas por email, aplicación automática, etc.).
- Repo GitHub público (o compartido con el curso).
- Tag `v1.0.0` en el commit del estado entregable.

### Dependencias
- Semanas 1–7 cerradas.

### Riesgos
- **Bug crítico durante la demo en vivo.** Mitigación: ensayar la demo completa al menos 3 veces sobre la URL de producción, con el mismo usuario, en las 48h previas.
- **API key del LLM excede budget** justo antes de la demo. Mitigación: hard limit en la plataforma del provider + alerta a 80% del presupuesto.

### Métrica de éxito
Demo completa en < 5 minutos sin intervención manual, ejecutada sobre las URLs públicas, ante el evaluador del curso.

---

## 10. Decisiones técnicas pendientes

Resolver **antes de cerrar la semana 1**. Cada una afecta múltiples semanas posteriores.

| Decisión                | Opciones                                       | Bloquea semanas | Recomendación inicial                                                  |
| ----------------------- | ---------------------------------------------- | --------------- | ---------------------------------------------------------------------- |
| **Provider LLM**        | OpenAI GPT-4o · Anthropic Claude 3.5 · Mixto   | 3, 5            | Empezar con uno (más barato para iterar) y validar abstracción en S5.  |
| **Storage del CV**      | Filesystem Railway · S3-compatible · En memoria | 2               | Object storage (R2/B2) — el FS de Railway no persiste entre deploys.   |
| **UI Library**          | shadcn/ui · Mantine · Chakra · Tailwind puro   | 6               | shadcn/ui — buen balance velocidad/customización.                      |
| **Auth library**        | NextAuth.js · Auth0 · Clerk                    | 2               | NextAuth.js — gratis, suficiente para OAuth Google.                    |
| **State management FE** | TanStack Query · SWR · Redux Toolkit           | 6               | TanStack Query — moderno, fit natural con FastAPI.                     |
| **Orquestación agente** | LangGraph · LangChain chain simple             | 5               | Cadena LangChain simple al inicio; migrar a LangGraph solo si hace falta. |

---

## 11. Camino crítico

```
S1 (Setup) ──> S2 (Auth + Upload) ──> S3 (Perfil semántico) ──┐
                                                              │
S1 (Setup + DB) ──> S4 (Conectores + caché embeddings) ───────┤
                                                              ▼
                                                  S5 (Agente + SLA < 30s)
                                                              │
                                                              ▼
                                                       S6 (Dashboard)
                                                              │
                                                              ▼
                                            S7 (Hardening) ──> S8 (Deploy + Demo)
```

**Holguras:**

- S3 y S4 pueden paralelizarse parcialmente (perfil y conectores son independientes hasta el matching de S5).
- S5 NO puede comenzar sin S3 y S4 cerradas.
- Si S4 se atrasa, S5 se atrasa y el SLA puede no validarse a tiempo — riesgo directo para la demo final.

---

## 12. Matriz de riesgos transversales

| Riesgo                                          | Probabilidad | Impacto | Mitigación                                                                                     |
| ----------------------------------------------- | ------------ | ------- | ---------------------------------------------------------------------------------------------- |
| LLM excede budget mensual ($20)                 | Media        | Alto    | Hard limit en provider + caching agresivo de embeddings desde S3 y S4.                         |
| API de job source cae o cambia                  | Media        | Medio   | Conectores desacoplados; sistema funciona con cualquier subset de fuentes activas.             |
| Calidad de extracción de perfil baja            | Media        | Alto    | Revisión humana obligatoria; A/B de prompts; tests con CVs reales desde S3.                    |
| SLA < 30s incumplido                            | Media        | Alto    | Telemetría desde S4; `asyncio.gather` en fetch y explain; fallback a top-10.                   |
| Conectores en serie en lugar de paralelo        | Baja         | Crítico | Test específico en S4 que verifica que `fetch_all_sources` paraleliza (timestamps en logs).    |
| Demo final falla en vivo                        | Baja         | Crítico | Ensayos sobre URL productiva; usuario seed precargado; screencast de backup por si todo falla. |
| Cobertura de tests no llega a 80%               | Alta         | Medio   | Cultura de tests desde S2, no parche en S7.                                                    |

---

## 13. Definition of Done del plan (cruzar con `BRIEF.md` §5)

Al final de la semana 8 el proyecto se considera cerrado si:

- [ ] DoD funcional de `BRIEF.md` §5.1 cumplido en su totalidad.
- [ ] DoD de calidad de `BRIEF.md` §5.2 cumplido (cobertura, linter, tipos).
- [ ] DoD de despliegue de `BRIEF.md` §5.3 cumplido.
- [ ] DoD de presentación de `BRIEF.md` §5.4 cumplido.
- [ ] Las 6 decisiones técnicas de §10 documentadas con justificación final en el README o un ADR.
- [ ] Tag `v1.0.0` creado.

---

> **Siguiente paso:** ejecutar la semana 1 — setup del repositorio y resolución de las decisiones técnicas pendientes.

# TalentMatch AI — Setup de Tooling (Skills · MCPs · Subagents)

> Estas son las **skills, MCPs y subagents que se identificaron como útiles** para
> construir TalentMatch AI, basándonos en los documentos de diseño (`BRIEF.md`,
> `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`), en las `rules/` de aprendizaje del
> proyecto, y en cómo se equipan proyectos de software + AI Engineering similares.

| Campo    | Detalle                    |
| -------- | -------------------------- |
| Proyecto | TalentMatch AI             |
| Autor    | Santiago                   |
| Versión  | 1.0 — Draft                |
| Etapa    | Tooling setup (pre-código) |

---

## 0. El modelo mental (qué es cada cosa)

Tres conceptos distintos que conviene no mezclar:

- **Skill** (`/nombre`): un **workflow reutilizable** — pasos + instrucciones que
  Claude corre **dentro de la conversación principal**. Sirve para tareasß
  repetitivas con un patrón fijo (ej. _"creá un nuevo conector"_, _"corré el
  smoke test"_).
- **MCP** (Model Context Protocol): un **servidor externo que aporta herramientas
  nuevas** — conecta a Claude con sistemas reales (una base de datos, el
  navegador, una API). No es un workflow: es una **capacidad**.
- **Subagent**: una **instancia separada de Claude con su propia ventana de
  contexto**. Sirve para **delegar** tareas grandes o paralelas (research,
  auditoría, QA) sin ensuciar el contexto principal.

> Regla práctica: **MCPs = los sistemas que tocás · Skills = lo que hacés seguido
> con un patrón fijo · Subagents = roles que delegás en paralelo.**

Leyenda de estado en las tablas:

- _(built-in)_ — ya viene con Claude Code, listo para usar.
- _(crear)_ — hay que escribirlo como skill/subagent del proyecto.
- _(instalar)_ — hay que conectar el MCP server.

---

## 1. Skills (workflows que se ejecutan en la conversación)

| Función              | Skill                           | Qué hace                                                                                                                                                      |
| -------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Init**             | `/init` _(built-in)_            | Escanea el repo y genera/actualiza el `CLAUDE.md`.                                                                                                            |
| **Scaffold**         | `/scaffold` _(crear)_           | Genera boilerplate con tus convenciones (ej. nuevo conector `JobSource`, respetando Open/Closed).                                                             |
| **Ejecutar**         | `/run` _(built-in)_             | Levanta la app y la maneja para ver un cambio andando.                                                                                                        |
| **Verificar**        | `/verify` _(built-in)_          | Corre la app y observa el comportamiento real, no solo tests.                                                                                                 |
| **Smoke E2E (real)** | `/smoke` _(crear)_              | Inventa un personaje, genera su CV en PDF (synthetic data), lo sube y corre el flujo end-to-end con LLM y fuentes reales. Responde: ¿funciona o no? + ¿< 30s? |
| **Smoke E2E (CI)**   | `/e2e` _(crear)_                | Mismo recorrido pero con CV fixture + LLM mockeado + fuentes con fixtures HTTP. Determinístico, $0, corre en cada PR.                                         |
| **Logs / triage**    | `/check-logs` _(crear)_         | Lee stdout/stack traces, los traduce y te dice la causa probable.                                                                                             |
| **Lint + types**     | `/lint` _(crear)_               | Corre `ruff` + `black` + `mypy` y arregla lo que pueda — gate de calidad.                                                                                     |
| **Tests**            | `/test` _(crear)_               | Corre `pytest --cov`, reporta cobertura, señala gaps hacia el 80%.                                                                                            |
| **Debug**            | `/debug` _(crear)_              | Reproduce el bug → aísla → propone fix explicando la causa.                                                                                                   |
| **Refactor**         | `/simplify` _(built-in)_        | Limpia código por reuso/simplicidad sin cazar bugs.                                                                                                           |
| **Review**           | `/code-review` _(built-in)_     | Revisa el diff buscando bugs y mejoras.                                                                                                                       |
| **Seguridad**        | `/security-review` _(built-in)_ | OWASP web + LLM sobre el branch.                                                                                                                              |
| **Migración**        | `/migrate` _(crear)_            | Genera + aplica migración Alembic con tu convención.                                                                                                          |
| **Commit/PR**        | `/commit`, `/pr` _(crear)_      | Mensaje de commit convencional + abre PR con descripción.                                                                                                     |
| **Deps audit**       | `/audit-deps` _(crear)_         | Revisa vulnerabilidades de paquetes (supply chain — `security-practices.md`).                                                                                 |
| **Perf / SLA**       | `/benchmark` _(crear)_          | Mide p95 de `/api/search` y valida la SLA < 30s.                                                                                                              |
| **Eval (AI)**        | `/eval` _(crear)_               | Corre un eval set contra el LLM y reporta accuracy (recall de skills ≥ 80%).                                                                                  |
| **Docs / ADR**       | `/adr` _(crear)_                | Documenta una decisión técnica (las 6 pendientes de §10 del plan).                                                                                            |

**Notas de por qué importan acá:**

- `/smoke` y `/e2e` son la **"Métrica de éxito" de la Semana 5 vuelta ejecutable**:
  validan la SLA < 30s y el Definition of Done (`BRIEF.md` §5.1) en un comando.
  Son la mejor defensa contra el riesgo _"Demo final falla en vivo (Crítico)"_.
- `/lint`, `/test` y `/code-review` operacionalizan `engineering-practices.md`
  (SOLID, Clean Code, type hints, cobertura ≥ 80%).
- `/eval` y `/benchmark` son la **firma del AI Engineering**: medir accuracy y
  latencia en vez de _"parece que anda"_.

---

## 2. Subagents (roles delegados en su propio contexto)

Pensalos como **contratar especialistas** que trabajan aparte y te traen la conclusión.

| Rol                  | Subagent                       | Para qué                                                                                  |
| -------------------- | ------------------------------ | ----------------------------------------------------------------------------------------- |
| **Researcher**       | `Explore` _(built-in)_         | Barrer el repo ("¿dónde se usa el embedder?") sin llenar el contexto.                     |
| **Arquitecto**       | `Plan` _(built-in)_            | Diseñar la estrategia de cada semana antes de tocar código.                               |
| **Generalista**      | `general-purpose` _(built-in)_ | Tareas multi-paso de investigación.                                                       |
| **Debugger**         | `debugger` _(crear)_           | Caza un bug difícil end-to-end mientras seguís en otra cosa.                              |
| **Log/Error triage** | `triager` _(crear)_            | Lee montañas de logs/Sentry y resume _qué se rompió y por qué_.                           |
| **QA**               | `test-engineer` _(crear)_      | Escribe y corre tests con LLM mockeado, persigue la cobertura ≥ 80%.                      |
| **Security**         | `security-auditor` _(crear)_   | Auditoría afinada a tu threat model (prompt injection indirecta vía CV/jobs, SSRF, IDOR). |
| **Reviewer**         | `code-reviewer` _(crear)_      | Revisión de PR como un senior, en contexto aislado.                                       |
| **Performance**      | `perf-optimizer` _(crear)_     | Perfila y optimiza el camino caliente (la SLA < 30s).                                     |
| **Docs writer**      | `doc-writer` _(crear)_         | Mantiene README/ADRs/docstrings al día.                                                   |
| **Integraciones**    | `integrator` _(crear)_         | Implementa conectores a APIs externas (Jobicy, Adzuna, RemoteOK…).                        |
| **Upgrade/deps**     | `dependency-bot` _(crear)_     | Actualiza paquetes y arregla lo que rompa.                                                |

**Notas:** los built-in cubren research y arquitectura. Los de mayor valor a crear
son `security-auditor` (tu `security-practices.md` es agresiva y merece foco
dedicado) y `test-engineer` (la cobertura 80% es un riesgo de probabilidad "Alta"
en la matriz del plan).

---

## 3. MCPs (conexiones a sistemas reales = capacidades nuevas)

| Categoría        | MCP                                   | Qué te da                                                                                               |
| ---------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| **Datos**        | PostgreSQL + pgvector _(instalar)_    | Query directa: embeddings, cache hit rate, vector search (`embedding <=> :vec`). El motor del matching. |
| **Browser**      | Chrome DevTools _(ya conectado)_      | UI, E2E, `lighthouse_audit`, performance traces del lado cliente de la SLA.                             |
| **Docs en vivo** | Context7 / Ref _(instalar)_           | API actual de LangChain/FastAPI/Next 14, sin alucinar versiones viejas.                                 |
| **Repo/CI**      | GitHub _(instalar)_                   | PRs, issues, estado de GitHub Actions.                                                                  |
| **Errores/logs** | Sentry _(instalar, S7)_               | Lee excepciones reales de prod — el "mirá los logs" de verdad.                                          |
| **Tracing LLM**  | LangSmith _(instalar)_                | Traza cada paso del agente LangGraph y por qué decidió. Firma AI eng.                                   |
| **Deploy**       | Railway / Vercel _(instalar)_         | Logs de deploy, estado, env vars.                                                                       |
| **Contenedores** | Docker _(instalar)_                   | Manejar el Docker Compose (Postgres local + backend).                                                   |
| **Diseño**       | Figma _(instalar, S6)_                | Pasar diseño → componentes Next/shadcn.                                                                 |
| **Gestión**      | Linear / Jira / Slack _(instalar)_    | Tracking de tareas y avisos.                                                                            |
| **Cache**        | Redis _(opcional)_                    | Si sumás caché fuera de pgvector.                                                                       |
| **Web**          | `WebSearch` / `WebFetch` _(built-in)_ | Buscar y leer docs/recursos.                                                                            |

**Notas:** el de mayor valor de lejos es **Postgres + pgvector** — vas a inspeccionar
embeddings y cache constantemente. Para AI eng, **LangSmith** es el que más enseña
(ves el razonamiento del agente). GitHub y Railway/Vercel también se pueden manejar
por CLI (`gh`, `railway`, `vercel`) si preferís no sumar MCPs.

---

## 4. Cómo curar (no prender todo a la vez)

Cada MCP/skill cargado **pesa** (contexto + tokens). El arte no es activar todo,
sino **curar por fase** del `IMPLEMENTATION_PLAN.md`:

| Semana                      | Activar                                                             |
| --------------------------- | ------------------------------------------------------------------- |
| **S1 — Setup**              | MCP Postgres + Docker · MCP GitHub · skills `/lint` `/test`         |
| **S2 — Auth + Upload**      | subagent `security-auditor` (file upload, JWT) · skill `/migrate`   |
| **S3 — Perfil semántico**   | MCP Context7 + LangSmith · subagent `test-engineer` · skill `/eval` |
| **S4 — Conectores + caché** | subagent `integrator` · skill `/scaffold` (conectores)              |
| **S5 — Agente + SLA**       | skills `/smoke` `/e2e` `/benchmark` · subagent `perf-optimizer`     |
| **S6 — Dashboard/UX**       | MCP Chrome DevTools + Figma                                         |
| **S7 — Hardening**          | MCP Sentry · subagent `triager` · skill `/audit-deps`               |
| **S8 — Deploy + Demo**      | MCP Railway/Vercel · skills `/smoke` (ensayo de demo)               |

---

> **Siguiente paso:** a medida que cada semana arranque, creamos los skills/subagents
> _(crear)_ y conectamos los MCPs _(instalar)_ que correspondan, y recién ahí los
> ejecutamos sobre código real.

# Reglas del Agente — Manual operativo

> El **cómo trabajamos** en TalentMatch AI. Esta es la guía de operación del agente:
> es auto-contenida a propósito (repetir un principio acá está bien — lo que no se
> repite es el _código_). Las prácticas en detalle viven en las otras `rules/`
> (`engineering-practices`, `security-practices`, los `explain-*`) y en `BRIEF.md`.

# Onboarding

- **Proyecto:** TalentMatch AI — agente de búsqueda y match de empleos tech (CV → top-N de jobs con score y explicación, en < 30s).
- **Stack:** Python 3.11 + FastAPI (async) · Next.js 14 (App Router) + React · PostgreSQL + pgvector · LangChain/LangGraph.
- **LLM/Embeddings:** OpenAI GPT-4o + `text-embedding-3-small`, vía la abstracción de LangChain (swappable a Claude sin tocar negocio).
- **Auth:** NextAuth.js (Google OAuth) en el front + verificación JWT en el back. **UI:** shadcn/ui + Tailwind. **State FE:** TanStack Query. **Storage CV:** Cloudflare R2.
- **Gestor de paquetes:** `uv` (backend) · `npm` (frontend).
- **Estructura (monorepo):**
  - `/backend`: API FastAPI con Clean Architecture: `domain/` (modelos) · `application/` (servicios) · `infrastructure/` (APIs externas, DB) · `presentation/` (endpoints).
  - `/backend/app/sources`: un conector por fuente de jobs (interfaz `JobSource`).
  - `/frontend`: Next.js 14 — la UI que consume la API.
  - `/prompts`: prompts versionados (`extract_profile.md`, `explain_match.md`).
  - `/tests`: tests del backend (LLM mockeado).

# Comandos Críticos

- **Setup:** `uv sync` (backend) · `npm install` (frontend)
- **Dev:** `docker compose up -d` (Postgres + pgvector) · `uvicorn app.main:app --reload` (backend) · `npm run dev` (frontend)
- **Test:** `pytest --cov` (backend, objetivo de cobertura ≥ 80%)
- **Lint/Types:** `ruff check . && black . && mypy .`
- **DB:** `alembic revision --autogenerate -m "msg"` (crear migración) · `alembic upgrade head` (aplicar)

# Reglas de Agente

0. **Guia de produccion de codigo** No des mas de 300 lineas de codigo por iteracion, me ias danto los fragmentos de a poco para que sea facil de seguir y entender lo que esta pasando, recuerda que esto es un proyecto muy full stack en el que mi uno de mis objetivos principales para mi es aprender.
1. **Tool & Skill Discovery:** antes de planear, revisá tus herramientas, skills y subagents disponibles. Si existe una skill específica para la tarea (generar una migración, scaffoldear un conector, correr un eval), usala con prioridad para asegurar consistencia.
2. **Verificación delegada:** delegá SIEMPRE la validación de cualquier feature o bugfix al subagent `test-engineer` (rol QA). No des una tarea por cerrada sin su reporte.
3. **Estilo:** si `ruff`/`black`/`mypy` fallan, corregí. No inventes reglas de estilo: seguí la config existente.
4. **LLM intercambiable:** nunca hardcodear el SDK de OpenAI/Anthropic en código de negocio — siempre vía la abstracción LangChain (`BRIEF.md` §4.2).
5. **Constraints no negociables:** ningún cambio puede romper la SLA < 30s, el budget < $20/mes ni el caché de embeddings en pgvector. Si una decisión los toca, avisá antes de implementar.
6. **Modo aprendizaje:** explicá decisiones, patrones, tecnologías y errores según las `rules/explain-*`. El objetivo es que Santiago aprenda, no solo que el código funcione.

# Flujo de Implementación

Flujo obligatorio para cualquier implementación:

1. **Diseño y casos de uso:** entendé primero el escenario y dejá claros los criterios de aceptación para crear casos de prueba.
2. **Plan:** Haz el diseno y plan para crear los casos de prueba, siguiendo los requerimientos del BRIEF.md (seguiremos esa metodologia TDD no se si sea aplicable para este caso) (Tienes ya un IMPLEMENTATION_PLAN.md)
3. **Implementación:** Entendiendo los casos de prueba y el IMPLEMENTATION_PLAN.md, siguiendo las `rules/` de ingeniería y seguridad, implementa lo acordado.
4. **Verificación:** Corriendo los tests unitarios que se definieron bajo la metodologia TDD.

# Principios de Implementación

1. **DRY:** no repitas código; abstraé la lógica reutilizable (embedding y scoring centralizados, no copiados).
2. **Simplicidad primero (KISS / YAGNI):** evitá la sobre-ingeniería. La solución más simple suele ser la correcta; un patrón que no resuelve un problema real no va.
3. **TDD Pragmatico** Escribe los tests (o al menos define los casos de prueba) antes de escribir la implementacion.
4. **Structured output siempre:** el LLM devuelve JSON parseado a Pydantic, nunca texto libre + regex.
5. **Open/Closed en fuentes:** agregar una fuente de jobs = un conector nuevo que implementa `JobSource`, sin tocar el core.

# Debugging

Cuando se reporte un bug, **no intentes arreglarlo de inmediato**. Analizá la causa raíz, explicá el error (ver `rules/explain-errors`), En su lugar crea un test que reproduzca el bug, y entonces ahi si arreglalo

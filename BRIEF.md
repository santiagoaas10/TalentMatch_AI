# TalentMatch AI — Technical Brief

**Agente Inteligente de Búsqueda y Match de Empleos en Tech**

| Campo    | Detalle                                            |
| -------- | -------------------------------------------------- |
| Proyecto | TalentMatch AI                                     |
| Autor    | Santiago                                           |
| Versión  | 1.0 — Draft                                        |
| Fecha    | Mayo 2026                                          |
| Etapa    | Technical Brief (previo al Plan de Implementación) |

---

## 1. Título

**TalentMatch AI: Agente Inteligente de Búsqueda y Match de Empleos en Tech**

---

## 2. Contexto

El mercado laboral tech es altamente competitivo y asimétrico: los candidatos adaptan su perfil al mercado en lugar de que el mercado se adapte a ellos. Los profesionales invierten horas buscando manualmente en múltiples portales, ajustando CVs por oferta, y aplicando a posiciones que a menudo no son un buen fit real.

TalentMatch AI invierte este paradigma: el candidato sube su CV, responde preguntas opcionales de enriquecimiento, y el agente construye un perfil semántico profundo con el que busca, filtra y rankea oportunidades en tiempo real desde múltiples fuentes.

### 2.1 Problema

- Los buscadores de empleo pierden 5–10 horas semanales en búsqueda manual poco personalizada.
- Los portales actuales filtran por keywords, no por fit real de carrera.
- No existe una herramienta que construya el perfil del candidato desde su CV y lo use como vector de búsqueda continua.

### 2.2 Solución propuesta

> Un agente de IA que extrae el perfil del candidato desde su CV, lo enriquece con preguntas y preferencias libres, y ejecuta búsquedas semánticas continuas en múltiples fuentes de empleo, presentando resultados con score de match explicable.

### 2.3 Usuario objetivo

- Ingenieros de datos, ML engineers, y profesionales tech con 2–8 años de experiencia.
- Profesionales en transición de carrera dentro del ecosistema tech.
- Candidatos que buscan trabajo remoto internacional.

---

## 3. Requerimientos Técnicos

> **Arquitectura:** Fullstack Python + React | **Backend:** FastAPI | **Frontend:** Next.js | **Deploy:** Railway (backend) + Vercel (frontend) | **Patrón:** RAG + Agentic pipeline

### 3.1 Arquitectura General

**Diagrama de capas:**

1. **Frontend (Vercel)** — React/Next.js: Upload CV, formulario de enriquecimiento, dashboard de resultados con scores.
2. **API Gateway** — FastAPI: Endpoints REST para auth, perfil, búsqueda y resultados. Validación con Pydantic.
3. **Capa de IA** — LLM + Embeddings: Extracción de perfil desde CV (PDF parsing), generación de embeddings, scoring semántico.
4. **Capa de Datos** — PostgreSQL + pgvector: Perfil del usuario, historial de búsquedas, jobs cacheados.
5. **Capa de Integración** — Job Sources: Conectores a Jobicy, RemoteOK, Adzuna API, LinkedIn (scraping controlado), YCombinator Jobs, Startup Jobs.

### 3.2 Stack Tecnológico

| Capa            | Tecnología                 | Justificación                                               |
| --------------- | -------------------------- | ----------------------------------------------------------- |
| Backend         | Python 3.11 + FastAPI      | Alto rendimiento, async nativo, excelente para ML pipelines |
| Frontend        | React + Next.js 14         | SSR para SEO, App Router, compatible con Vercel             |
| Auth            | NextAuth.js / Auth0        | OAuth Google, manejo seguro de sesiones JWT                 |
| Base de datos   | PostgreSQL + pgvector      | Vector search nativo, sin necesidad de Pinecone externo     |
| LLM             | OpenAI GPT-4o / Claude 3.5 | A definir según costos; abstracción con LangChain           |
| Embeddings      | text-embedding-3-small     | Balance costo/calidad para perfil semántico                 |
| Orquestación IA | LangChain / LangGraph      | Manejo de agentes, tools, y pipelines RAG                   |
| PDF Parsing     | PyMuPDF / pdfplumber       | Extracción robusta de texto desde CVs                       |
| Deploy BE       | Railway                    | Simple, soporte Python nativo, variables de entorno         |
| Deploy FE       | Vercel                     | Integración nativa Next.js, previews automáticas            |
| CI/CD           | GitHub Actions             | Tests automáticos en PR, deploy on merge to main            |
| Monitoring      | Sentry + Loguru            | Error tracking y logs estructurados                         |

### 3.3 Modelo de Datos

**Entidades principales:**

- **User:** `id`, `email`, `provider` (Google/email), `created_at`, `updated_at`
- **CandidateProfile:** `user_id`, `raw_cv_text`, `extracted_skills[]`, `experience_years`, `seniority_level`, `preferred_roles[]`, `preferred_locations[]`, `salary_range`, `work_mode` (remote/hybrid/onsite), `embedding_vector`, `enrichment_notes`, `updated_at`
- **JobListing:** `id`, `source` (jobicy/remoteok/adzuna/linkedin/yc/startup), `external_id`, `title`, `company`, `location`, `description`, `tags[]`, `salary_range`, `url`, `embedding_vector`, `fetched_at`
- **JobMatch:** `id`, `user_id`, `job_id`, `match_score` (0.0–1.0), `match_reasons[]`, `status` (new/saved/applied/dismissed), `created_at`
- **SearchSession:** `id`, `user_id`, `query_snapshot`, `sources_used[]`, `jobs_found`, `timestamp`

### 3.4 Flujo del Agente (Pipeline IA)

1. **Ingest:** Usuario sube PDF del CV → PyMuPDF extrae texto limpio.
2. **Profile Extraction:** LLM analiza el texto y extrae entidades estructuradas (skills, experiencia, tecnologías, roles, educación).
3. **Enrichment:** Formulario opcional (preferencias, salario, tipo de trabajo) + campo de texto libre.
4. **Embedding:** Se genera un vector embedding del perfil completo y se guarda en pgvector.
5. **Job Fetching:** El agente consulta las fuentes configuradas (Jobicy, RemoteOK, Adzuna, YC Jobs, Startup Jobs, LinkedIn con rate limiting).
6. **Semantic Matching:** Cada job listing se embeds y se calcula cosine similarity contra el perfil del usuario.
7. **Ranking & Explanation:** Top N jobs son rankeados. El LLM genera una explicación breve del match para cada resultado.
8. **Presentación:** El dashboard muestra jobs con score visual, razones del match, y acciones (guardar, aplicar, descartar).

### 3.5 Requerimientos de Seguridad

- Autenticación vía OAuth 2.0 (Google) con JWT tokens — expiración 24h, refresh token seguro.
- HTTPS obligatorio en todos los endpoints (Railway y Vercel proveen TLS por defecto).
- Variables de entorno para todas las API keys — nunca en el código. Uso de Railway Secrets y Vercel Environment Variables.
- Rate limiting en endpoints públicos: max 20 req/min por IP (implementado con `slowapi`).
- Sanitización de inputs en el pipeline de parsing para evitar prompt injection.
- CORS configurado explícitamente — solo el dominio del frontend puede consumir la API.
- Los embeddings y datos personales se eliminan en cascada al borrar la cuenta.

### 3.6 Requerimientos de Despliegue

- **Backend en Railway:** servicio Docker con Dockerfile, health check en `/health`, variables de entorno por ambiente (dev/staging/prod).
- **Frontend en Vercel:** deploy automático en push a `main`, preview deployments en PRs.
- **Base de datos:** Railway Postgres plugin con backups diarios automáticos.
- **CI/CD:** GitHub Actions — lint + tests en cada PR, deploy automático a staging en merge a `develop`, manual a `prod`.
- Logs centralizados con Loguru — nivel INFO en producción, DEBUG en dev.

---

## 4. Constraints

### 4.1 Principios de Diseño de Software

- **SOLID:** Single Responsibility en cada módulo (ej: `ProfileExtractor` no hace fetching de jobs). Open/Closed para agregar nuevas fuentes sin modificar el core. Dependency Inversion para que los servicios dependan de abstracciones.
- **DRY:** Lógica de embedding y scoring centralizada en un módulo reutilizable.
- **Clean Architecture:** Separación clara entre dominio (modelos), aplicación (servicios), infraestructura (APIs externas, DB) y presentación (endpoints FastAPI).
- **12-Factor App:** Configuración por variables de entorno, stateless processes, logs a stdout.

### 4.2 Constraints Técnicos

- Tiempo de respuesta máximo del pipeline completo (CV upload → primer resultado): **< 30 segundos**.
- Costo mensual de LLM API: **< $20 USD** en uso normal (1,000 perfiles activos). Se debe implementar caching de embeddings.
- El agente no almacena contenido completo de job listings — solo metadata + embedding para respetar TOS de las fuentes.
- LinkedIn scraping debe ser respetuoso con rate limits y `robots.txt` — máximo 50 jobs/hora por usuario.
- El modelo LLM debe ser intercambiable (OpenAI ↔ Claude ↔ Open Source) mediante abstracción LangChain sin cambiar código de negocio.
- La base de datos no debe exceder 1GB en el plan gratuito de Railway durante el curso.

### 4.3 Constraints de Negocio / Curso

- **Scope del MVP en 8 semanas:** CV upload, extracción de perfil, matching semántico, y dashboard de resultados. Features secundarios (alertas email, aplicación automática) quedan fuera del alcance.
- El proyecto debe ser demostrable en un entorno público (URL accesible) para la presentación final.
- Documentación mínima: README con setup local, arquitectura en diagrama, y guía de uso.
- No se almacenan ni procesan datos de terceros sin consentimiento explícito.

### 4.4 Patrones de IA a Aplicar

- **RAG (Retrieval-Augmented Generation):** El agente recupera jobs relevantes usando vector similarity antes de generar explicaciones con el LLM.
- **Structured Output:** El LLM retorna JSON tipado (Pydantic models) para la extracción del perfil — nunca texto libre sin parsear.
- **Tool Use / Function Calling:** El agente orquesta tools independientes (`fetch_jobs`, `score_match`, `explain_match`) usando LangGraph.
- **Prompt Templates versionados:** Los prompts de extracción y scoring están en archivos separados, versionados en git.

---

## 5. Definition of Done

### 5.1 Criterios Funcionales

El trabajo se considera completado cuando:

- Un usuario puede registrarse y autenticarse con Google OAuth sin errores.
- El usuario puede subir un PDF de su CV (max 5MB) y el sistema extrae correctamente: nombre, skills, experiencia en años, tecnologías, y roles previos.
- El usuario puede revisar y corregir su perfil extraído antes de iniciar la búsqueda.
- El usuario puede agregar texto libre de preferencias y el sistema lo integra al embedding del perfil.
- El agente consulta al menos 3 fuentes de empleo (Jobicy, RemoteOK, Adzuna como mínimo) y retorna resultados en **< 30 segundos**.
- Cada resultado muestra: título, empresa, ubicación, salario estimado (si disponible), score de match (0–100), y al menos 2 razones del match generadas por LLM.
- El usuario puede guardar, marcar como aplicado, o descartar jobs desde el dashboard.
- El sistema funciona en producción (URLs de Railway y Vercel accesibles públicamente).

### 5.2 Criterios de Calidad y Testing

- La cobertura de tests es **>= 80%** en el backend (`pytest` + `coverage`).
- Los tests incluyen:
  - Unit tests para el pipeline de extracción de perfil.
  - Unit tests para la lógica de scoring semántico.
  - Integration tests para los conectores de cada fuente de empleo (mocked).
  - Integration tests para los endpoints de autenticación y perfil.
  - Al menos 1 end-to-end test del flujo completo (CV upload → resultados).
- Todos los endpoints de la API están documentados en el Swagger generado por FastAPI (`/docs`).
- El linter (`ruff`) y el formatter (`black`) pasan sin errores en todo el codebase.
- Los type hints están presentes en todas las funciones del backend y `mypy` no reporta errores críticos.

### 5.3 Criterios de Despliegue

- El pipeline de CI/CD ejecuta tests automáticamente en cada Pull Request y bloquea el merge si fallan.
- El backend responde con `200 OK` en el endpoint `/health` tras el deploy.
- Las variables de entorno están documentadas en un archivo `.env.example` (sin valores reales).
- El README incluye: descripción del proyecto, diagrama de arquitectura, instrucciones de setup local en < 5 pasos, y link a la demo en producción.

### 5.4 Criterios de Presentación Final (Semana 8)

- Demo en vivo: flujo completo desde CV upload hasta visualización de matches en < 5 minutos.
- El proyecto está disponible en GitHub (repositorio público o compartido con el curso).
- Slide de arquitectura incluida en la presentación final del curso.

---

> **Próximo paso:** Plan de Implementación — breakdown de tareas por semana, hitos, y asignación de esfuerzo para cada componente del sistema.

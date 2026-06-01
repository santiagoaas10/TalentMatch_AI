# TalentMatch AI — Arquitectura y Flujo del Sistema

> Documento complementario al `BRIEF.md`. Describe el flujo end-to-end del pipeline, fase por fase, con diagramas ASCII.

---

## Visión general del sistema

El sistema se divide en **3 fases** secuenciales desde el punto de vista del usuario:

1. **Onboarding** — autenticación y carga del CV.
2. **Construcción del perfil semántico** — parsing, extracción estructurada y embedding.
3. **Búsqueda, matching y presentación** — agente con tools, scoring vectorial y explicaciones LLM.

---

## FASE 1 — Onboarding

La primera vez que el usuario llega: se autentica y sube su CV.

```
┌──────────┐
│ USUARIO  │
└────┬─────┘
     │
     │  click "Login con Google"
     ▼
┌────────────────────┐
│  OAuth 2.0 Google  │ ---------> JWT token (sesión 24h)
└─────────┬──────────┘
          │
          ▼
   Usuario autenticado
          │
          │  arrastra su CV.pdf al uploader
          ▼
┌────────────────────────┐
│  Frontend Next.js      │ ---------> POST /api/upload-cv  (multipart)
└────────────────────────┘
```

**Tecnologías involucradas:** NextAuth.js / Auth0, FastAPI endpoint con validación Pydantic, almacenamiento cifrado del CV en reposo (AES-256).

---

## FASE 2 — Construcción del perfil semántico

Aquí "le enseñamos al sistema quién es el candidato". Es la fase más sensible: si el perfil queda mal extraído, todo el matching posterior falla.

```
   CV.pdf (binario)
        │
        ▼
┌────────────────────┐
│   PyMuPDF parser   │ ---------> texto plano del CV
└─────────┬──────────┘            (sin formato, solo el contenido)
          │
          ▼
┌─────────────────────────┐
│  LLM (GPT-4o / Claude)  │ ---------> JSON estructurado (Pydantic)
│   prompt: "extrae       │            {
│   skills, experiencia,  │              "name": "Santiago",
│   roles, tecnologías"   │              "skills": ["Python", "FastAPI"...],
└────────────┬────────────┘              "years_exp": 5,
             │                           "roles": ["ML Engineer"...]
             │                           ...
             ▼                          }
   ┌────────────────────────┐
   │  Pantalla de revisión  │ ---------> usuario corrige/confirma
   │  (editable por user)   │
   └────────────┬───────────┘
                │
                │  + formulario opcional (salario, remoto/híbrido, etc.)
                │  + texto libre ("quiero algo en startups early-stage")
                ▼
   ┌──────────────────────────────┐
   │  Perfil enriquecido (texto)  │
   └─────────────┬────────────────┘
                 │
                 ▼
   ┌────────────────────────────────┐
   │  Embedding API                 │ ---------> vector [0.23, -0.11, ..., 0.84]
   │  (text-embedding-3-small)      │            (1536 dimensiones)
   └─────────────┬──────────────────┘
                 │
                 ▼
   ┌──────────────────────────┐
   │  PostgreSQL + pgvector   │ ---------> guardado en tabla CandidateProfile
   └──────────────────────────┘
```

Al terminar esta fase, el sistema **"entiende"** al candidato como un vector matemático en un espacio de 1536 dimensiones. Cualquier job cuyo vector sea cercano (cosine similarity alto) va a hacer match.

**Por qué LLM + revisión humana:** la extracción nunca es perfecta. Permitirle al usuario corregir antes de embeddear evita arrastrar errores por todo el pipeline.

---

## FASE 3 — Búsqueda, matching y presentación

El corazón del agente. Aquí entra LangGraph orquestando tools independientes.

```
   Usuario hace click "Buscar empleos"
        │
        ▼
┌─────────────────────────────────────────────┐
│         AGENTE (LangGraph)                  │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │  Tool 1: fetch_jobs                 │    │
│  │  ────────────────────               │    │
│  │  consulta en paralelo:              │    │
│  │   ├─> Jobicy API                    │    │
│  │   ├─> RemoteOK API                  │    │
│  │   ├─> Adzuna API                    │    │
│  │   ├─> YC Jobs                       │    │
│  │   ├─> Startup Jobs                  │    │
│  │   └─> LinkedIn (rate limited)       │    │
│  └─────────────┬───────────────────────┘    │
│                │                            │
│                ▼  ~500 jobs crudos          │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │  Embedder                           │    │
│  │  ────────                           │    │
│  │  embeds cada job description        │    │
│  │  (o los recupera del caché)         │    │
│  └─────────────┬───────────────────────┘    │
│                │                            │
│                ▼  500 vectores              │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │  Tool 2: score_match (pgvector)     │    │
│  │  ──────────────────────────         │    │
│  │  cosine_similarity(                 │    │
│  │    user_vector,                     │    │
│  │    job_vector                       │    │
│  │  )  ---------> score 0.0–1.0        │    │
│  └─────────────┬───────────────────────┘    │
│                │                            │
│                ▼  ranking ordenado          │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │  Filtro Top N (ej. los 20 mejores)  │    │
│  └─────────────┬───────────────────────┘    │
│                │                            │
│                ▼                            │
│  ┌─────────────────────────────────────┐    │
│  │  Tool 3: explain_match (LLM)        │    │
│  │  ───────────────────────────        │    │
│  │  prompt: "dado el perfil X y el     │    │
│  │  job Y, genera 2-3 razones del      │    │
│  │  match en lenguaje natural"         │    │
│  │                                     │    │
│  │  ---------> "Tu experiencia en      │    │
│  │              FastAPI encaja con     │    │
│  │              su stack..."           │    │
│  └─────────────┬───────────────────────┘    │
│                │                            │
└────────────────┼────────────────────────────┘
                 │
                 ▼  jobs + score + explicación
   ┌───────────────────────────────────┐
   │  Dashboard (Next.js)              │
   │  ────────────────────             │
   │  - card por job                   │
   │  - barra visual del score (0-100) │
   │  - 2-3 razones del match          │
   │  - botones: guardar               │
   │             aplicado              │
   │             descartar             │
   └─────────────┬─────────────────────┘
                 │
                 ▼
   ┌──────────────────────────┐
   │  Estado en JobMatch DB   │ ---------> historial para el usuario
   └──────────────────────────┘
```

---

## TL;DR — el flujo en una sola línea

```
CV.pdf ---> texto ---> JSON perfil ---> vector ---> [match con jobs vectorizados]
                                                              │
                                                              ▼
                                              ranking ---> LLM explica ---> dashboard
```

---

## Por qué este diseño es elegante

- **Async donde importa:** las llamadas a las 6 fuentes de jobs corren en paralelo (FastAPI async), no en serie. Eso es lo que permite cumplir el constraint de **< 30 segundos** total.
- **Caché agresivo de embeddings:** los embeddings de jobs ya consultados se guardan en pgvector. La segunda vez que el sistema ve el mismo job de RemoteOK, no lo vuelve a embeddear → ahorras dinero (constraint **< $20/mes**).
- **LLM solo en los extremos:** el modelo caro (GPT-4o / Claude) solo se usa 2 veces — extraer perfil (1 vez por usuario) y explicar matches (1 vez por top-N jobs). El matching central es matemática pura sobre vectores → barato y rápido.
- **Tools independientes:** `fetch_jobs`, `score_match`, `explain_match` son módulos desacoplados (cumple SOLID / Open-Closed). Mañana agregas Indeed.com como fuente y solo tocas `fetch_jobs`, el resto no se entera.
- **Patrón RAG real:** el LLM nunca inventa ofertas. Solo razona sobre datos recuperados del vector store → sin alucinaciones, con explicabilidad.

---

## Mapeo arquitectura ↔ Brief

| Componente del diagrama | Sección del BRIEF |
|--------------------------|-------------------|
| OAuth Google + JWT | 3.5 Seguridad |
| Frontend Next.js + uploader | 3.1 (Capa 1) |
| FastAPI endpoints | 3.1 (Capa 2) |
| PyMuPDF + LLM extractor | 3.4 (pasos 1–2) |
| Embedding + pgvector | 3.1 (Capa 4), 3.4 (paso 4) |
| Agente con tools | 3.4 (pasos 5–7), 4.4 (Tool Use) |
| Dashboard de resultados | 3.1 (Capa 1), 5.1 (DoD funcional) |

---

> **Próximo documento:** `IMPLEMENTATION_PLAN.md` — breakdown semanal de tareas y hitos para las 8 semanas del bootcamp.

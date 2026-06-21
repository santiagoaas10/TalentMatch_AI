---
name: use-context7-mcp
description: Guía de uso del MCP Context7 en TalentMatch AI. Consulta la documentación actualizada de cualquier librería del stack ANTES de escribir código con ella. Triggers - "cómo funciona X en FastAPI", "documentación de LangChain", "API de Next.js", "cómo usar pgvector con SQLAlchemy", "sintaxis de Alembic", "LangGraph", "TanStack Query", "NextAuth", "Pydantic", "shadcn", "antes de implementar con".
---

# use-context7-mcp — Documentación actualizada del stack en tiempo real

Context7 es un MCP de Upstash que provee documentación **actualizada** de
librerías directamente en el contexto de Claude. Resuelve un problema crítico:
el conocimiento de Claude tiene una fecha de corte y las librerías del stack
(LangChain, LangGraph, Next.js 14, FastAPI) evolucionan rápido. Sin Context7,
Claude puede usar APIs deprecadas, parámetros renombrados o patrones que ya no
son la recomendación oficial.

> **Regla de oro:** si vas a escribir código con una librería del stack que no
> has usado en esta sesión, consultá su doc con Context7 primero. 30 segundos de
> consulta evitan 30 minutos de debugging de API incorrecta.

---

## Cómo funciona Context7 (dos pasos siempre)

Context7 expone dos herramientas que se usan en secuencia:

### Paso 1 — `resolve-library-id`
Convierte el nombre humano de una librería en su ID interno de Context7.

```
Herramienta: resolve-library-id
Input: { "libraryName": "fastapi" }
Output: { "id": "/tiangolo/fastapi", "name": "FastAPI", ... }
```

### Paso 2 — `get-library-docs`
Trae la documentación de esa librería, con un `topic` opcional para filtrar.

```
Herramienta: get-library-docs
Input: {
  "context7CompatibleLibraryID": "/tiangolo/fastapi",
  "topic": "dependency injection",   // opcional pero muy recomendado
  "tokens": 5000                     // cuántos tokens de doc traer (default 5000)
}
Output: documentación actualizada en markdown
```

---

## Mapa del stack — qué consultar y cuándo

### Backend — Python / FastAPI

| Librería | Cuándo consultar | Topic recomendado |
|---|---|---|
| **FastAPI** | Nuevo endpoint, middleware, CORS, rate limiting | `dependency injection`, `middleware`, `background tasks`, `lifespan` |
| **Pydantic v2** | Nuevo modelo de dominio, validators, structured output | `model validators`, `field`, `computed fields` |
| **SQLAlchemy 2.x** | Nuevo Repository, query async, relaciones | `async session`, `select`, `relationship` |
| **Alembic** | Crear o modificar migración | `autogenerate`, `op.add_column`, `batch operations` |
| **slowapi** | Rate limiting en endpoint nuevo | `limiter`, `key_func`, `decorator` |
| **PyMuPDF / pdfplumber** | Parseo de CV en PDF | `extract text`, `page`, `blocks` |

### IA / LLM

| Librería | Cuándo consultar | Topic recomendado |
|---|---|---|
| **LangChain** | Chains, prompts, output parsers | `chat models`, `prompt template`, `output parser`, `structured output` |
| **LangGraph** | Flujo del agente, nodos, estado | `state graph`, `add_node`, `conditional edges`, `checkpointer` |
| **pgvector (SQLAlchemy)** | Query de similitud, índice HNSW | `cosine distance`, `hnsw index`, `vector column` |
| **OpenAI (vía LangChain)** | Cambio de modelo, parámetros de embedding | `embeddings`, `chat openai`, `function calling` |

### Frontend — Next.js / React

| Librería | Cuándo consultar | Topic recomendado |
|---|---|---|
| **Next.js 14 App Router** | Nueva page, layout, server component, route handler | `app router`, `server components`, `route handlers`, `metadata` |
| **NextAuth.js v5** | Configuración OAuth, sesión, JWT | `providers`, `session`, `callbacks`, `middleware` |
| **TanStack Query v5** | Fetch de datos, mutations, caché | `useQuery`, `useMutation`, `invalidateQueries` |
| **shadcn/ui** | Nuevo componente UI | nombre del componente (`dialog`, `form`, `table`) |
| **Tailwind CSS** | Clases que no recordás | `utilities`, `responsive`, `dark mode` |

---

## Flujo de uso en cada feature

### Antes de implementar (obligatorio)

1. Identificar qué librerías toca la feature a implementar.
2. Para cada una que no se haya consultado en esta sesión, correr `resolve-library-id` + `get-library-docs` con el topic específico.
3. Leer el output y extraer: la firma de la función/clase, los parámetros actuales, el patrón recomendado.
4. Recién entonces escribir el código.

### Durante la implementación

- Si aparece un error de API (parámetro no reconocido, método no existe), consultar Context7 antes de intentar workarounds.
- Si la doc devuelta no cubre el caso, aumentar `tokens` a 8000-10000 para traer más contexto.

---

## Ejemplos concretos para TalentMatch AI

### Ejemplo 1: implementar el endpoint de upload de CV

```
1. resolve-library-id("fastapi")         → /tiangolo/fastapi
2. get-library-docs("/tiangolo/fastapi", topic="file upload")
3. resolve-library-id("pdfplumber")      → /jsvine/pdfplumber
4. get-library-docs("/jsvine/pdfplumber", topic="extract text")
```

### Ejemplo 2: implementar ProfileExtractor con structured output

```
1. resolve-library-id("langchain")
2. get-library-docs("<id>", topic="structured output")
   → muestra cómo usar .with_structured_output(PydanticModel)
3. resolve-library-id("pydantic")
4. get-library-docs("<id>", topic="model validators")
```

### Ejemplo 3: implementar la búsqueda por similitud con pgvector

```
1. resolve-library-id("pgvector")
2. get-library-docs("<id>", topic="cosine distance sqlalchemy")
   → muestra la sintaxis de <=> con SQLAlchemy async
```

### Ejemplo 4: crear la página de resultados en Next.js

```
1. resolve-library-id("nextjs")
2. get-library-docs("<id>", topic="server components data fetching")
3. resolve-library-id("tanstack query")
4. get-library-docs("<id>", topic="useQuery")
```

---

## Cuándo NO es necesario consultar Context7

- Para código Python puro (funciones, clases, iteradores básicos) — no cambia entre versiones.
- Para conceptos matemáticos (cosine similarity, normalización) — sin API.
- Para SQL estándar — su sintaxis es estable.
- Si ya consultaste la misma librería + topic en esta sesión y la doc no cambió.

El objetivo es no malgastar tokens en consultas innecesarias, pero tampoco asumir
que recordás la API correcta de una librería que cambia rápido (LangGraph cambió
su API significativamente entre 0.1 y 0.2, por ejemplo).

---

## Señales de que debiste haber consultado Context7

- `AttributeError` en un método de LangChain/LangGraph que "debería existir".
- Parámetro deprecation warning de Pydantic (`v1` vs `v2` validators).
- Error de Next.js de "use client" vs server component en un contexto inesperado.
- `TypeError` en la firma de una función de SQLAlchemy async.

Si aparece alguno de estos, el primer paso es Context7 — no StackOverflow ni
memoria de Claude.

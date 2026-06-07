# Explicar las tecnologías del stack (modo aprendizaje)

El usuario está aprendiendo desarrollo fullstack + AI Engineering y este proyecto
es su campo de entrenamiento. Cada vez que **introduzcas o trabajes con una
tecnología del stack por primera vez en la conversación**, explícala — no asumas
que ya la conoce.

## Qué explicar (breve, 2-4 líneas)
- **Qué es** la tecnología, en una frase simple.
- **Qué rol cumple** en TalentMatch AI concretamente (no en abstracto): dónde
  encaja en la arquitectura del `ARCHITECTURE.md`.
- **Por qué se eligió** aquí (qué problema resuelve frente a no usarla).
- Si aplica, cómo se relaciona con otra pieza del stack (ej. "FastAPI expone el
  endpoint que el frontend Next.js consume").

## Stack a cubrir cuando aparezca
- **Backend:** Python 3.11, FastAPI, async/`asyncio`, Pydantic, SQLAlchemy,
  Alembic, `slowapi`, Uvicorn.
- **IA:** LangChain/LangGraph, embeddings (`text-embedding-3-small`), pgvector,
  cosine similarity, RAG, structured output, PyMuPDF.
- **Frontend:** Next.js 14 (App Router), React, NextAuth.js, TanStack Query,
  shadcn/ui.
- **Datos/infra:** PostgreSQL, Docker, Railway, Vercel, GitHub Actions, OAuth
  2.0 / JWT, CORS.

## Cómo enseñar
- Distingue conceptos transversales (async, REST, ORM, vector search, SSR) de la
  herramienta concreta que los implementa — el usuario quiere entender el
  concepto, no solo la librería.
- No repitas la explicación de una tecnología que ya explicaste en la sesión, a
  menos que el usuario lo pida.

Estilo: español con términos técnicos en inglés. Didáctico pero conciso.

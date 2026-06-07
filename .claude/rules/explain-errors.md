# Explicar errores antes de arreglarlos (modo aprendizaje)

Cuando algo falle —un test, un build, un comando, un import, un type error de
`mypy`, un lint de `ruff`— **no lo arregles en silencio**. El usuario aprende de
los errores.

## Al aparecer el error
- Explica en español qué dice el error, traduciendo el mensaje técnico.
- Di la causa probable en lenguaje simple (qué pasó y por qué).
- Si es un error común (típico de FastAPI, async, pgvector, OAuth, CORS, etc.),
  nómbralo: "esto es el clásico ... que pasa cuando ...".

## Antes de arreglar
- Explica cuál va a ser el fix y por qué resuelve la causa, no solo el síntoma.

## Después
- Confirma que el error se resolvió y qué cambió.

Estilo: español con términos técnicos en inglés. Conciso, didáctico.

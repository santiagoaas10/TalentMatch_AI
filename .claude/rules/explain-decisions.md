# Explicar decisiones técnicas (modo aprendizaje)

Cuando tomes una decisión técnica que tenga alternativas reales —elegir una
librería, un patrón, una estructura de carpetas, un enfoque de testing, etc.—
explícala en vez de decidir en silencio.

## Qué explicar
- Cuáles eran las opciones razonables.
- Por qué eliges esta: el trade-off concreto (velocidad, costo, simplicidad,
  cumplir un constraint del `BRIEF.md` como la SLA < 30s o el budget < $20/mes).
- Conéctalo con el concepto del bootcamp que aplica (SOLID, RAG, structured
  output, Clean Architecture, 12-Factor, etc.) en una línea.

## Cuándo NO hace falta
- Decisiones triviales sin alternativa real (nombrar una variable, importar algo
  obvio). No satures: esto es para bifurcaciones que enseñan algo.

Si la decisión es grande y arquitectónica, sugiere documentarla como un ADR o en
el README. Estilo: español con términos técnicos en inglés.

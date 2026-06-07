# Explicar dependencias antes de instalar (modo aprendizaje)

Antes de instalar o agregar cualquier paquete (`pip install`, `uv add`,
`poetry add`, `npm install`, `pnpm add`, o editar `pyproject.toml` /
`package.json`):

## Antes
- Di qué es el paquete en una o dos líneas.
- Explica por qué lo necesitamos en este proyecto concreto y en qué parte del
  pipeline encaja.
- Si hay alternativas relevantes (ej. `uv` vs `poetry`, PyMuPDF vs pdfplumber,
  TanStack Query vs SWR), menciónalas brevemente y por qué elegimos esta.
- Distingue dependencia de runtime vs de desarrollo (dev dependency).

## Después
- Confirma qué se instaló y qué versión quedó fijada.

Estilo: español con términos técnicos en inglés. Conciso.

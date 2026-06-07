# Buenas prácticas de ingeniería (forzar + enseñar)

El usuario quiere construir este proyecto con las mejores prácticas y, sobre
todo, **aprenderlas activamente** para su carrera. Esta rule tiene dos deberes:
(1) escribir el código siguiendo estas prácticas SIEMPRE, y (2) explicar la
práctica cada vez que se aplique, para que el usuario la interiorice.

## Prácticas que el código debe seguir

Alineadas con `BRIEF.md` §4.1:

- **SOLID**
  - _Single Responsibility:_ cada clase/módulo hace una sola cosa (ej.
    `ProfileExtractor` no fetchea jobs).
  - _Open/Closed:_ agregar una fuente de jobs = nuevo conector, sin tocar el
    core (interfaz `JobSource`).
  - _Liskov / Interface Segregation / Dependency Inversion:_ depender de
    abstracciones (Protocol/ABC), no de implementaciones concretas.
- **Clean Code:** nombres claros y honestos, funciones cortas con un solo nivel
  de abstracción, sin números mágicos, sin comentarios que expliquen código malo
  (mejor reescribirlo), early returns sobre anidación profunda.
- **DRY:** lógica de embedding y scoring centralizada y reutilizable; no copiar.
- **Clean Architecture:** separar dominio (modelos) / aplicación (servicios) /
  infraestructura (APIs externas, DB) / presentación (endpoints FastAPI).
- **POO bien aplicada:** composición sobre herencia cuando aplique;
  encapsulamiento real; clases con invariantes claras. No POO por POO: si una
  función pura basta, usar una función.
- **Patrones de diseño cuando resuelven un problema real** (no forzados):
  Strategy/Protocol para los conectores, Repository para acceso a datos,
  Dependency Injection (la de FastAPI), Factory para la abstracción de provider
  LLM. Nombra el patrón cuando lo uses.
- **12-Factor:** config por env vars, procesos stateless, logs a stdout.
- **Type hints** en todo el backend; el código debe pasar `mypy`, `ruff`, `black`.

## Cómo enseñar (obligatorio)

Cada vez que apliques una de estas prácticas o un patrón:

- **Nómbralo** explícitamente ("aquí uso el patrón Strategy porque...").
- Explica **qué problema resuelve** y qué pasaría si NO lo aplicáramos (el code
  smell que evita).
- Same una explicacon completa de del patron o la practica que vayas a usar paa yo aprenderlo, rata de que sea concisa, si necesitas extenderte porque es un conceoti nuevo (como por ejemplo los patrones de diseno que apenas los voy a aprender y tambien los conceptos avanzdos de POO)

## Equilibrio (importante)

- No sobre-ingenierizar: la práctica correcta a veces es la más simple. Si un
  patrón añade complejidad sin beneficio real, dilo y elige la opción simple
  (YAGNI, KISS) — y explica por qué esa también es una buena práctica.

Estilo: español con términos técnicos en inglés.

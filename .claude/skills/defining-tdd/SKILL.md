---
name: defining-tdd
description: Flujo TDD de TalentMatch AI — delimita los casos de uso y escribe los tests ANTES de implementar (Red → Green → Refactor). Úsalo al arrancar cualquier feature, endpoint, conector de jobs, servicio o bugfix. Triggers - "implementar", "nueva feature", "nuevo endpoint", "nuevo conector", "TDD", "casos de prueba", "casos de uso", "arreglar bug".
---

# defining-tdd — Casos de uso y tests antes de implementar

Workflow obligatorio para construir cualquier cosa en TalentMatch AI siguiendo
**TDD pragmático**: primero se entiende el caso de uso, después se escriben los
tests (que fallan), y recién entonces se implementa. Codifica el "Flujo de
Implementación" de `.claude/rules/reglas-del-agente.md`.

> **Por qué TDD acá:** el test escrito primero es a la vez la *especificación
> ejecutable* del caso de uso y la red de seguridad contra regresiones. Si
> implementás primero, los tests terminan describiendo lo que el código *hace*
> (sesgo), no lo que *debería hacer*.

## Cuándo se dispara

- Antes de implementar un feature, endpoint, servicio, conector `JobSource`, o validador.
- Antes de arreglar un bug (primero un test que lo reproduce — ver §6).

## El ciclo

### 1. Delimitar el caso de uso (antes de tocar código)

Respondé y escribí explícitamente, como criterios de aceptación:

- **Input → Output esperado.** Qué entra, qué sale, qué tipos.
- **Casos:** happy path + edge cases + errores esperados.
- **Conexión con el diseño:** qué parte del `BRIEF.md` / `IMPLEMENTATION_PLAN.md` cubre.
- Si toca un constraint duro (SLA < 30s, budget, caché de embeddings), anotalo: puede necesitar un test de latencia o un assert de cache-hit.

No avances hasta tener esta lista. Es la spec.

### 2. RED — escribir los tests primero (deben fallar)

- Tests con `pytest` en `/tests`, espejando la estructura del código.
- **Nunca llamadas reales al LLM:** mockealo (respuesta snapshot / `unittest.mock`). Para conectores, **fixtures HTTP**, no hits reales.
- Para extracción de perfil, incluí los casos del plan: CV completo, minimalista, en español y en inglés, y uno con **prompt injection** (defensa: el output debe seguir siendo el schema Pydantic válido).
- Corré `pytest` → **deben fallar**. Un test que pasa sin implementación no prueba nada; confirmá que falla por la razón correcta.

### 3. GREEN — implementar lo mínimo para pasar

- El código mínimo que pone los tests en verde, siguiendo las `rules/` (SOLID, Clean Architecture, structured output).
- **Máx. 300 líneas por iteración** (regla 0 de `reglas-del-agente.md`): entregá en fragmentos y explicá lo que pasa.

### 4. REFACTOR — limpiar con los tests en verde

- Aplicá DRY, mejores nombres, early returns. Los tests siguen verdes = la red de seguridad funciona.

### 5. Verificar

- `pytest --cov` — cobertura objetivo ≥ 80%.
- Reportá qué casos quedaron cubiertos y cuáles no.

## Dónde TDD aplica limpio y dónde se adapta

Esto responde la duda de si TDD sirve para un proyecto con LLM:

- **Aplica limpio (lógica determinística):** scoring por cosine similarity, validadores de upload, repositorios, parsers de PDF, conectores con fixtures, lógica de caché. Acá TDD es directo: input → output exacto.
- **Se adapta (LLM no determinístico):** en `profile_extractor` / `explain_match` **no** testeás el texto exacto que devuelve el modelo (cambia entre corridas). Testeás el **contrato**: que el output parsea al schema Pydantic, que los campos requeridos están, que el mock se llamó con el prompt correcto. La *calidad* del output (recall de skills, relevancia) no es un unit test — va al skill `/eval`.

## Bugfix (§6)

Cuando se reporte un bug: **no lo arregles de una.** Analizá la causa raíz,
explicá el error (`rules/explain-errors`), **escribí primero un test que lo
reproduzca** (RED), y entonces sí implementá el fix hasta que pase (GREEN). Ese
test queda como regresión permanente.

## Qué se entrega al final

1. La lista de casos de uso / criterios de aceptación.
2. El/los archivo(s) de test en `/tests` (escritos primero).
3. La implementación que los pone en verde.
4. El reporte de `pytest --cov`.

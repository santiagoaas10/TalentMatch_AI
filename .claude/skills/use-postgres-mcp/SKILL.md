---
name: use-postgres-mcp
description: Guía de uso del MCP de PostgreSQL en TalentMatch AI. Úsalo antes de escribir o modificar cualquier modelo de datos, migración Alembic, Repository o query de pgvector. Triggers - "crear migración", "modificar tabla", "verificar schema", "query a la base", "pgvector", "embeddings en DB", "repository", "alembic", "inspeccionar DB".
---

# use-postgres-mcp — Cómo usar el MCP de Postgres en TalentMatch AI

El MCP de Postgres permite que Claude se conecte **directamente** a tu base de
datos local (o staging) y ejecute queries SQL sin que tengas que copiar y pegar
outputs del terminal. Esto elimina errores de "schema imaginado" y permite
validar queries reales antes de meterlas en el código.

> **Prerrequisito:** Docker corriendo con `docker compose up -d`. Si la DB no
> está levantada, el MCP no puede conectarse y falla silenciosamente.
> Verificar con: `docker ps | grep postgres`

---

## Cuándo activar esta skill (triggers)

| Situación | Qué hacer con el MCP |
|---|---|
| Vas a crear una migración Alembic | Inspeccionar el schema actual antes |
| Acabas de correr `alembic upgrade head` | Verificar que la tabla/columna se creó |
| Escribís un nuevo `Repository` | Validar la query contra el schema real |
| Implementás búsqueda por pgvector | Confirmar el índice HNSW y las dimensiones |
| Hay un bug de DB en producción/staging | Reproducir la query y ver el output real |
| Sospechás de datos corruptos | Inspeccionar registros directamente |

---

## Flujo obligatorio: ANTES de escribir código de DB

### Paso 1 — Verificar que la DB y la extensión están listas

```sql
-- ¿Está corriendo Postgres?
SELECT version();

-- ¿pgvector está instalado? (obligatorio para embeddings)
SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';
```

Si `vector` no aparece → correr `CREATE EXTENSION vector;` y avisarle al usuario.

### Paso 2 — Inspeccionar el schema actual

```sql
-- Ver todas las tablas del proyecto
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Ver columnas y tipos de una tabla específica
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'nombre_de_tabla'
ORDER BY ordinal_position;
```

### Paso 3 — Verificar migraciones aplicadas

```sql
-- Ver el historial de migraciones que Alembic ha aplicado
SELECT version_num, is_current FROM alembic_version;
```

---

## Flujo: DESPUÉS de correr `alembic upgrade head`

Siempre verificar que la migración se aplicó como se esperaba:

```sql
-- Confirmar que la tabla nueva existe
SELECT to_regclass('public.nombre_tabla') IS NOT NULL AS existe;

-- Confirmar columna específica con su tipo
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'nombre_tabla' AND column_name = 'nombre_columna';

-- Confirmar índices creados
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'nombre_tabla';
```

---

## Flujo específico: pgvector

Cada vez que trabajemos con embeddings en `job_listings` o `user_profiles`:

```sql
-- Verificar que la columna de embedding tiene el tipo correcto
SELECT column_name, data_type, udt_name
FROM information_schema.columns
WHERE table_name = 'job_listings' AND column_name = 'embedding';
-- udt_name debe ser 'vector'

-- Verificar dimensiones del embedding (debe ser 1536 para text-embedding-3-small)
SELECT vector_dims(embedding) AS dimensiones
FROM job_listings
WHERE embedding IS NOT NULL
LIMIT 1;

-- Verificar que el índice HNSW existe (crítico para la SLA < 30s)
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'job_listings' AND indexdef ILIKE '%hnsw%';

-- Probar una búsqueda por cosine similarity (reemplazar el vector de ejemplo)
-- Esto permite validar la query antes de meterla en el Repository
SELECT id, source, title,
       1 - (embedding <=> '[0.1, 0.2, ...]'::vector) AS score
FROM job_listings
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector
LIMIT 5;

-- Ver cuántos jobs tienen embedding cacheado vs. pendiente
SELECT
  COUNT(*) FILTER (WHERE embedding IS NOT NULL) AS con_embedding,
  COUNT(*) FILTER (WHERE embedding IS NULL)     AS sin_embedding
FROM job_listings;
```

> **Por qué el índice HNSW es crítico:** sin él, la búsqueda de similitud hace
> un scan secuencial de toda la tabla (O(n)). Con el índice HNSW, la búsqueda es
> aproximada pero O(log n) — la diferencia entre < 1s y > 30s con miles de jobs.

---

## Flujo: validar queries del Repository antes de escribirlas en Python

Antes de escribir el código SQLAlchemy de un `Repository`, probar la query raw en SQL:

```sql
-- Ejemplo: query del JobRepository.find_by_source_and_external_id
SELECT id, source, external_id, title, created_at
FROM job_listings
WHERE source = 'remoteok' AND external_id = 'job-123';

-- Ejemplo: query del UserRepository.get_active_profile
SELECT u.id, u.email, up.skills, up.embedding
FROM users u
JOIN user_profiles up ON up.user_id = u.id
WHERE u.id = '550e8400-e29b-41d4-a716-446655440000'
  AND u.deleted_at IS NULL;
```

Si la query SQL funciona y devuelve lo esperado → recién entonces escribir el
equivalente en SQLAlchemy. Esto evita bugs de ORM que son difíciles de debuguear.

---

## Flujo: verificar cascade-delete (BRIEF.md §3.5)

Al implementar borrado de cuenta, confirmar que todos los datos del usuario se eliminan:

```sql
-- Tras borrar un usuario, verificar que no quedan huérfanos
SELECT COUNT(*) FROM user_profiles WHERE user_id = 'uuid-del-usuario-borrado';
SELECT COUNT(*) FROM job_matches   WHERE user_id = 'uuid-del-usuario-borrado';
SELECT COUNT(*) FROM search_sessions WHERE user_id = 'uuid-del-usuario-borrado';
-- Todos deben devolver 0
```

---

## Guardrails de seguridad al usar este MCP

- **Solo leer en producción.** Nunca correr `UPDATE`, `DELETE` o `DROP` en la DB
  de producción con el MCP — solo `SELECT`. Las mutaciones van por Alembic + código.
- **No loguear connection strings.** El MCP toma `$POSTGRES_URL` del env; nunca
  pegar el valor real en el chat.
- **Datos de usuarios son PII.** Si inspeccionás registros reales de usuarios,
  no mostrarlos en el chat ni en commits — aplica `rules/security-practices`.

---

## Qué NO reemplaza este MCP

- No reemplaza los tests de `pytest` — el MCP valida el schema en desarrollo; los
  tests validan el comportamiento del código.
- No reemplaza Alembic — las migraciones siguen siendo el mecanismo de evolución
  del schema. El MCP solo inspecciona, no modifica estructura.

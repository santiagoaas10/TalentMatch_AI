---
name: commit-and-push
description: Hace git add + commit (con mensaje resumen autogenerado de lo trabajado) + push a la rama indicada (default main) en TalentMatch AI. Triggers - "commit and push", "haz commit y push", "commitea y pushea", "commit y push a <rama>", "sube los cambios".
---

# commit-and-push — Commit y push en un solo paso

Workflow para empaquetar el trabajo reciente en un commit con mensaje resumen y
subirlo al remoto. Lo dispara el usuario con frases como "commit and push",
"haz commit y push a main", o "commit y push a <rama>".

> **Autorización explícita:** el usuario configuró este skill a propósito para
> commitear y pushear cuando lo pide — incluido push directo a `main`. Por eso
> acá NO aplica el default de "crear branch antes de tocar la rama por defecto":
> el usuario lo pidió explícitamente. Aun así, se sigue la regla `git-explain`
> (explicar cada comando antes de correrlo).

## Determinar la rama destino

- Si el usuario nombra una rama ("...push a `develop`"), usar esa.
- Si no nombra ninguna ("commit and push" a secas), usar **`main`**.
- Antes de pushear, confirmar con `git branch --show-current` en qué rama estás.
  Si la rama destino pedida ≠ la rama actual, avisar al usuario y preguntar antes
  de hacer checkout (no cambiar de rama en silencio).

## El flujo (en orden)

### 1. Entender qué cambió (para el mensaje de commit)

Correr, explicando cada uno (regla `git-explain`):

- `git status` — ver qué archivos están modificados / nuevos / borrados.
- `git diff` y `git diff --staged` — ver el contenido real de los cambios.
- `git log --oneline -5` — ver el estilo de los últimos mensajes para mantener
  consistencia.

El mensaje de commit se redacta a partir de lo que **realmente** muestran estos
comandos, no de lo que se supone que se hizo.

### 2. Stage de los cambios

- `git add -A` para incluir todo lo trabajado (modificados, nuevos, borrados).
- Si hay archivos que claramente NO deben commitearse (`.env`, secretos, archivos
  temporales, `__pycache__`), **avisar y excluirlos** — no commitear secretos
  (regla `security-practices`: secrets siempre por env var, nunca en git).

### 3. Commit con mensaje resumen

- Redactar un mensaje **conciso y honesto** que resuma lo hecho hasta ese momento.
- Estilo: español con términos técnicos en inglés, alineado con el historial.
- Primera línea: resumen imperativo corto (≤ 72 chars). Si hace falta, cuerpo con
  bullets de los cambios principales.
- Terminar SIEMPRE el mensaje con la línea de co-autoría:

  ```
  Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
  ```

- Usar `git commit -m "..."` (con `-m` repetido para múltiples párrafos).

### 4. Push

- `git push origin <rama>` a la rama destino determinada arriba.
- Si la rama no tiene upstream configurado, usar `git push -u origin <rama>`.
- Explicar el comando antes (regla `git-explain`).

### 5. Reportar

Resumir qué pasó: hash del commit creado, mensaje usado, a qué rama se subió, y
confirmar que el push fue exitoso (o explicar el error si falló — regla
`explain-errors`).

## Guardas

- **No commitear si no hay cambios:** si `git status` está limpio, avisar y parar.
- **No pushear secretos ni `.env`.**
- **No hacer `--force`** salvo que el usuario lo pida explícitamente y entienda el
  riesgo (reescribe historial remoto).
- Si surge un conflicto o el push es rechazado (remoto adelante), explicar la
  causa y proponer `git pull --rebase` antes de reintentar — no forzar.

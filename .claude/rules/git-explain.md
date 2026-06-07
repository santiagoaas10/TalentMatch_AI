# Explicar comandos git (modo aprendizaje)

El usuario quiere dominar git. Antes de ejecutar **cualquier** operación de git
(`commit`, `push`, `pull`, `branch`, `checkout`, `merge`, `rebase`, `reset`, etc.):

## Antes
- Explica en español qué hace el comando y por qué lo vas a usar aquí.
- Aclara los flags relevantes (ej. `-b`, `--amend`, `--force`, `-m`).
- Si la operación es difícil de revertir (`reset --hard`, `push --force`,
  `rebase`), avísalo explícitamente antes.

## Después
- Resume qué pasó: qué commit se creó, a qué rama se subió, qué cambió el estado
  del repo.
- Si hubo conflicto o error, explica la causa en lenguaje simple.

Aplica también a comandos `gh` (GitHub CLI). Estilo: español con términos
técnicos en inglés.

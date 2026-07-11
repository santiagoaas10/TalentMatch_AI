---
name: executing-browser
description: Guía de uso del CLI agent-browser para automatizar y testear el frontend de TalentMatch AI. Úsalo para navegar páginas, interactuar con elementos, tomar screenshots, inspeccionar React y verificar comportamiento visual. Triggers - "abrir el browser", "screenshot de la app", "probar la UI", "verificar el frontend", "navegar a", "hacer click en", "inspeccionar el DOM", "test visual", "agent-browser", "automatizar el browser".
---

# executing-browser — Automatización de browser para TalentMatch AI

`agent-browser` es un CLI que controla Chrome de forma programática desde la
terminal, diseñado para agentes de AI. Permite navegar, interactuar, tomar
capturas y verificar el comportamiento real del frontend — sin abrir el browser
manualmente.

> **Regla de oro:** no reportes una tarea de UI como completa sin haberla
> verificado con el browser. `screenshot` + `snapshot` son la prueba de que
> funciona, no solo los tests unitarios.

---

## Concepto clave: daemon persistente

El browser NO se abre y cierra en cada comando. Corre como un **proceso daemon**
en background. Cada llamada se conecta a él — por eso podés encadenar comandos
con `&&` y el estado de la página se mantiene entre llamadas.

```bash
agent-browser open localhost:3000 && agent-browser snapshot -i
```

---

## Flujo estándar de verificación de UI

### 1. Abrir la app
```bash
agent-browser open http://localhost:3000
```

### 2. Capturar el árbol de elementos (para saber qué hay en pantalla)
```bash
agent-browser snapshot -i          # solo elementos interactivos (más limpio)
agent-browser snapshot             # árbol de accesibilidad completo
```
El snapshot devuelve `refs` como `@e1`, `@e2` — úsalos en los comandos siguientes
en lugar de selectores CSS frágiles.

### 3. Interactuar con elementos
```bash
agent-browser click @e2                    # click por ref (del snapshot)
agent-browser fill @e3 "test@email.com"    # limpiar y escribir en un input
agent-browser press Enter                  # tecla Enter
agent-browser find role button click --name "Submit"  # buscar por rol y nombre
```

### 4. Verificar visualmente
```bash
agent-browser screenshot                   # screenshot básico
agent-browser screenshot --annotate        # screenshot con etiquetas numeradas (ideal para debug)
```

### 5. Cerrar (opcional — el daemon se mantiene entre sesiones)
```bash
agent-browser close --all
```

---

## Comandos más usados en TalentMatch AI

### Navegación
```bash
agent-browser open http://localhost:3000          # página principal
agent-browser open http://localhost:3000/upload   # página de upload de CV
agent-browser back                                # volver atrás
agent-browser reload                              # recargar
```

### Formularios (upload de CV, búsqueda)
```bash
agent-browser upload @e1 ./tests/fixtures/cv_sample.pdf   # subir un PDF
agent-browser fill @e2 "Python developer"                 # llenar campo de búsqueda
agent-browser click @e3                                   # click en botón
agent-browser wait @e4                                    # esperar a que aparezca un elemento
agent-browser wait 2000                                   # esperar 2 segundos (página lenta)
```

### Obtener información de la página
```bash
agent-browser get text @e1          # texto de un elemento
agent-browser get url               # URL actual
agent-browser get title             # título de la página
agent-browser get value @e2         # valor de un input
```

### Verificar estado
```bash
agent-browser is visible @e1        # ¿el elemento está visible?
agent-browser is enabled @e2        # ¿el botón está habilitado?
```

---

## Inspección de React (frontend Next.js)

Activar React DevTools al abrir la página:
```bash
agent-browser --enable react-devtools open http://localhost:3000
```

Luego inspeccionar:
```bash
agent-browser react tree                    # árbol completo de componentes React
agent-browser react inspect <id>            # props, hooks y estado de un componente
agent-browser react renders start           # iniciar grabación de re-renders
agent-browser react renders stop            # parar y ver qué se re-renderizó
```

Útil para detectar re-renders innecesarios en los componentes de resultados
de matching o el dashboard.

---

## Performance y Core Web Vitals
```bash
agent-browser vitals http://localhost:3000
```
Devuelve LCP, CLS, TTFB, FCP, INP — métricas clave para verificar que el
frontend cumple el SLA de experiencia de usuario del BRIEF.

---

## Red y Network
```bash
agent-browser network requests                    # ver todas las requests de la página
agent-browser network requests --filter "/api/"  # filtrar por patrón
agent-browser console                             # ver logs del browser
agent-browser errors                              # ver errores de la página
```
Útil para verificar que el frontend está llamando a los endpoints correctos de la API.

---

## Modo AI (lenguaje natural)
```bash
agent-browser chat "sube el archivo tests/fixtures/cv.pdf y verifica que aparezcan resultados de matching"
```
El agente de AI decide qué comandos ejecutar. Útil para flujos complejos de
varios pasos. Para flujos más cortos, usar comandos directos — son más predecibles.

---

## Autenticación — reusar sesión de Chrome
```bash
# Reusar el perfil de Chrome del sistema (con Google OAuth ya logueado)
agent-browser --profile Default open http://localhost:3000

# Guardar y restaurar estado por nombre de sesión
agent-browser --session-name talentmatch open http://localhost:3000
```
Con `--profile Default`, Google OAuth de NextAuth.js funciona directamente sin
tener que hacer login manual cada vez.

---

## Tips de debug
```bash
agent-browser --headed open http://localhost:3000   # abrir con ventana visible (no headless)
agent-browser highlight @e1                         # resaltar un elemento en pantalla
agent-browser diff snapshot                         # comparar con el snapshot anterior
agent-browser doctor                                # diagnosticar problemas de instalación
```

---

## Encadenamiento — flujos de un solo comando
```bash
# Verificar flujo completo de onboarding
agent-browser open http://localhost:3000/upload \
  && agent-browser wait @e1 \
  && agent-browser upload @e1 ./tests/fixtures/cv_sample.pdf \
  && agent-browser wait 5000 \
  && agent-browser screenshot --annotate

# Verificar que la API responde desde el frontend
agent-browser open http://localhost:3000 \
  && agent-browser network requests --filter "/api/jobs" \
  && agent-browser get url
```

---

## Cuándo NO usar agent-browser

- Para verificar lógica de negocio pura (scoring, embeddings) — usar `pytest`.
- Para verificar el schema de la DB — usar el MCP de PostgreSQL (`use-postgres-mcp`).
- Para testear endpoints directamente — usar `curl` o el cliente HTTP de FastAPI (`/docs`).

`agent-browser` es para verificar **comportamiento visual y de usuario**, no
lógica interna.

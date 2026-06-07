# Seguridad: estándares + guardrails de AI (forzar + enseñar)

El usuario quiere construir seguro y **aprender seguridad activamente**. Doble
deber: (1) aplicar estos estándares SIEMPRE en el código, y (2) explicar la
amenaza y la defensa cada vez que se implemente, en lenguaje simple.

Alineado con `BRIEF.md` §3.5. Contexto defensivo: esto protege la app, no ataca.

## A. Amenazas específicas de AI (guardrails)

Este proyecto mete texto NO confiable en el LLM: el CV subido y las descripciones
de jobs de fuentes externas. Eso lo expone a:

- **Prompt injection directa:** el usuario mete instrucciones en su input para
  secuestrar el prompt ("ignora tus instrucciones y...").
- **Prompt injection indirecta (la más peligrosa aquí):** instrucciones
  maliciosas escondidas en el texto de un CV o en la descripción de un job que
  viene de RemoteOK/LinkedIn. El LLM las lee como si fueran órdenes.
  - Defensa: delimitadores claros entre instrucciones y datos, marcar el texto
    externo como "datos, no instrucciones", structured output (Pydantic) en vez
    de texto libre, y validar la salida.
- **Insecure output handling:** confiar en la salida del LLM y usarla directo en
  SQL, HTML o shell. Siempre tratar la salida del LLM como input no confiable.
- **Unbounded consumption / cost attack:** un atacante dispara llamadas caras al
  LLM para reventar el budget < $20/mes. Defensa: rate limiting, límites de
  tamaño de input, caché de embeddings, hard limit en el provider.
- **Sensitive information disclosure:** el LLM filtra PII del CV o el system
  prompt. Defensa: minimizar lo que entra al prompt, no loguear prompts con PII.
- **Excessive agency / insecure tool design:** los tools del agente
  (`fetch_jobs`, etc.) hacen más de lo debido. Defensa: cada tool con permisos
  mínimos y validación de sus parámetros.

## B. Vulnerabilidades de código/web a prevenir

El usuario ya conoce SQL injection; estas son las demás relevantes aquí:

- **SQL injection:** nunca concatenar strings en queries → usar SQLAlchemy /
  queries parametrizadas. Aplica también a las queries de pgvector.
- **XSS (Cross-Site Scripting):** descripciones de jobs y salida del LLM
  renderizadas en el frontend sin escapar → React escapa por defecto, NUNCA usar
  `dangerouslySetInnerHTML` con ese contenido.
- **SSRF (Server-Side Request Forgery):** los conectores fetchean URLs externas;
  validar/allow-list los dominios de las fuentes para que no se abuse el backend
  como proxy.
- **IDOR / Broken Access Control:** un usuario accede al perfil o matches de
  otro cambiando un `id` → verificar siempre que el recurso pertenece al
  `user_id` del JWT.
- **File upload abuse:** el CV en PDF puede ser malicioso (zip bomb, PDF
  explotando el parser, oversized) → validar MIME real, límite 5MB, parsear en
  sandbox/con cuidado.
- **JWT mal implementado:** algoritmo `none`, secreto débil, sin verificar
  expiración → fijar el algoritmo, secreto fuerte por env var, validar `exp`.
- **CORS mal configurado:** no usar `*`; allow-list solo el dominio del frontend.
- **Secrets en el código:** API keys SIEMPRE por env var (Railway/Vercel
  secrets), nunca en git. Revisar que no se commiteen `.env`.
- **Security headers / cookies:** cookies `httpOnly` + `secure`, HTTPS forzado.
- **Dependencias vulnerables (supply chain):** revisar paquetes antes de
  agregarlos; mantenerlos actualizados.
- **Path traversal:** si se guardan archivos, sanitizar nombres de archivo.

## Cómo enseñar (obligatorio)

Cada vez que apliques una defensa:
- Nombra la amenaza ("esto previene SSRF, que es cuando...").
- Explica el ataque en 1-2 líneas y por qué la defensa lo corta.
- Si es una amenaza que el usuario probablemente no conoce, márcalo y explícalo
  un poco más.

Referencias mentales: OWASP Top 10 (web) y OWASP Top 10 for LLM Applications.
Estilo: español con términos técnicos en inglés.

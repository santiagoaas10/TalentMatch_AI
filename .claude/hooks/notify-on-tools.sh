#!/usr/bin/env bash
# Stop hook — reproduce un sonido de notificación SOLO si el turno usó al
# menos una tool. No crea archivos en runtime: lee el transcript que Claude
# Code ya mantiene (su ruta llega en el payload del hook por stdin).

# El payload del Stop llega como JSON por stdin; extraemos la ruta del transcript.
transcript="$(jq -r '.transcript_path // empty')"
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

# ¿Hubo algún tool_use desde el último mensaje REAL del usuario?
# - Un mensaje de usuario real tiene content string, o un array cuyo primer
#   bloque NO es "tool_result" (los tool_result son salidas de tools, no input).
# - Tomamos el índice del último usuario real y miramos si algún assistant
#   posterior contiene un bloque "tool_use".
used_tool="$(jq -s -r '
  [ .[] | select(.type=="user" or .type=="assistant") ] as $m
  | ([ $m | to_entries[]
        | select(.value.type=="user"
                 and ((.value.message.content|type)=="string"
                      or ((.value.message.content[0]?.type) != "tool_result")))
        | .key ] | last // -1) as $u
  | [ $m[$u+1:][] | select(.type=="assistant") | .message.content[]?.type ]
  | any(. == "tool_use")
' "$transcript" 2>/dev/null)"

if [ "$used_tool" = "true" ]; then
  afplay /System/Library/Sounds/Glass.aiff
fi
exit 0

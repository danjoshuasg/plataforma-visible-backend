#!/bin/bash

# Script para obtener token JWT

USERNAME=${1:-testuser}
PASSWORD=${2:-testpass123}

echo "🔑 Obteniendo token para usuario: $USERNAME"

TOKEN_RESPONSE=$(curl -s -X POST http://localhost:8090/api/public/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}")

if [ $? -eq 0 ]; then
    ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.access_token')
    if [ "$ACCESS_TOKEN" != "null" ]; then
        echo "✅ Token obtenido:"
        echo "$ACCESS_TOKEN"
        
        # Guardar en archivo para uso posterior
        echo "$ACCESS_TOKEN" > .token
        echo "💾 Token guardado en archivo .token"
    else
        echo "❌ Error obteniendo token:"
        echo "$TOKEN_RESPONSE"
    fi
else
    echo "❌ Error conectando con la API"
fi
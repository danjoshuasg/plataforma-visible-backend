#!/bin/bash

# 🚀 DEPLOYMENT SCRIPT - Sistema Visible MIMP
# Para usar en VM Ubuntu con Docker ya instalado

set -e

echo "🚀 DESPLEGANDO SISTEMA VISIBLE MIMP EN VM..."
echo "=============================================="

# Colors
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Verificar Docker
print_info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado. Instálalo primero:"
    echo "curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "sudo sh get-docker.sh"
    echo "sudo usermod -aG docker \$USER"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose no está instalado. Instálalo primero:"
    echo "sudo apt-get update"
    echo "sudo apt-get install docker-compose-plugin"
    exit 1
fi

print_status "Docker y Docker Compose encontrados"

# Verificar si ya está ejecutándose
if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    print_warning "Sistema ya está ejecutándose. ¿Deseas reiniciarlo? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_info "Parando sistema actual..."
        docker-compose -f docker-compose.prod.yml down
    else
        print_info "Manteniendo sistema actual"
        exit 0
    fi
fi

# Limpiar contenedores anteriores si existen
print_info "Limpiando contenedores anteriores..."
docker-compose -f docker-compose.prod.yml down --remove-orphans 2>/dev/null || true

# Descargar imagen más reciente
print_info "Descargando imagen más reciente de Docker Hub..."
docker pull 92623745danjoshua/authplataformavisible:latest

# Iniciar servicios
print_info "Iniciando Sistema Visible MIMP..."
docker-compose -f docker-compose.prod.yml up -d

# Esperar a que los servicios estén listos
wait_for_service() {
    local service=$1 url=$2 name=$3 timeout=${4:-60}
    print_info "Esperando $name (max ${timeout}s)..."
    local count=0
    while ! curl -sf "$url" >/dev/null 2>&1; do
        echo -n "."
        sleep 2
        count=$((count + 2))
        if [ $count -ge $timeout ]; then
            print_error "$name timeout después de ${timeout}s"
            return 1
        fi
    done
    print_status "$name listo"
}

# Esperar servicios
print_info "Esperando que los servicios inicien..."
sleep 10

wait_for_service "keycloak" "http://localhost:8080/realms/demo-realm/.well-known/openid-connect/certs" "Keycloak" 90
wait_for_service "golang-api" "http://localhost:8090/api/public/health" "Golang API" 30  
wait_for_service "postgrest" "http://localhost:3000/" "PostgREST" 30
wait_for_service "nginx" "http://localhost/docs/api-docs.html" "Nginx" 20

# Mostrar estado
echo ""
print_status "¡Sistema Visible MIMP desplegado exitosamente!"
echo ""
echo "🔗 URLs disponibles:"
echo "  • Keycloak Admin:    http://$(hostname -I | awk '{print $1}'):8080/admin"
echo "  • Golang API:        http://$(hostname -I | awk '{print $1}'):8090/api/"
echo "  • PostgREST Visible: http://$(hostname -I | awk '{print $1}'):3000/"
echo "  • Documentación:     http://$(hostname -I | awk '{print $1}'/docs/api-docs.html"
echo ""
echo "👤 Usuarios del Sistema Visible:"
echo "  • admin@mimp.gob.pe / admin123 (Administrador)"
echo "  • editor@mimp.gob.pe / editor123 (Editor General)"
echo "  • observatorio@mimp.gob.pe / obs123 (Editor Observatorio)"
echo ""
echo "🛠️  Comandos útiles:"
echo "  • Ver logs:      docker-compose -f docker-compose.prod.yml logs -f [servicio]"
echo "  • Reiniciar:     docker-compose -f docker-compose.prod.yml restart"
echo "  • Parar todo:    docker-compose -f docker-compose.prod.yml down"
echo "  • Ver estado:    docker-compose -f docker-compose.prod.yml ps"
echo ""
echo "🧪 Para probar el sistema:"
echo "  • Ejecutar: curl -X POST http://localhost:8090/api/public/login \\"
echo "             -H 'Content-Type: application/json' \\"
echo "             -d '{\"username\":\"admin@mimp.gob.pe\",\"password\":\"admin123\"}'"
echo ""

# Mostrar información del sistema
print_info "Estado de contenedores:"
docker-compose -f docker-compose.prod.yml ps
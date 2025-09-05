# 🚀 Sistema Visible MIMP - Despliegue en VM

## 📦 Contenido del Paquete

Este paquete contiene todos los archivos necesarios para desplegar el Sistema Visible del MIMP en una VM Ubuntu.

### Archivos incluidos:
```
sistema-visible-vm/
├── docker-compose.prod.yml    # Configuración Docker para producción
├── .env.prod                  # Variables de entorno
├── readme-vm.md              # Este archivo
├── scripts/
│   └── deploy-vm.sh          # Script de deployment automático
├── init-db/
│   └── init.sql              # Esquema de base de datos del Observatorio Visible
├── keycloak/import/
│   └── realm-config.json     # Configuración Keycloak con usuarios MIMP
├── docs/
│   └── api-docs.html         # Documentación del sistema
└── nginx/
    └── nginx.conf            # Configuración Nginx

```

## 🔧 Requisitos en la VM

- **OS:** Ubuntu 18.04+ (recomendado 20.04 o 22.04)
- **Docker:** Versión 20.10+
- **Docker Compose:** Plugin v2
- **Puertos disponibles:** 80, 3000, 8080, 8090, 5432
- **RAM:** Mínimo 2GB (recomendado 4GB)
- **Disco:** Mínimo 5GB libres

## 🚀 Instrucciones de Despliegue

### 1. Preparar la VM

```bash
# Instalar Docker (si no está instalado)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Reiniciar sesión o ejecutar:
newgrp docker

# Verificar instalación
docker --version
docker compose version
```

### 2. Desplegar el Sistema

```bash
# Extraer archivos
tar -xzf sistema-visible-vm.tar.gz
cd sistema-visible-vm

# Ejecutar deployment
chmod +x scripts/deploy-vm.sh
./scripts/deploy-vm.sh
```

### 3. Verificar Despliegue

El script mostrará las URLs disponibles. Por ejemplo:
```
🔗 URLs disponibles:
• Keycloak Admin:    http://192.168.1.100:8080/admin
• Golang API:        http://192.168.1.100:8090/api/
• PostgREST Visible: http://192.168.1.100:3000/
• Documentación:     http://192.168.1.100/docs/api-docs.html
```

### 4. Probar el Sistema

```bash
# Test de login con usuario MIMP
curl -X POST http://localhost:8090/api/public/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@mimp.gob.pe","password":"admin123"}'
```

## 👥 Usuarios del Sistema Visible

| Usuario | Contraseña | Rol | Nivel de Acceso |
|---------|------------|-----|-----------------|
| `admin@mimp.gob.pe` | `admin123` | Administrador | Nivel 1 (Completo) |
| `editor@mimp.gob.pe` | `editor123` | Editor General | Nivel 2 (Edición) |
| `observatorio@mimp.gob.pe` | `obs123` | Editor Observatorio | Nivel 3 (Específico) |

## 🏛️ Módulos del Observatorio

El sistema incluye 6 módulos temáticos del MIMP:

1. **NNA** - Niñas, Niños y Adolescentes
2. **VIOLENCIA_MUJER** - Violencia contra la mujer  
3. **DISCAPACIDAD** - Personas con discapacidad
4. **ADULTO_MAYOR** - Adultos mayores
5. **FAMILIA** - Fortalecimiento familiar
6. **ACOSO_POLITICO** - Prevención del acoso político

## 🛠️ Comandos Útiles

```bash
# Ver estado de servicios
docker compose -f docker-compose.prod.yml ps

# Ver logs
docker compose -f docker-compose.prod.yml logs -f [servicio]

# Reiniciar servicio específico  
docker compose -f docker-compose.prod.yml restart [servicio]

# Parar todo el sistema
docker compose -f docker-compose.prod.yml down

# Actualizar imagen de la API
docker pull 92623745danjoshua/authplataformavisible:latest
docker compose -f docker-compose.prod.yml up -d --no-deps golang-api
```

## 🔧 Troubleshooting

### Puertos ocupados
```bash
# Verificar qué está usando un puerto
sudo netstat -tlnp | grep :8080

# Liberar puerto si es necesario
sudo kill -9 <PID>
```

### Reiniciar completamente
```bash
# Parar y limpiar todo
docker compose -f docker-compose.prod.yml down --volumes
docker system prune -f

# Volver a desplegar
./scripts/deploy-vm.sh
```

### Verificar logs de errores
```bash
# Logs de todos los servicios
docker compose -f docker-compose.prod.yml logs

# Logs de servicio específico
docker compose -f docker-compose.prod.yml logs keycloak
docker compose -f docker-compose.prod.yml logs golang-api
```

## 🔐 Seguridad

- Cambiar contraseñas por defecto en `.env.prod` antes de producción
- El sistema usa emails institucionales `@mimp.gob.pe`
- Tokens JWT con expiración de 30 minutos
- Row Level Security (RLS) en PostgreSQL
- Health checks en todos los servicios

## 📊 APIs Disponibles

- **PostgREST:** Acceso directo a tablas del Observatorio Visible
- **Golang API:** Autenticación y endpoints protegidos  
- **Documentación interactiva:** En `/docs/api-docs.html`

## 📞 Soporte

Para actualizar la aplicación, simplemente:
1. Hacer push de nueva imagen a Docker Hub
2. En la VM ejecutar: `docker pull 92623745danjoshua/authplataformavisible:latest`  
3. Reiniciar: `docker compose -f docker-compose.prod.yml up -d --no-deps golang-api`
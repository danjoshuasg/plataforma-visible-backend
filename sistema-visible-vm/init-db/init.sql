-- =====================================================
-- SISTEMA DE AUTENTICACIÓN VISIBLE - OBSERVATORIO MIMP
-- =====================================================

-- Crear roles para PostgREST
CREATE ROLE web_anon nologin;
CREATE ROLE authenticated noinherit;
CREATE ROLE admin noinherit;

-- Otorgar permisos
GRANT web_anon TO authuser;
GRANT authenticated TO authuser;
GRANT admin TO authuser;

-- Crear schema para API
CREATE SCHEMA api;
GRANT usage ON SCHEMA api TO web_anon, authenticated, admin;

-- =====================================================
-- CATÁLOGOS Y LOOKUPS
-- =====================================================

CREATE TABLE api.rol (
    id_rol SMALLINT PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(200),
    nivel_acceso SMALLINT NOT NULL, -- 1=Admin, 2=Editor General, 3=Editor Observatorio
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT uk_rol_codigo UNIQUE(codigo)
);

CREATE TABLE api.tipo_modulo (
    id_tipo_modulo SMALLINT PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    orden_presentacion SMALLINT,
    icono VARCHAR(50),
    color_tema VARCHAR(7), -- Hex color
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE api.tipo_submodulo (
    id_tipo_submodulo SMALLINT PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    ruta_url VARCHAR(100),
    orden_presentacion SMALLINT,
    icono VARCHAR(50),
    requiere_moderacion BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE
);

-- =====================================================
-- ENTIDADES PRINCIPALES
-- =====================================================

CREATE TABLE api.usuario (
    id_usuario SERIAL PRIMARY KEY,
    correo_institucional VARCHAR(150) NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    id_rol SMALLINT NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_ultima_sesion TIMESTAMP,
    ip_ultima_sesion INET,
    intentos_fallidos SMALLINT DEFAULT 0,
    bloqueado_hasta TIMESTAMP,
    token_recuperacion VARCHAR(255),
    token_expiracion TIMESTAMP,
    requiere_cambio_password BOOLEAN DEFAULT FALSE,
    created_by INTEGER,
    updated_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES api.rol(id_rol),
    CONSTRAINT fk_usuario_created_by FOREIGN KEY (created_by) REFERENCES api.usuario(id_usuario),
    CONSTRAINT fk_usuario_updated_by FOREIGN KEY (updated_by) REFERENCES api.usuario(id_usuario),
    CONSTRAINT chk_correo_mimp CHECK (correo_institucional LIKE '%@mimp.gob.pe')
);

CREATE TABLE api.modulo (
    id_modulo SERIAL PRIMARY KEY,
    id_tipo_modulo SMALLINT NOT NULL,
    slug VARCHAR(50) NOT NULL UNIQUE,
    titulo VARCHAR(200) NOT NULL,
    descripcion_breve VARCHAR(500),
    descripcion_completa TEXT,
    imagen_hero VARCHAR(255),
    publicado BOOLEAN DEFAULT FALSE,
    fecha_publicacion TIMESTAMP,
    metadata_seo JSONB, -- {title, description, keywords, og_image}
    configuracion_storytelling JSONB, -- {sections: [{title, content, media}]}
    created_by INTEGER,
    updated_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_modulo_tipo FOREIGN KEY (id_tipo_modulo) REFERENCES api.tipo_modulo(id_tipo_modulo),
    CONSTRAINT fk_modulo_created_by FOREIGN KEY (created_by) REFERENCES api.usuario(id_usuario),
    CONSTRAINT fk_modulo_updated_by FOREIGN KEY (updated_by) REFERENCES api.usuario(id_usuario)
);

CREATE TABLE api.submodulo (
    id_submodulo SERIAL PRIMARY KEY,
    id_modulo INTEGER NOT NULL,
    id_tipo_submodulo SMALLINT NOT NULL,
    publicado BOOLEAN DEFAULT FALSE,
    fecha_publicacion TIMESTAMP,
    configuracion_especifica JSONB, -- Configuraciones específicas por tipo
    orden_personalizado SMALLINT,
    created_by INTEGER,
    updated_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_submodulo_modulo FOREIGN KEY (id_modulo) REFERENCES api.modulo(id_modulo) ON DELETE CASCADE,
    CONSTRAINT fk_submodulo_tipo FOREIGN KEY (id_tipo_submodulo) REFERENCES api.tipo_submodulo(id_tipo_submodulo),
    CONSTRAINT fk_submodulo_created_by FOREIGN KEY (created_by) REFERENCES api.usuario(id_usuario),
    CONSTRAINT fk_submodulo_updated_by FOREIGN KEY (updated_by) REFERENCES api.usuario(id_usuario),
    CONSTRAINT uk_submodulo_modulo_tipo UNIQUE(id_modulo, id_tipo_submodulo)
);

-- =====================================================
-- PUBLICACIONES
-- =====================================================

CREATE TABLE api.tipo_publicacion (
    id_tipo_publicacion SMALLINT PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(500),
    icono VARCHAR(50),
    orden_presentacion SMALLINT,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE api.publicacion (
    id_publicacion SERIAL PRIMARY KEY,
    id_modulo INTEGER NOT NULL,
    id_tipo_publicacion SMALLINT NOT NULL,
    titulo VARCHAR(500) NOT NULL,
    autor VARCHAR(300) NOT NULL,
    anio_publicacion SMALLINT NOT NULL,
    resumen TEXT,
    archivo_path VARCHAR(500),
    archivo_size_mb DECIMAL(10,2),
    archivo_mime_type VARCHAR(100),
    url_externa VARCHAR(500),
    es_archivo_local BOOLEAN DEFAULT TRUE,
    publicado BOOLEAN DEFAULT FALSE,
    fecha_publicacion TIMESTAMP,
    vistas_contador INTEGER DEFAULT 0,
    descargas_contador INTEGER DEFAULT 0,
    created_by INTEGER NOT NULL,
    updated_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_publicacion_modulo FOREIGN KEY (id_modulo) REFERENCES api.modulo(id_modulo),
    CONSTRAINT fk_publicacion_tipo FOREIGN KEY (id_tipo_publicacion) REFERENCES api.tipo_publicacion(id_tipo_publicacion),
    CONSTRAINT fk_publicacion_created_by FOREIGN KEY (created_by) REFERENCES api.usuario(id_usuario),
    CONSTRAINT fk_publicacion_updated_by FOREIGN KEY (updated_by) REFERENCES api.usuario(id_usuario),
    CONSTRAINT chk_publicacion_anio CHECK (anio_publicacion >= 1900 AND anio_publicacion <= EXTRACT(YEAR FROM CURRENT_DATE) + 1)
);

-- =====================================================
-- SESIONES
-- =====================================================

CREATE TABLE api.sesion_usuario (
    id_sesion BIGSERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL,
    token_sesion VARCHAR(255) NOT NULL UNIQUE,
    ip_origen INET NOT NULL,
    user_agent TEXT,
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_ultimo_acceso TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP NOT NULL,
    activa BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_sesion_usuario FOREIGN KEY (id_usuario) REFERENCES api.usuario(id_usuario) ON DELETE CASCADE
);

-- =====================================================
-- HABILITAR RLS (Row Level Security)
-- =====================================================

ALTER TABLE api.usuario ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.modulo ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.submodulo ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.publicacion ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.sesion_usuario ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLÍTICAS DE SEGURIDAD
-- =====================================================

-- Usuarios anónimos pueden leer catálogos
CREATE POLICY "Anonymous can read roles" ON api.rol
    FOR SELECT TO web_anon USING (activo = true);

CREATE POLICY "Anonymous can read tipo_modulo" ON api.tipo_modulo
    FOR SELECT TO web_anon USING (activo = true);

CREATE POLICY "Anonymous can read tipo_submodulo" ON api.tipo_submodulo
    FOR SELECT TO web_anon USING (activo = true);

CREATE POLICY "Anonymous can read tipo_publicacion" ON api.tipo_publicacion
    FOR SELECT TO web_anon USING (activo = true);

-- Usuarios anónimos pueden leer contenido publicado
CREATE POLICY "Anonymous can read published modulos" ON api.modulo
    FOR SELECT TO web_anon USING (publicado = true);

CREATE POLICY "Anonymous can read published submodulos" ON api.submodulo
    FOR SELECT TO web_anon USING (publicado = true);

CREATE POLICY "Anonymous can read published publicaciones" ON api.publicacion
    FOR SELECT TO web_anon USING (publicado = true);

-- Usuarios autenticados pueden ver sus propios datos
CREATE POLICY "Users can view their own data" ON api.usuario
    FOR SELECT TO authenticated 
    USING (id_usuario = (current_setting('request.jwt.claims', true)::json->>'user_id')::INTEGER);

CREATE POLICY "Users can update their own data" ON api.usuario
    FOR UPDATE TO authenticated 
    USING (id_usuario = (current_setting('request.jwt.claims', true)::json->>'user_id')::INTEGER);

-- Usuarios autenticados pueden leer todo el contenido
CREATE POLICY "Authenticated can read all modulos" ON api.modulo
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated can read all submodulos" ON api.submodulo
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated can read all publicaciones" ON api.publicacion
    FOR SELECT TO authenticated USING (true);

-- Editores pueden crear y modificar contenido según su nivel
CREATE POLICY "Editors can manage modulos" ON api.modulo
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM api.usuario 
            WHERE id_usuario = (current_setting('request.jwt.claims', true)::json->>'user_id')::INTEGER
            AND id_rol IN (1, 2) -- Admin o Editor General
        )
    );

-- Administradores pueden hacer todo
CREATE POLICY "Admins can do everything on usuario" ON api.usuario
    FOR ALL TO admin USING (true) WITH CHECK (true);

CREATE POLICY "Admins can do everything on modulo" ON api.modulo
    FOR ALL TO admin USING (true) WITH CHECK (true);

-- =====================================================
-- PERMISOS EN TABLAS
-- =====================================================

-- Catálogos - lectura para todos
GRANT SELECT ON api.rol TO web_anon, authenticated, admin;
GRANT SELECT ON api.tipo_modulo TO web_anon, authenticated, admin;
GRANT SELECT ON api.tipo_submodulo TO web_anon, authenticated, admin;
GRANT SELECT ON api.tipo_publicacion TO web_anon, authenticated, admin;

-- Contenido principal
GRANT SELECT ON api.modulo TO web_anon, authenticated;
GRANT SELECT ON api.submodulo TO web_anon, authenticated;
GRANT SELECT ON api.publicacion TO web_anon, authenticated;

GRANT ALL ON api.modulo TO admin;
GRANT ALL ON api.submodulo TO admin;
GRANT ALL ON api.publicacion TO admin;

-- Usuarios
GRANT SELECT, UPDATE ON api.usuario TO authenticated;
GRANT ALL ON api.usuario TO admin;

-- Sesiones
GRANT SELECT, INSERT, UPDATE ON api.sesion_usuario TO authenticated, admin;

-- Secuencias
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA api TO authenticated, admin;

-- =====================================================
-- VISTAS PARA API
-- =====================================================

-- Vista para módulos públicos con información agregada
CREATE VIEW api.modulos_publicos AS
SELECT 
    m.id_modulo,
    m.slug,
    m.titulo,
    m.descripcion_breve,
    m.imagen_hero,
    tm.nombre as tipo_modulo,
    tm.color_tema,
    tm.orden_presentacion,
    m.fecha_publicacion,
    COUNT(DISTINCT s.id_submodulo) as total_submodulos
FROM api.modulo m
JOIN api.tipo_modulo tm ON m.id_tipo_modulo = tm.id_tipo_modulo
LEFT JOIN api.submodulo s ON m.id_modulo = s.id_modulo AND s.publicado = true
WHERE m.publicado = true
GROUP BY m.id_modulo, m.slug, m.titulo, m.descripcion_breve, m.imagen_hero, tm.nombre, tm.color_tema, tm.orden_presentacion, m.fecha_publicacion
ORDER BY tm.orden_presentacion, m.titulo;

GRANT SELECT ON api.modulos_publicos TO web_anon, authenticated, admin;

-- Vista para estadísticas del usuario autenticado
CREATE VIEW api.mis_estadisticas AS
SELECT 
    u.id_usuario,
    u.nombres || ' ' || u.apellidos as nombre_completo,
    r.nombre as rol,
    COUNT(DISTINCT m.id_modulo) as modulos_asignados,
    COUNT(DISTINCT p.id_publicacion) as publicaciones_creadas
FROM api.usuario u
JOIN api.rol r ON u.id_rol = r.id_rol
LEFT JOIN api.modulo m ON m.created_by = u.id_usuario
LEFT JOIN api.publicacion p ON p.created_by = u.id_usuario
WHERE u.id_usuario = (current_setting('request.jwt.claims', true)::json->>'user_id')::INTEGER
GROUP BY u.id_usuario, u.nombres, u.apellidos, r.nombre;

GRANT SELECT ON api.mis_estadisticas TO authenticated;

-- =====================================================
-- FUNCIONES RPC
-- =====================================================

-- Función para obtener perfil del usuario
CREATE OR REPLACE FUNCTION api.get_user_profile()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    user_id INTEGER;
BEGIN
    -- Obtener user ID del JWT
    user_id := (current_setting('request.jwt.claims', true)::json->>'user_id')::INTEGER;
    
    SELECT json_build_object(
        'id_usuario', u.id_usuario,
        'nombre_completo', u.nombres || ' ' || u.apellidos,
        'correo', u.correo_institucional,
        'rol', r.nombre,
        'nivel_acceso', r.nivel_acceso,
        'activo', u.activo,
        'fecha_ultima_sesion', u.fecha_ultima_sesion
    ) INTO result
    FROM api.usuario u
    JOIN api.rol r ON u.id_rol = r.id_rol
    WHERE u.id_usuario = user_id;
    
    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION api.get_user_profile() TO authenticated;

-- Función para obtener módulos del observatorio
CREATE OR REPLACE FUNCTION api.get_modulos_observatorio()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id_modulo', m.id_modulo,
            'slug', m.slug,
            'titulo', m.titulo,
            'descripcion', m.descripcion_breve,
            'tipo', tm.nombre,
            'color_tema', tm.color_tema,
            'submodulos', (
                SELECT json_agg(
                    json_build_object(
                        'id_submodulo', s.id_submodulo,
                        'tipo', ts.nombre,
                        'ruta_url', ts.ruta_url,
                        'icono', ts.icono
                    )
                )
                FROM api.submodulo s
                JOIN api.tipo_submodulo ts ON s.id_tipo_submodulo = ts.id_tipo_submodulo
                WHERE s.id_modulo = m.id_modulo AND s.publicado = true
                ORDER BY ts.orden_presentacion
            )
        )
        ORDER BY tm.orden_presentacion
    ) INTO result
    FROM api.modulo m
    JOIN api.tipo_modulo tm ON m.id_tipo_modulo = tm.id_tipo_modulo
    WHERE m.publicado = true;
    
    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION api.get_modulos_observatorio() TO web_anon, authenticated;

-- =====================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

CREATE INDEX idx_usuario_correo ON api.usuario(correo_institucional);
CREATE INDEX idx_usuario_rol ON api.usuario(id_rol) WHERE activo = TRUE;
CREATE INDEX idx_modulo_publicado ON api.modulo(publicado) WHERE publicado = TRUE;
CREATE INDEX idx_modulo_slug ON api.modulo(slug);
CREATE INDEX idx_publicacion_modulo ON api.publicacion(id_modulo, publicado) WHERE publicado = TRUE;
CREATE INDEX idx_sesion_token ON api.sesion_usuario(token_sesion) WHERE activa = TRUE;

-- =====================================================
-- DATOS INICIALES
-- =====================================================

INSERT INTO api.rol (id_rol, codigo, nombre, nivel_acceso) VALUES 
(1, 'ADMIN', 'Administrador', 1),
(2, 'EDITOR_GENERAL', 'Editor General', 2),
(3, 'EDITOR_OBSERVATORIO', 'Editor Observatorio', 3);

INSERT INTO api.tipo_modulo (id_tipo_modulo, codigo, nombre, orden_presentacion, color_tema) VALUES
(1, 'NNA', 'Niñas, Niños y Adolescentes', 1, '#4F46E5'),
(2, 'VIOLENCIA_MUJER', 'Violencia contra la mujer', 2, '#DC2626'),
(3, 'DISCAPACIDAD', 'Discapacidad', 3, '#059669'),
(4, 'ADULTO_MAYOR', 'Adulto Mayor', 4, '#7C2D12'),
(5, 'FAMILIA', 'Familia', 5, '#7C3AED'),
(6, 'ACOSO_POLITICO', 'Acoso Político', 6, '#BE185D');

INSERT INTO api.tipo_submodulo (id_tipo_submodulo, codigo, nombre, ruta_url, orden_presentacion, requiere_moderacion) VALUES
(1, 'ESTADISTICAS', 'Estadísticas', '/estadisticas', 1, FALSE),
(2, 'BUENAS_PRACTICAS', 'Buenas Prácticas', '/buenas-practicas', 2, TRUE),
(3, 'SERVICIOS', 'Servicios Institucionales', '/servicios', 3, FALSE),
(4, 'OPINIONES', 'Opiniones de Expertos', '/opiniones-expertos', 4, FALSE),
(5, 'PUBLICACIONES', 'Publicaciones', '/publicaciones', 5, FALSE),
(6, 'DERECHOS', 'Derechos', '/derechos', 6, FALSE);

INSERT INTO api.tipo_publicacion (id_tipo_publicacion, codigo, nombre, orden_presentacion) VALUES
(1, 'INV_INTERNA', 'Investigación Interna', 1),
(2, 'INV_EXTERNA', 'Investigación Externa', 2),
(3, 'LIBRO', 'Libro', 3),
(4, 'REVISTA', 'Revista', 4),
(5, 'NOTA_ESTADISTICA', 'Nota Estadística', 5);

-- Usuario administrador de ejemplo
INSERT INTO api.usuario (correo_institucional, nombres, apellidos, password_hash, id_rol, created_by) VALUES
('admin@mimp.gob.pe', 'Administrador', 'Sistema', '$2y$10$example_hash_here', 1, NULL);

-- Módulo de ejemplo
INSERT INTO api.modulo (id_tipo_modulo, slug, titulo, descripcion_breve, publicado, created_by) VALUES
(1, 'nna-observatorio', 'Observatorio NNA', 'Información estadística y análisis sobre niñas, niños y adolescentes', TRUE, 1);

-- Publicación de ejemplo
INSERT INTO api.publicacion (id_modulo, id_tipo_publicacion, titulo, autor, anio_publicacion, resumen, publicado, created_by) VALUES
(1, 1, 'Análisis de la Situación de NNA 2024', 'MIMP - Dirección de NNA', 2024, 'Estudio comprensivo sobre la situación actual de niñas, niños y adolescentes en el Perú', TRUE, 1);
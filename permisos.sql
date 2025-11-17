-- =============================================
-- SCRIPT DE CONFIGURACIÓN SISTEMAS DE COBRANZAS
-- =============================================

-- 1. LIMPIAR DATOS EXISTENTES (OPCIONAL)
/*
DELETE FROM co_user_permissions;
DELETE FROM co_role_permissions;
DELETE FROM co_user_roles;
DELETE FROM co_features;
DELETE FROM co_roles;
DELETE FROM co_permission_inheritance;
COMMIT;
*/

-- 2. CONFIGURACIÓN DE APLICACIONES (Implícita en las tablas)
-- Las aplicaciones se manejan por application_id en las tablas

-- 3. INSERTAR ROLES PARA AMBAS APLICACIONES
INSERT INTO co_roles (role_id, role_name, role_description, application_id, is_active, created_by) 
VALUES (1, 'ADMIN_COBRANZAS', 'Administrador del Sistema de Cobranzas', 100, 'Y', 'SYSTEM');

INSERT INTO co_roles (role_id, role_name, role_description, application_id, is_active, created_by) 
VALUES (2, 'SUPERVISOR', 'Supervisor de Cobranzas', 100, 'Y', 'SYSTEM');

INSERT INTO co_roles (role_id, role_name, role_description, application_id, is_active, created_by) 
VALUES (3, 'GESTOR_COBRANZA', 'Gestor de Cobranza', 100, 'Y', 'SYSTEM');

INSERT INTO co_roles (role_id, role_name, role_description, application_id, is_active, created_by) 
VALUES (4, 'ANALISTA', 'Analista de Cartera', 100, 'Y', 'SYSTEM');

INSERT INTO co_roles (role_id, role_name, role_description, application_id, is_active, created_by) 
VALUES (5, 'AUDITOR', 'Auditor Interno', 100, 'Y', 'SYSTEM');

INSERT INTO co_roles (role_id, role_name, role_description, application_id, is_active, created_by) 
VALUES (6, 'BACKOFFICE_ADMIN', 'Administrador Backoffice', 200, 'Y', 'SYSTEM');

INSERT INTO co_roles (role_id, role_name, role_description, application_id, is_active, created_by) 
VALUES (7, 'BACKOFFICE_OPER', 'Operador Backoffice', 200, 'Y', 'SYSTEM');

INSERT INTO co_roles (role_id, role_name, role_description, application_id, is_active, created_by) 
VALUES (8, 'BACKOFFICE_REPORT', 'Generador Reportes Backoffice', 200, 'Y', 'SYSTEM');

INSERT INTO co_roles (role_id, role_name, role_description, application_id, is_active, created_by) 
VALUES (9, 'CONSULTA', 'Usuario de Solo Consulta', 100, 'Y', 'SYSTEM');

INSERT INTO co_roles (role_id, role_name, role_description, application_id, is_active, created_by) 
VALUES (10, 'CLIENTE_EXTERNO', 'Cliente Externo (Portal)', 200, 'Y', 'SYSTEM');

-- 4. INSERTAR FEATURES PARA APP COBRANZAS (APP_ID = 100)
-- 4.1 Páginas Principales
INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (1, 'PAGE_100', 'Dashboard Cobranzas', 'PAGE', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (2, 'PAGE_110', 'Gestión de Cartera', 'PAGE', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (3, 'PAGE_120', 'Registro de Gestiones', 'PAGE', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (4, 'PAGE_130', 'Calendarización Pagos', 'PAGE', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (5, 'PAGE_140', 'Reportes de Gestión', 'PAGE', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (6, 'PAGE_150', 'Configuración Sistema', 'PAGE', 100, 'SYSTEM');

-- 4.2 Funcionalidades Específicas de Cobranzas
INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (7, 'GESTION_CREAR', 'Crear Gestión Cobranza', 'ACTION', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (8, 'GESTION_EDITAR', 'Editar Gestión Cobranza', 'ACTION', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (9, 'GESTION_ELIMINAR', 'Eliminar Gestión Cobranza', 'ACTION', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (10, 'PAGO_REGISTRAR', 'Registrar Pago', 'ACTION', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (11, 'PAGO_ANULAR', 'Anular Pago', 'ACTION', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (12, 'REPORTE_EXPORT', 'Exportar Reportes', 'ACTION', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (13, 'REPORTE_IMPRIMIR', 'Imprimir Reportes', 'ACTION', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (14, 'CLIENTE_EDITAR', 'Editar Datos Cliente', 'ACTION', 100, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (15, 'DEUDA_REESTRUCTURAR', 'Reestructurar Deuda', 'ACTION', 100, 'SYSTEM');

-- 5. INSERTAR FEATURES PARA BACKOFFICE COBRANZAS (APP_ID = 200)
INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (16, 'PAGE_200', 'Dashboard Backoffice', 'PAGE', 200, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (17, 'PAGE_210', 'Procesos Batch', 'PAGE', 200, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (18, 'PAGE_220', 'Conciliación Pagos', 'PAGE', 200, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (19, 'PAGE_230', 'Carga Masiva', 'PAGE', 200, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (20, 'PAGE_240', 'Auditoría Sistema', 'PAGE', 200, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (21, 'PAGE_250', 'Administración Usuarios', 'PAGE', 200, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (22, 'BATCH_EJECUTAR', 'Ejecutar Proceso Batch', 'ACTION', 200, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (23, 'CONCILIACION_APROBAR', 'Aprobar Conciliación', 'ACTION', 200, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (24, 'CARGA_MASIVA', 'Carga Masiva Datos', 'ACTION', 200, 'SYSTEM');

INSERT INTO co_features (feature_id, feature_code, feature_name, feature_type, application_id, created_by) 
VALUES (25, 'USUARIO_CREAR', 'Crear Usuario', 'ACTION', 200, 'SYSTEM');

-- 6. CONFIGURAR HERENCIA DE PERMISOS
INSERT INTO co_permission_inheritance (inheritance_id, application_id, inherit_type, is_active, created_by) 
VALUES (1, 100, 'ROLE_TO_USER', 'Y', 'SYSTEM');

INSERT INTO co_permission_inheritance (inheritance_id, application_id, inherit_type, is_active, created_by) 
VALUES (2, 200, 'ROLE_TO_USER', 'Y', 'SYSTEM');

-- 7. ASIGNAR PERMISOS POR ROL - APP COBRANZAS (APP_ID = 100)

-- 7.1 ADMIN_COBRANZAS - Todos los permisos
INSERT INTO co_role_permissions (role_id, feature_id, permission_level, is_granted, application_id, created_by)
SELECT 1, feature_id, 'FULL', 'Y', 100, 'SYSTEM'
FROM co_features WHERE application_id = 100;

-- 7.2 SUPERVISOR - Permisos amplios excepto configuración
INSERT INTO co_role_permissions (role_id, feature_id, permission_level, is_granted, application_id, created_by) VALUES
(2, 1, 'VIEW', 'Y', 100, 'SYSTEM'),
(2, 2, 'VIEW', 'Y', 100, 'SYSTEM'),
(2, 3, 'VIEW', 'Y', 100, 'SYSTEM'),
(2, 4, 'VIEW', 'Y', 100, 'SYSTEM'),
(2, 5, 'VIEW', 'Y', 100, 'SYSTEM'),
(2, 7, 'CREATE', 'Y', 100, 'SYSTEM'),
(2, 8, 'EDIT', 'Y', 100, 'SYSTEM'),
(2, 10, 'CREATE', 'Y', 100, 'SYSTEM'),
(2, 12, 'DOWNLOAD', 'Y', 100, 'SYSTEM'),
(2, 13, 'PRINT', 'Y', 100, 'SYSTEM'),
(2, 14, 'EDIT', 'Y', 100, 'SYSTEM'),
(2, 15, 'CREATE', 'Y', 100, 'SYSTEM');

-- 7.3 GESTOR_COBRANZA - Permisos operativos
INSERT INTO co_role_permissions (role_id, feature_id, permission_level, is_granted, application_id, created_by) VALUES
(3, 1, 'VIEW', 'Y', 100, 'SYSTEM'),
(3, 2, 'VIEW', 'Y', 100, 'SYSTEM'),
(3, 3, 'VIEW', 'Y', 100, 'SYSTEM'),
(3, 4, 'VIEW', 'Y', 100, 'SYSTEM'),
(3, 7, 'CREATE', 'Y', 100, 'SYSTEM'),
(3, 8, 'EDIT', 'Y', 100, 'SYSTEM'),
(3, 10, 'CREATE', 'Y', 100, 'SYSTEM');

-- 7.4 ANALISTA - Permisos de análisis
INSERT INTO co_role_permissions (role_id, feature_id, permission_level, is_granted, application_id, created_by) VALUES
(4, 1, 'VIEW', 'Y', 100, 'SYSTEM'),
(4, 2, 'VIEW', 'Y', 100, 'SYSTEM'),
(4, 5, 'VIEW', 'Y', 100, 'SYSTEM'),
(4, 12, 'DOWNLOAD', 'Y', 100, 'SYSTEM'),
(4, 13, 'PRINT', 'Y', 100, 'SYSTEM');

-- 7.5 AUDITOR - Solo consulta
INSERT INTO co_role_permissions (role_id, feature_id, permission_level, is_granted, application_id, created_by) VALUES
(5, 1, 'VIEW', 'Y', 100, 'SYSTEM'),
(5, 2, 'VIEW', 'Y', 100, 'SYSTEM'),
(5, 5, 'VIEW', 'Y', 100, 'SYSTEM'),
(5, 12, 'DOWNLOAD', 'Y', 100, 'SYSTEM');

-- 7.6 CONSULTA - Mínimos permisos
INSERT INTO co_role_permissions (role_id, feature_id, permission_level, is_granted, application_id, created_by) VALUES
(9, 1, 'VIEW', 'Y', 100, 'SYSTEM'),
(9, 2, 'VIEW', 'Y', 100, 'SYSTEM');

-- 8. ASIGNAR PERMISOS POR ROL - BACKOFFICE COBRANZAS (APP_ID = 200)

-- 8.1 BACKOFFICE_ADMIN - Todos los permisos backoffice
INSERT INTO co_role_permissions (role_id, feature_id, permission_level, is_granted, application_id, created_by)
SELECT 6, feature_id, 'FULL', 'Y', 200, 'SYSTEM'
FROM co_features WHERE application_id = 200;

-- 8.2 BACKOFFICE_OPER - Permisos operativos
INSERT INTO co_role_permissions (role_id, feature_id, permission_level, is_granted, application_id, created_by) VALUES
(7, 16, 'VIEW', 'Y', 200, 'SYSTEM'),
(7, 17, 'VIEW', 'Y', 200, 'SYSTEM'),
(7, 18, 'VIEW', 'Y', 200, 'SYSTEM'),
(7, 19, 'VIEW', 'Y', 200, 'SYSTEM'),
(7, 22, 'CREATE', 'Y', 200, 'SYSTEM'),
(7, 24, 'CREATE', 'Y', 200, 'SYSTEM');

-- 8.3 BACKOFFICE_REPORT - Solo reportes
INSERT INTO co_role_permissions (role_id, feature_id, permission_level, is_granted, application_id, created_by) VALUES
(8, 16, 'VIEW', 'Y', 200, 'SYSTEM'),
(8, 17, 'VIEW', 'Y', 200, 'SYSTEM');

-- 8.4 CLIENTE_EXTERNO - Mínimos permisos portal
INSERT INTO co_role_permissions (role_id, feature_id, permission_level, is_granted, application_id, created_by) VALUES
(10, 16, 'VIEW', 'Y', 200, 'SYSTEM');

-- 9. CREAR USUARIOS Y ASIGNAR ROLES BASE

-- 9.1 Usuarios App Cobranzas
INSERT INTO co_user_roles (username, role_id, application_id, created_by) VALUES
('admin.cobranzas', 1, 100, 'SYSTEM'),
('supervisor.principal', 2, 100, 'SYSTEM'),
('maria.gestor', 3, 100, 'SYSTEM'),
('carlos.gestor', 3, 100, 'SYSTEM'),
('analista.cartera', 4, 100, 'SYSTEM'),
('auditor.interno', 5, 100, 'SYSTEM'),
('consulta.general', 9, 100, 'SYSTEM');

-- 9.2 Usuarios Backoffice Cobranzas
INSERT INTO co_user_roles (username, role_id, application_id, created_by) VALUES
('backoffice.admin', 6, 200, 'SYSTEM'),
('operador.backoffice', 7, 200, 'SYSTEM'),
('reportes.backoffice', 8, 200, 'SYSTEM'),
('cliente.premium', 10, 200, 'SYSTEM');

-- 10. PERMISOS ESPECÍFICOS POR USUARIO (EXCEPCIONES)

-- 10.1 Maria Gestor - Permiso adicional para exportar reportes
INSERT INTO co_user_permissions (username, feature_id, permission_level, is_granted, application_id, created_by)
VALUES ('maria.gestor', 12, 'DOWNLOAD', 'Y', 100, 'SYSTEM');

-- 10.2 Carlos Gestor - Restricción: no puede anular pagos
INSERT INTO co_user_permissions (username, feature_id, permission_level, is_granted, application_id, created_by)
VALUES ('carlos.gestor', 11, 'DELETE', 'N', 100, 'SYSTEM');

-- 10.3 Analista Cartera - Permiso especial para reestructurar deudas
INSERT INTO co_user_permissions (username, feature_id, permission_level, is_granted, application_id, created_by)
VALUES ('analista.cartera', 15, 'CREATE', 'Y', 100, 'SYSTEM');

-- 10.4 Operador Backoffice - Permiso para crear usuarios (temporal)
INSERT INTO co_user_permissions (username, feature_id, permission_level, is_granted, application_id, created_by)
VALUES ('operador.backoffice', 25, 'CREATE', 'Y', 200, 'SYSTEM');

-- 10.5 Cliente Premium - Permiso extendido en portal
INSERT INTO co_user_permissions (username, feature_id, permission_level, is_granted, application_id, created_by)
VALUES ('cliente.premium', 18, 'VIEW', 'Y', 200, 'SYSTEM');

-- 11. PERMISOS DENEGADOS ESPECÍFICOS

-- 11.1 Consulta General - Denegar acceso a página de configuración
INSERT INTO co_user_permissions (username, feature_id, permission_level, is_granted, application_id, created_by)
VALUES ('consulta.general', 6, 'VIEW', 'N', 100, 'SYSTEM');

-- 11.2 Reportes Backoffice - Denegar ejecución de procesos batch
INSERT INTO co_user_permissions (username, feature_id, permission_level, is_granted, application_id, created_by)
VALUES ('reportes.backoffice', 22, 'CREATE', 'N', 200, 'SYSTEM');

COMMIT;

-- =============================================
-- VERIFICACIÓN Y REPORTE DE CONFIGURACIÓN
-- =============================================

-- 12. REPORTE DE PERMISOS CONFIGURADOS
SET PAGESIZE 100
SET LINESIZE 200

COLUMN "Aplicación" FORMAT A20
COLUMN "Rol" FORMAT A20
COLUMN "Feature" FORMAT A30
COLUMN "Permisos" FORMAT A30

PROMPT === PERMISOS POR ROL ===
SELECT 
    CASE r.application_id 
        WHEN 100 THEN 'COBRANZAS' 
        WHEN 200 THEN 'BACKOFFICE' 
    END as "Aplicación",
    r.role_name as "Rol",
    f.feature_name as "Feature",
    LISTAGG(rp.permission_level, ', ') WITHIN GROUP (ORDER BY rp.permission_level) as "Permisos",
    COUNT(*) as "Total_Permisos"
FROM co_role_permissions rp
JOIN co_roles r ON rp.role_id = r.role_id
JOIN co_features f ON rp.feature_id = f.feature_id
WHERE rp.is_granted = 'Y'
GROUP BY r.application_id, r.role_name, f.feature_name
ORDER BY r.application_id, r.role_name, f.feature_name;

PROMPT === USUARIOS Y SUS ROLES ===
SELECT 
    CASE ur.application_id 
        WHEN 100 THEN 'COBRANZAS' 
        WHEN 200 THEN 'BACKOFFICE' 
    END as "Aplicación",
    ur.username as "Usuario",
    r.role_name as "Rol"
FROM co_user_roles ur
JOIN co_roles r ON ur.role_id = r.role_id
WHERE ur.is_active = 'Y'
ORDER BY ur.application_id, ur.username;

PROMPT === PERMISOS ESPECÍFICOS POR USUARIO ===
SELECT 
    up.username as "Usuario",
    f.feature_name as "Feature",
    up.permission_level as "Permiso",
    up.is_granted as "Concedido"
FROM co_user_permissions up
JOIN co_features f ON up.feature_id = f.feature_id
ORDER BY up.username, f.feature_name;

PROMPT === RESUMEN GENERAL ===
SELECT 
    CASE application_id 
        WHEN 100 THEN 'COBRANZAS' 
        WHEN 200 THEN 'BACKOFFICE' 
    END as "Aplicación",
    COUNT(DISTINCT role_id) as "Roles_Configurados",
    COUNT(DISTINCT feature_id) as "Features_Configurados",
    COUNT(*) as "Total_Permisos_Rol",
    (SELECT COUNT(*) FROM co_user_roles WHERE application_id = rp.application_id) as "Usuarios_Asignados"
FROM co_role_permissions rp
GROUP BY application_id;

-- =============================================
-- FUNCIONES DE VERIFICACIÓN
-- =============================================

PROMPT === VERIFICACIÓN DE PERMISOS PARA USUARIOS CLAVE ===

-- Verificar permisos de maria.gestor
SELECT 
    pkg_apex_auth_v2.has_permission('maria.gestor', 100, 'PAGE_110', 'VIEW') as "Puede_Ver_Cartera",
    pkg_apex_auth_v2.has_permission('maria.gestor', 100, 'REPORTE_EXPORT', 'DOWNLOAD') as "Puede_Exportar",
    pkg_apex_auth_v2.has_permission('maria.gestor', 100, 'PAGE_150', 'VIEW') as "Puede_Ver_Config"
FROM DUAL;

-- Verificar permisos de carlos.gestor (con restricción)
SELECT 
    pkg_apex_auth_v2.has_permission('carlos.gestor', 100, 'PAGO_ANULAR', 'DELETE') as "Puede_Anular_Pagos"
FROM DUAL;

-- Verificar permisos de backoffice.admin
SELECT 
    pkg_apex_auth_v2.has_permission('backoffice.admin', 200, 'USUARIO_CREAR', 'CREATE') as "Puede_Crear_Usuarios",
    pkg_apex_auth_v2.has_permission('backoffice.admin', 200, 'PAGE_240', 'VIEW') as "Puede_Ver_Auditoria"
FROM DUAL;

PROMPT === CONFIGURACIÓN COMPLETADA EXITOSAMENTE ===
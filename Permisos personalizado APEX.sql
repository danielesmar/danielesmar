en Oracle Apex como puedo crear una autorización personalizada por página para roles admin, colaborador, auditor, usuario básico. la idea es administrar por cada página o feature diferentes permisos por ejemplo, ver, editar, eliminar, crear, imprimir, descargar, etc. por rol, un rol por defecto tiene los permisos predefinidos y son heredados a los usuarios al crear o al cambiarle el rol a parte de puede personalizar estos permisos es decir por feature agregar los permisos a según conveniencia. a parte las features y roles deben estar asociadas a una aplicación es decir existen diferentes roles, feature y permisos para la app y diferentes roles para el sitio administrativo. crea paso a paso como implementarlo en Oracle Apex y plsql. dame las mejores prácticas y estrategias para lograrlo




Deepseek

Sistema de Autorización Personalizada en Oracle APEX
Te guiaré paso a paso para implementar un sistema robusto de autorización por página y feature con roles personalizados.

1. Estructura de Tablas
1.1 Tabla de Roles
sql
CREATE TABLE apex_roles (
    role_id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name        VARCHAR2(100) NOT NULL UNIQUE,
    role_description VARCHAR2(500),
    application_id   NUMBER NOT NULL,
    is_active        VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y','N')),
    created_by       VARCHAR2(100),
    created_date     DATE DEFAULT SYSDATE,
    updated_by       VARCHAR2(100),
    updated_date     DATE
);
1.2 Tabla de Features/Permisos
sql
CREATE TABLE apex_features (
    feature_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    feature_code     VARCHAR2(100) NOT NULL UNIQUE,
    feature_name     VARCHAR2(200) NOT NULL,
    feature_type     VARCHAR2(50) CHECK (feature_type IN ('PAGE','COMPONENT','ACTION')),
    parent_feature_id NUMBER REFERENCES apex_features(feature_id),
    application_id   NUMBER NOT NULL,
    created_by       VARCHAR2(100),
    created_date     DATE DEFAULT SYSDATE
);
1.3 Tabla de Permisos por Rol
sql
CREATE TABLE apex_role_permissions (
    permission_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_id          NUMBER NOT NULL REFERENCES apex_roles(role_id),
    feature_id       NUMBER NOT NULL REFERENCES apex_features(feature_id),
    permission_level VARCHAR2(50) CHECK (permission_level IN ('VIEW','EDIT','CREATE','DELETE','PRINT','DOWNLOAD','FULL')),
    is_granted       VARCHAR2(1) DEFAULT 'Y' CHECK (is_granted IN ('Y','N')),
    application_id   NUMBER NOT NULL,
    created_by       VARCHAR2(100),
    created_date     DATE DEFAULT SYSDATE,
    updated_by       VARCHAR2(100),
    updated_date     DATE,
    UNIQUE (role_id, feature_id, permission_level)
);
1.4 Tabla de Usuarios y Roles
sql
CREATE TABLE apex_user_roles (
    user_role_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username         VARCHAR2(100) NOT NULL,
    role_id          NUMBER NOT NULL REFERENCES apex_roles(role_id),
    application_id   NUMBER NOT NULL,
    is_active        VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y','N')),
    start_date       DATE DEFAULT SYSDATE,
    end_date         DATE,
    created_by       VARCHAR2(100),
    created_date     DATE DEFAULT SYSDATE
);
2. Paquete de Autorización
sql
CREATE OR REPLACE PACKAGE pkg_apex_auth AS
    
    -- Constantes para tipos de permisos
    C_PERM_VIEW     CONSTANT VARCHAR2(10) := 'VIEW';
    C_PERM_EDIT     CONSTANT VARCHAR2(10) := 'EDIT';
    C_PERM_CREATE   CONSTANT VARCHAR2(10) := 'CREATE';
    C_PERM_DELETE   CONSTANT VARCHAR2(10) := 'DELETE';
    C_PERM_PRINT    CONSTANT VARCHAR2(10) := 'PRINT';
    C_PERM_DOWNLOAD CONSTANT VARCHAR2(10) := 'DOWNLOAD';
    C_PERM_FULL     CONSTANT VARCHAR2(10) := 'FULL';
    
    -- Función para verificar permiso
    FUNCTION has_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2 DEFAULT C_PERM_VIEW
    ) RETURN VARCHAR2;
    
    -- Función para obtener roles del usuario
    FUNCTION get_user_roles(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER
    ) RETURN SYS_REFCURSOR;
    
    -- Procedimiento para asignar rol a usuario
    PROCEDURE assign_user_role(
        p_username      IN VARCHAR2,
        p_role_name     IN VARCHAR2,
        p_application_id IN NUMBER,
        p_created_by    IN VARCHAR2
    );
    
    -- Procedimiento para crear permisos por defecto
    PROCEDURE create_default_permissions(
        p_role_id       IN NUMBER,
        p_application_id IN NUMBER,
        p_created_by    IN VARCHAR2
    );
    
    -- Función para verificar permiso en página actual
    FUNCTION has_page_permission(
        p_page_id       IN NUMBER DEFAULT NULL,
        p_permission    IN VARCHAR2 DEFAULT C_PERM_VIEW
    ) RETURN BOOLEAN;
    
END pkg_apex_auth;
/

CREATE OR REPLACE PACKAGE BODY pkg_apex_auth AS

    FUNCTION has_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2 DEFAULT C_PERM_VIEW
    ) RETURN VARCHAR2
    IS
        l_count NUMBER := 0;
    BEGIN
        SELECT COUNT(*)
        INTO l_count
        FROM apex_role_permissions rp
        JOIN apex_features f ON rp.feature_id = f.feature_id
        JOIN apex_user_roles ur ON rp.role_id = ur.role_id
        JOIN apex_roles r ON ur.role_id = r.role_id
        WHERE ur.username = p_username
          AND ur.application_id = p_application_id
          AND ur.is_active = 'Y'
          AND r.is_active = 'Y'
          AND rp.is_granted = 'Y'
          AND f.feature_code = p_feature_code
          AND f.application_id = p_application_id
          AND (rp.permission_level = p_permission 
               OR rp.permission_level = C_PERM_FULL
               OR (p_permission = C_PERM_VIEW AND rp.permission_level IN (C_PERM_EDIT, C_PERM_CREATE, C_PERM_DELETE)));
        
        RETURN CASE WHEN l_count > 0 THEN 'Y' ELSE 'N' END;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'N';
    END has_permission;

    FUNCTION get_user_roles(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER
    ) RETURN SYS_REFCURSOR
    IS
        l_roles SYS_REFCURSOR;
    BEGIN
        OPEN l_roles FOR
        SELECT r.role_name, r.role_description
        FROM apex_user_roles ur
        JOIN apex_roles r ON ur.role_id = r.role_id
        WHERE ur.username = p_username
          AND ur.application_id = p_application_id
          AND ur.is_active = 'Y'
          AND r.is_active = 'Y';
        
        RETURN l_roles;
    END get_user_roles;

    PROCEDURE assign_user_role(
        p_username      IN VARCHAR2,
        p_role_name     IN VARCHAR2,
        p_application_id IN NUMBER,
        p_created_by    IN VARCHAR2
    )
    IS
        l_role_id NUMBER;
    BEGIN
        SELECT role_id INTO l_role_id
        FROM apex_roles
        WHERE role_name = p_role_name
          AND application_id = p_application_id
          AND is_active = 'Y';
        
        -- Desactivar roles anteriores
        UPDATE apex_user_roles 
        SET is_active = 'N', 
            end_date = SYSDATE,
            updated_by = p_created_by,
            updated_date = SYSDATE
        WHERE username = p_username
          AND application_id = p_application_id
          AND is_active = 'Y';
        
        -- Asignar nuevo rol
        INSERT INTO apex_user_roles (
            username, role_id, application_id, created_by
        ) VALUES (
            p_username, l_role_id, p_application_id, p_created_by
        );
        
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Rol no encontrado: ' || p_role_name);
    END assign_user_role;

    PROCEDURE create_default_permissions(
        p_role_id       IN NUMBER,
        p_application_id IN NUMBER,
        p_created_by    IN VARCHAR2
    )
    IS
        -- Permisos por defecto según el rol
        CURSOR c_default_features IS
        SELECT feature_id, permission_level
        FROM apex_features f,
             TABLE(
                 CASE 
                     WHEN (SELECT role_name FROM apex_roles WHERE role_id = p_role_id) = 'ADMIN' THEN
                         SYS.ODCIVARCHAR2LIST(C_PERM_FULL)
                     WHEN (SELECT role_name FROM apex_roles WHERE role_id = p_role_id) = 'COLABORADOR' THEN
                         SYS.ODCIVARCHAR2LIST(C_PERM_VIEW, C_PERM_EDIT, C_PERM_CREATE)
                     WHEN (SELECT role_name FROM apex_roles WHERE role_id = p_role_id) = 'AUDITOR' THEN
                         SYS.ODCIVARCHAR2LIST(C_PERM_VIEW, C_PERM_DOWNLOAD)
                     ELSE
                         SYS.ODCIVARCHAR2LIST(C_PERM_VIEW)
                 END
             ) perms
        WHERE f.application_id = p_application_id;
        
    BEGIN
        FOR rec IN c_default_features LOOP
            INSERT INTO apex_role_permissions (
                role_id, feature_id, permission_level, application_id, created_by
            ) VALUES (
                p_role_id, rec.feature_id, rec.permission_level, p_application_id, p_created_by
            );
        END LOOP;
        
        COMMIT;
    END create_default_permissions;

    FUNCTION has_page_permission(
        p_page_id       IN NUMBER DEFAULT NULL,
        p_permission    IN VARCHAR2 DEFAULT C_PERM_VIEW
    ) RETURN BOOLEAN
    IS
        l_page_id NUMBER := NVL(p_page_id, NV(:APP_PAGE_ID, 0));
        l_feature_code VARCHAR2(100);
        l_result VARCHAR2(1);
    BEGIN
        -- Construir código de feature basado en página
        l_feature_code := 'PAGE_' || l_page_id;
        
        l_result := has_permission(
            p_username => :APP_USER,
            p_application_id => :APP_ID,
            p_feature_code => l_feature_code,
            p_permission => p_permission
        );
        
        RETURN l_result = 'Y';
    END has_page_permission;

END pkg_apex_auth;
/
3. Configuración en APEX
3.1 Crear Autorización por Página
En las propiedades de cada página, crear una autorización:

Esquema de Autorización:

Tipo: Función que devuelve Booleano

Nombre: pkg_apex_auth.has_page_permission

3.2 Condiciones para Componentes
Para botones, regiones, etc., usar condiciones tipo "Función PL/SQL que devuelve Booleano":

sql
-- Para botón Editar
RETURN pkg_apex_auth.has_page_permission(:APP_PAGE_ID, 'EDIT');

-- Para botón Eliminar
RETURN pkg_apex_auth.has_page_permission(:APP_PAGE_ID, 'DELETE');

-- Para región específica
RETURN pkg_apex_auth.has_permission(
    :APP_USER, 
    :APP_ID, 
    'FEATURE_SPECIAL_REPORT', 
    'VIEW'
);
3.3 Proceso de Inicialización de Página
Crear un proceso de página (punto de proceso: "Antes del encabezado"):

sql
DECLARE
    l_has_access BOOLEAN;
BEGIN
    l_has_access := pkg_apex_auth.has_page_permission(:APP_PAGE_ID, 'VIEW');
    
    IF NOT l_has_access THEN
        -- Redirigir a página de acceso denegado
        apex_application.g_unrecoverable_error := true;
        RAISE_APPLICATION_ERROR(-20001, 'Acceso denegado');
    END IF;
END;
4. Páginas Administrativas
4.1 Página de Administración de Roles
Crear página con:

Formulario interactivo para apex_roles

Reporte de permisos por rol

Funcionalidad para copiar permisos entre roles

4.2 Página de Asignación de Usuarios
Formulario para apex_user_roles

Búsqueda de usuarios

Asignación múltiple de roles

4.3 Página de Configuración de Features
Árbol de features con parent-child

Asignación masiva de permisos

5. Mejores Prácticas
5.1 Caché de Permisos
sql
-- Crear tabla de caché
CREATE TABLE apex_auth_cache (
    username        VARCHAR2(100),
    application_id  NUMBER,
    feature_code    VARCHAR2(100),
    permission      VARCHAR2(50),
    has_access      VARCHAR2(1),
    cached_date     DATE DEFAULT SYSDATE,
    PRIMARY KEY (username, application_id, feature_code, permission)
);

-- Función con caché
FUNCTION has_permission_cached(
    p_username      IN VARCHAR2,
    p_application_id IN NUMBER,
    p_feature_code  IN VARCHAR2,
    p_permission    IN VARCHAR2
) RETURN VARCHAR2
IS
    l_result VARCHAR2(1);
BEGIN
    BEGIN
        SELECT has_access INTO l_result
        FROM apex_auth_cache
        WHERE username = p_username
          AND application_id = p_application_id
          AND feature_code = p_feature_code
          AND permission = p_permission
          AND cached_date > SYSDATE - (1/24); -- Cache por 1 hora
        
        RETURN l_result;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_result := has_permission(p_username, p_application_id, p_feature_code, p_permission);
            
            -- Guardar en caché
            INSERT INTO apex_auth_cache VALUES (
                p_username, p_application_id, p_feature_code, p_permission, l_result, SYSDATE
            );
            COMMIT;
            
            RETURN l_result;
    END;
END;
5.2 Logs de Auditoría
sql
CREATE TABLE apex_auth_audit (
    audit_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username        VARCHAR2(100),
    application_id  NUMBER,
    page_id         NUMBER,
    feature_code    VARCHAR2(100),
    action_type     VARCHAR2(50),
    access_granted  VARCHAR2(1),
    audit_date      DATE DEFAULT SYSDATE,
    ip_address      VARCHAR2(100),
    session_id      NUMBER
);
5.3 Script de Inicialización
sql
-- Insertar roles base
INSERT INTO apex_roles (role_name, role_description, application_id, created_by) 
VALUES ('ADMIN', 'Administrador del sistema', 100, 'SYSTEM');

INSERT INTO apex_roles (role_name, role_description, application_id, created_by) 
VALUES ('COLABORADOR', 'Usuario colaborador', 100, 'SYSTEM');

INSERT INTO apex_roles (role_name, role_description, application_id, created_by) 
VALUES ('AUDITOR', 'Usuario auditor', 100, 'SYSTEM');

INSERT INTO apex_roles (role_name, role_description, application_id, created_by) 
VALUES ('USUARIO_BASICO', 'Usuario básico', 100, 'SYSTEM');

-- Insertar features comunes
INSERT INTO apex_features (feature_code, feature_name, feature_type, application_id, created_by) 
VALUES ('PAGE_1', 'Dashboard Principal', 'PAGE', 100, 'SYSTEM');

INSERT INTO apex_features (feature_code, feature_name, feature_type, application_id, created_by) 
VALUES ('REPORT_EXPORT', 'Exportar Reportes', 'ACTION', 100, 'SYSTEM');
6. Consideraciones de Seguridad
Validación de Entradas: Siempre usar bind variables

Principio de Mínimo Privilegio: Asignar solo permisos necesarios

Auditoría Regular: Revisar logs de acceso

Backup de Configuración: Exportar regularmente la configuración de permisos

Testing de Seguridad: Probar todos los escenarios de acceso

Este sistema proporciona una base sólida y escalable para la gestión de autorizaciones en Oracle APEX, permitiendo una administración granular de permisos por página y feature.

This response is AI-generated, for reference only.
estos se basan en el rol del usuario o en el usuario? no veo la tabla donde se almacenen los permisos por usuario, es decir que desde una pantalla administrativa a un usuario básico le pueda dar permiso para ver información que con ese rol no podría por los permisos por defecto del rol
Tienes razón, me faltó incluir la personalización a nivel de usuario. Voy a completar el sistema con permisos específicos por usuario que sobrescriban los permisos del rol.

1. Tablas Adicionales
1.1 Tabla de Permisos Específicos por Usuario
sql
CREATE TABLE apex_user_permissions (
    user_permission_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username         VARCHAR2(100) NOT NULL,
    feature_id       NUMBER NOT NULL REFERENCES apex_features(feature_id),
    permission_level VARCHAR2(50) CHECK (permission_level IN ('VIEW','EDIT','CREATE','DELETE','PRINT','DOWNLOAD','FULL','DENY')),
    is_granted       VARCHAR2(1) DEFAULT 'Y' CHECK (is_granted IN ('Y','N')),
    application_id   NUMBER NOT NULL,
    created_by       VARCHAR2(100),
    created_date     DATE DEFAULT SYSDATE,
    updated_by       VARCHAR2(100),
    updated_date     DATE,
    UNIQUE (username, feature_id, permission_level)
);
1.2 Tabla de Herencia de Permisos
sql
CREATE TABLE apex_permission_inheritance (
    inheritance_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    application_id   NUMBER NOT NULL,
    inherit_type     VARCHAR2(20) CHECK (inherit_type IN ('ROLE_TO_USER', 'PARENT_TO_CHILD')),
    is_active        VARCHAR2(1) DEFAULT 'Y',
    created_by       VARCHAR2(100),
    created_date     DATE DEFAULT SYSDATE
);
2. Paquete de Autorización Mejorado
sql
CREATE OR REPLACE PACKAGE pkg_apex_auth_v2 AS
    
    -- Constantes
    C_PERM_VIEW     CONSTANT VARCHAR2(10) := 'VIEW';
    C_PERM_EDIT     CONSTANT VARCHAR2(10) := 'EDIT';
    C_PERM_CREATE   CONSTANT VARCHAR2(10) := 'CREATE';
    C_PERM_DELETE   CONSTANT VARCHAR2(10) := 'DELETE';
    C_PERM_PRINT    CONSTANT VARCHAR2(10) := 'PRINT';
    C_PERM_DOWNLOAD CONSTANT VARCHAR2(10) := 'DOWNLOAD';
    C_PERM_FULL     CONSTANT VARCHAR2(10) := 'FULL';
    C_PERM_DENY     CONSTANT VARCHAR2(10) := 'DENY';
    
    -- Función principal mejorada que considera usuario + rol
    FUNCTION has_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2 DEFAULT C_PERM_VIEW
    ) RETURN VARCHAR2;
    
    -- Función para obtener permisos específicos del usuario
    FUNCTION get_user_specific_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_id    IN NUMBER,
        p_permission    IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- Función para obtener permisos del rol
    FUNCTION get_role_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_id    IN NUMBER,
        p_permission    IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- Procedimiento para asignar permiso específico a usuario
    PROCEDURE grant_user_permission(
        p_username      IN VARCHAR2,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2,
        p_application_id IN NUMBER,
        p_is_granted    IN VARCHAR2 DEFAULT 'Y',
        p_granted_by    IN VARCHAR2
    );
    
    -- Procedimiento para revocar permiso específico
    PROCEDURE revoke_user_permission(
        p_username      IN VARCHAR2,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2,
        p_application_id IN NUMBER,
        p_revoked_by    IN VARCHAR2
    );
    
    -- Función para listar permisos de usuario (rol + específicos)
    FUNCTION get_user_permissions(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER
    ) RETURN SYS_REFCURSOR;
    
    -- Función para verificar herencia activa
    FUNCTION is_inheritance_active(
        p_application_id IN NUMBER,
        p_inherit_type   IN VARCHAR2
    ) RETURN BOOLEAN;

END pkg_apex_auth_v2;
/

CREATE OR REPLACE PACKAGE BODY pkg_apex_auth_v2 AS

    FUNCTION get_user_specific_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_id    IN NUMBER,
        p_permission    IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_result VARCHAR2(1) := NULL; -- NULL significa no hay permiso específico
    BEGIN
        -- Buscar permiso específico del usuario
        SELECT up.is_granted
        INTO l_result
        FROM apex_user_permissions up
        WHERE up.username = p_username
          AND up.feature_id = p_feature_id
          AND up.application_id = p_application_id
          AND up.is_granted IN ('Y','N')
          AND (up.permission_level = p_permission 
               OR up.permission_level = C_PERM_FULL
               OR up.permission_level = C_PERM_DENY);
        
        RETURN l_result;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL; -- No hay permiso específico, usar herencia del rol
        WHEN TOO_MANY_ROWS THEN
            -- Si hay múltiples permisos, priorizar en este orden: DENY, FULL, específico
            BEGIN
                SELECT MAX(is_granted) KEEP (
                    DENSE_RANK FIRST ORDER BY 
                    CASE permission_level 
                        WHEN C_PERM_DENY THEN 1
                        WHEN C_PERM_FULL THEN 2
                        ELSE 3 
                    END
                )
                INTO l_result
                FROM apex_user_permissions
                WHERE username = p_username
                  AND feature_id = p_feature_id
                  AND application_id = p_application_id;
                
                RETURN l_result;
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN NULL;
            END;
    END get_user_specific_permission;

    FUNCTION get_role_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_id    IN NUMBER,
        p_permission    IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_result VARCHAR2(1) := 'N';
    BEGIN
        SELECT MAX('Y')
        INTO l_result
        FROM apex_role_permissions rp
        JOIN apex_user_roles ur ON rp.role_id = ur.role_id
        WHERE ur.username = p_username
          AND ur.application_id = p_application_id
          AND ur.is_active = 'Y'
          AND rp.feature_id = p_feature_id
          AND rp.is_granted = 'Y'
          AND (rp.permission_level = p_permission 
               OR rp.permission_level = C_PERM_FULL
               OR (p_permission = C_PERM_VIEW AND rp.permission_level IN (C_PERM_EDIT, C_PERM_CREATE, C_PERM_DELETE)));
        
        RETURN NVL(l_result, 'N');
        
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'N';
    END get_role_permission;

    FUNCTION has_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2 DEFAULT C_PERM_VIEW
    ) RETURN VARCHAR2
    IS
        l_feature_id    NUMBER;
        l_user_perm     VARCHAR2(1);
        l_role_perm     VARCHAR2(1);
        l_inheritance   BOOLEAN;
    BEGIN
        -- Obtener ID del feature
        BEGIN
            SELECT feature_id INTO l_feature_id
            FROM apex_features
            WHERE feature_code = p_feature_code
              AND application_id = p_application_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 'N'; -- Feature no existe
        END;
        
        -- 1. Verificar permiso específico del usuario (tiene prioridad)
        l_user_perm := get_user_specific_permission(
            p_username, p_application_id, l_feature_id, p_permission
        );
        
        -- Si hay permiso específico del usuario, usarlo
        IF l_user_perm IS NOT NULL THEN
            RETURN l_user_perm;
        END IF;
        
        -- 2. Verificar si la herencia está activa
        l_inheritance := is_inheritance_active(p_application_id, 'ROLE_TO_USER');
        
        IF l_inheritance THEN
            -- 3. Obtener permiso del rol
            l_role_perm := get_role_permission(
                p_username, p_application_id, l_feature_id, p_permission
            );
            
            RETURN l_role_perm;
        ELSE
            RETURN 'N'; -- Sin herencia y sin permiso específico
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'N';
    END has_permission;

    PROCEDURE grant_user_permission(
        p_username      IN VARCHAR2,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2,
        p_application_id IN NUMBER,
        p_is_granted    IN VARCHAR2 DEFAULT 'Y',
        p_granted_by    IN VARCHAR2
    )
    IS
        l_feature_id NUMBER;
    BEGIN
        -- Obtener feature_id
        SELECT feature_id INTO l_feature_id
        FROM apex_features
        WHERE feature_code = p_feature_code
          AND application_id = p_application_id;
        
        -- Insertar o actualizar permiso
        MERGE INTO apex_user_permissions up
        USING (SELECT p_username as username, l_feature_id as feature_id FROM dual) src
        ON (up.username = src.username AND up.feature_id = src.feature_id AND up.permission_level = p_permission)
        WHEN MATCHED THEN
            UPDATE SET 
                up.is_granted = p_is_granted,
                up.updated_by = p_granted_by,
                up.updated_date = SYSDATE
        WHEN NOT MATCHED THEN
            INSERT (username, feature_id, permission_level, is_granted, application_id, created_by)
            VALUES (p_username, l_feature_id, p_permission, p_is_granted, p_application_id, p_granted_by);
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error al asignar permiso: ' || SQLERRM);
    END grant_user_permission;

    PROCEDURE revoke_user_permission(
        p_username      IN VARCHAR2,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2,
        p_application_id IN NUMBER,
        p_revoked_by    IN VARCHAR2
    )
    IS
        l_feature_id NUMBER;
    BEGIN
        -- Obtener feature_id
        SELECT feature_id INTO l_feature_id
        FROM apex_features
        WHERE feature_code = p_feature_code
          AND application_id = p_application_id;
        
        -- Eliminar permiso específico
        DELETE FROM apex_user_permissions
        WHERE username = p_username
          AND feature_id = l_feature_id
          AND permission_level = p_permission
          AND application_id = p_application_id;
        
        COMMIT;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- El permiso no existía, no hay problema
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20003, 'Error al revocar permiso: ' || SQLERRM);
    END revoke_user_permission;

    FUNCTION get_user_permissions(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER
    ) RETURN SYS_REFCURSOR
    IS
        l_cursor SYS_REFCURSOR;
    BEGIN
        OPEN l_cursor FOR
        WITH user_roles AS (
            SELECT r.role_id, r.role_name
            FROM apex_user_roles ur
            JOIN apex_roles r ON ur.role_id = r.role_id
            WHERE ur.username = p_username
              AND ur.application_id = p_application_id
              AND ur.is_active = 'Y'
              AND r.is_active = 'Y'
        ),
        role_permissions AS (
            SELECT 
                f.feature_code,
                f.feature_name,
                rp.permission_level,
                'ROLE' as permission_type,
                ur.role_name,
                rp.is_granted
            FROM apex_role_permissions rp
            JOIN apex_features f ON rp.feature_id = f.feature_id
            JOIN user_roles ur ON rp.role_id = ur.role_id
            WHERE rp.application_id = p_application_id
        ),
        user_permissions AS (
            SELECT 
                f.feature_code,
                f.feature_name,
                up.permission_level,
                'USER' as permission_type,
                NULL as role_name,
                up.is_granted
            FROM apex_user_permissions up
            JOIN apex_features f ON up.feature_id = f.feature_id
            WHERE up.username = p_username
              AND up.application_id = p_application_id
        )
        SELECT * FROM role_permissions
        UNION ALL
        SELECT * FROM user_permissions
        ORDER BY feature_code, permission_type DESC, permission_level;
        
        RETURN l_cursor;
    END get_user_permissions;

    FUNCTION is_inheritance_active(
        p_application_id IN NUMBER,
        p_inherit_type   IN VARCHAR2
    ) RETURN BOOLEAN
    IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO l_count
        FROM apex_permission_inheritance
        WHERE application_id = p_application_id
          AND inherit_type = p_inherit_type
          AND is_active = 'Y';
        
        RETURN l_count > 0;
    END is_inheritance_active;

END pkg_apex_auth_v2;
/
3. Páginas Administrativas para Gestión de Usuarios
3.1 Página de Gestión de Permisos por Usuario
sql
-- Crear página con reporte interactivo
-- SQL Query para el reporte:
SELECT 
    u.username,
    u.display_name,
    r.role_name,
    f.feature_code,
    f.feature_name,
    COALESCE(up.permission_level, rp.permission_level) as effective_permission,
    CASE 
        WHEN up.permission_level IS NOT NULL THEN 'PERSONALIZADO'
        ELSE 'HEREDADO'
    END as permission_source,
    up.is_granted as user_granted,
    rp.is_granted as role_granted
FROM apex_users u
LEFT JOIN apex_user_roles ur ON u.username = ur.username AND ur.application_id = :APP_ID
LEFT JOIN apex_roles r ON ur.role_id = r.role_id
CROSS JOIN apex_features f
LEFT JOIN apex_user_permissions up ON u.username = up.username 
    AND f.feature_id = up.feature_id 
    AND up.application_id = :APP_ID
LEFT JOIN apex_role_permissions rp ON r.role_id = rp.role_id 
    AND f.feature_id = rp.feature_id 
    AND rp.application_id = :APP_ID
WHERE f.application_id = :APP_ID
ORDER BY u.username, f.feature_code;
3.2 Modal para Editar Permisos de Usuario
Crear un modal con checkboxes para cada permiso:

html
<!-- Checkboxes dinámicos -->
<div class="permisos-container">
    <div class="form-group">
        <label>Usuario: &APP_USER.</label>
        <label>Rol Actual: <span id="rol-actual">COLABORADOR</span></label>
    </div>
    
    <table class="table">
        <thead>
            <tr>
                <th>Feature</th>
                <th>Ver</th>
                <th>Editar</th>
                <th>Crear</th>
                <th>Eliminar</th>
                <th>Denegar</th>
            </tr>
        </thead>
        <tbody>
            <!-- Los registros se generan dinámicamente -->
        </tbody>
    </table>
</div>
3.3 Procesos APEX para Guardar Permisos
sql
-- Proceso AJAX para guardar permisos
DECLARE
    l_username VARCHAR2(100) := :PXX_USERNAME;
    l_feature_code VARCHAR2(100) := :PXX_FEATURE_CODE;
    l_permission VARCHAR2(50) := :PXX_PERMISSION;
    l_action VARCHAR2(10) := :PXX_ACTION; -- 'GRANT' or 'REVOKE'
BEGIN
    IF l_action = 'GRANT' THEN
        pkg_apex_auth_v2.grant_user_permission(
            p_username => l_username,
            p_feature_code => l_feature_code,
            p_permission => l_permission,
            p_application_id => :APP_ID,
            p_granted_by => :APP_USER
        );
    ELSE
        pkg_apex_auth_v2.revoke_user_permission(
            p_username => l_username,
            p_feature_code => l_feature_code,
            p_permission => l_permission,
            p_application_id => :APP_ID,
            p_revoked_by => :APP_USER
        );
    END IF;
    
    apex_json.open_object();
    apex_json.write('status', 'success');
    apex_json.close_object();
EXCEPTION
    WHEN OTHERS THEN
        apex_json.open_object();
        apex_json.write('status', 'error');
        apex_json.write('message', SQLERRM);
        apex_json.close_object();
END;
4. Funciones de Utilidad para Desarrolladores
sql
-- Función simplificada para usar en condiciones APEX
CREATE OR REPLACE FUNCTION f_has_perm(
    p_feature_code IN VARCHAR2,
    p_permission IN VARCHAR2 DEFAULT 'VIEW'
) RETURN VARCHAR2
AS
BEGIN
    RETURN pkg_apex_auth_v2.has_permission(
        :APP_USER,
        :APP_ID,
        p_feature_code,
        p_permission
    );
END;
/

-- Uso en condiciones APEX:
-- f_has_perm('PAGE_1', 'EDIT') = 'Y'
-- f_has_perm('REPORT_EXPORT', 'DOWNLOAD') = 'Y'
5. Políticas de Seguridad Adicionales
5.1 Validación de Acceso Administrativo
sql
-- Solo administradores pueden modificar permisos
CREATE OR REPLACE FUNCTION can_manage_permissions RETURN BOOLEAN
AS
BEGIN
    RETURN pkg_apex_auth_v2.has_permission(
        :APP_USER,
        :APP_ID,
        'ADMIN_PERMISSIONS',
        'FULL'
    ) = 'Y';
END;
/
5.2 Log de Cambios de Permisos
sql
CREATE TABLE apex_permission_audit (
    audit_id NUMBER GENERATED ALWAYS AS IDENTITY,
    username VARCHAR2(100),
    target_user VARCHAR2(100),
    feature_code VARCHAR2(100),
    permission VARCHAR2(50),
    action_type VARCHAR2(20), -- GRANT, REVOKE, UPDATE
    old_value VARCHAR2(100),
    new_value VARCHAR2(100),
    changed_by VARCHAR2(100),
    change_date DATE DEFAULT SYSDATE
);
6. Flujo de Trabajo Recomendado
Permisos por Defecto: Se asignan mediante los roles

Personalización: Los administradores pueden sobrescribir permisos por usuario

Herencia: Los permisos no personalizados se heredan del rol

Prioridad: Permisos de usuario > Permisos de rol

Auditoría: Se registran todos los cambios

Este sistema ahora permite exactamente lo que necesitas: un usuario básico puede tener permisos específicos que sobrescriban los de su rol, dándote flexibilidad total en la gestión de accesos.


















***********************************************************************************************************


Chat GPT

1) Diseño de datos (tablas)

Guarda roles, features y permisos por APP_ID (ya que cada app tiene su propio conjunto). Ejecuta esto en SQL Workshop:

-- Roles por aplicación
CREATE TABLE app_roles (
  role_id      NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
  app_id       NUMBER NOT NULL,
  role_key     VARCHAR2(100) NOT NULL,
  role_label   VARCHAR2(200),
  default_flag CHAR(1) DEFAULT 'N' CHECK (default_flag IN ('Y','N')),
  CONSTRAINT uq_app_role UNIQUE (app_id, role_key)
);

-- Features (cada feature es algo que puede protegerse - por página o funcionalidad)
CREATE TABLE app_features (
  feature_id   NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
  app_id       NUMBER NOT NULL,
  feature_key  VARCHAR2(200) NOT NULL,
  feature_label VARCHAR2(200),
  CONSTRAINT uq_app_feature UNIQUE (app_id, feature_key)
);

-- Acciones permitidas (catálogo)
CREATE TABLE app_actions (
  action_code  VARCHAR2(20) PRIMARY KEY,
  action_label VARCHAR2(200)
);

INSERT INTO app_actions (action_code, action_label) VALUES ('VIEW','Ver');
INSERT INTO app_actions (action_code, action_label) VALUES ('CREATE','Crear');
INSERT INTO app_actions (action_code, action_label) VALUES ('EDIT','Editar');
INSERT INTO app_actions (action_code, action_label) VALUES ('DELETE','Eliminar');
INSERT INTO app_actions (action_code, action_label) VALUES ('PRINT','Imprimir');
INSERT INTO app_actions (action_code, action_label) VALUES ('DOWNLOAD','Descargar');
COMMIT;

-- Permisos asignados a roles (solo guardamos las acciones permitidas)
CREATE TABLE role_permissions (
  role_permission_id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
  role_id            NUMBER NOT NULL,
  feature_id         NUMBER NOT NULL,
  action_code         VARCHAR2(20) NOT NULL,
  CONSTRAINT fk_rp_role FOREIGN KEY (role_id) REFERENCES app_roles(role_id) ON DELETE CASCADE,
  CONSTRAINT fk_rp_feat FOREIGN KEY (feature_id) REFERENCES app_features(feature_id) ON DELETE CASCADE,
  CONSTRAINT fk_rp_act  FOREIGN KEY (action_code) REFERENCES app_actions(action_code),
  CONSTRAINT uq_role_feat_act UNIQUE (role_id, feature_id, action_code)
);

-- Roles asignados a usuarios (por app)
CREATE TABLE user_roles (
  user_role_id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
  app_id       NUMBER NOT NULL,
  username     VARCHAR2(255) NOT NULL,
  role_id      NUMBER NOT NULL,
  CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES app_roles(role_id) ON DELETE CASCADE,
  CONSTRAINT uq_user_role UNIQUE (app_id, username, role_id)
);

-- Overrides por usuario (permite dar/quitar permisos puntuales)
CREATE TABLE user_permissions (
  user_permission_id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
  username           VARCHAR2(255) NOT NULL,
  feature_id         NUMBER NOT NULL,
  action_code         VARCHAR2(20) NOT NULL,
  allowed            CHAR(1) DEFAULT 'Y' CHECK (allowed IN ('Y','N')),
  CONSTRAINT fk_up_feat FOREIGN KEY (feature_id) REFERENCES app_features(feature_id),
  CONSTRAINT fk_up_act  FOREIGN KEY (action_code) REFERENCES app_actions(action_code),
  CONSTRAINT uq_user_perm UNIQUE (username, feature_id, action_code)
);

-- Índices recomendados para rendimiento
CREATE INDEX idx_rp_feat_act ON role_permissions (feature_id, action_code);
CREATE INDEX idx_ur_user_app ON user_roles (username, app_id);
CREATE INDEX idx_up_user_feat ON user_permissions (username, feature_id, action_code);

COMMIT;


Por qué: incluir app_id facilita tener distintos roles/sets por cada aplicación (lo pedías). Mantener user_permissions permite overrides por usuario.

2) Paquete PL/SQL central (lógica de autorización)

Crea un paquete que centralice comprobaciones. Pega esto en SQL Workshop → SQL Commands:

CREATE OR REPLACE PACKAGE app_security_pkg IS
  -- p_action = 'VIEW','CREATE','EDIT','DELETE','PRINT','DOWNLOAD'
  FUNCTION has_permission(
    p_username   IN VARCHAR2,
    p_app_id     IN NUMBER,
    p_feature_key IN VARCHAR2,
    p_action     IN VARCHAR2
  ) RETURN BOOLEAN;

  -- Helper para usar directamente desde APEX (usa :APP_USER y :APP_ID)
  FUNCTION is_authorized_for(
    p_feature_key IN VARCHAR2,
    p_action      IN VARCHAR2
  ) RETURN BOOLEAN;
END app_security_pkg;
/
CREATE OR REPLACE PACKAGE BODY app_security_pkg IS

  FUNCTION has_permission(
    p_username   IN VARCHAR2,
    p_app_id     IN NUMBER,
    p_feature_key IN VARCHAR2,
    p_action     IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_feature_id  NUMBER;
    l_dummy       NUMBER;
  BEGIN
    -- 1) resolver feature_id
    BEGIN
      SELECT feature_id INTO l_feature_id
      FROM app_features
      WHERE app_id = p_app_id
        AND feature_key = p_feature_key;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN FALSE; -- feature desconocida => deny
    END;

    -- 2) override a nivel usuario (allow)
    BEGIN
      SELECT 1 INTO l_dummy
      FROM user_permissions up
      WHERE up.username = p_username
        AND up.feature_id = l_feature_id
        AND up.action_code = p_action
        AND up.allowed = 'Y'
        AND ROWNUM = 1;
      RETURN TRUE;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;

    -- 3) override a nivel usuario (deny) -> si existe un deny explícito, negar
    BEGIN
      SELECT 1 INTO l_dummy
      FROM user_permissions up
      WHERE up.username = p_username
        AND up.feature_id = l_feature_id
        AND up.action_code = p_action
        AND up.allowed = 'N'
        AND ROWNUM = 1;
      RETURN FALSE;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;

    -- 4) permisos por roles asignados al usuario
    BEGIN
      SELECT 1 INTO l_dummy
      FROM user_roles ur
      JOIN role_permissions rp ON ur.role_id = rp.role_id
      WHERE ur.username = p_username
        AND ur.app_id = p_app_id
        AND rp.feature_id = l_feature_id
        AND rp.action_code = p_action
        AND ROWNUM = 1;
      RETURN TRUE;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;

    -- 5) si no tiene roles, probar rol por defecto de la app (si existe)
    BEGIN
      SELECT 1 INTO l_dummy
      FROM app_roles r
      JOIN role_permissions rp ON r.role_id = rp.role_id
      WHERE r.app_id = p_app_id
        AND r.default_flag = 'Y'
        AND rp.feature_id = l_feature_id
        AND rp.action_code = p_action
        AND ROWNUM = 1;
      RETURN TRUE;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;

    RETURN FALSE;
  END has_permission;

  FUNCTION is_authorized_for(
    p_feature_key IN VARCHAR2,
    p_action      IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_user VARCHAR2(255) := v('APP_USER');
    l_app  NUMBER;
  BEGIN
    BEGIN
      l_app := TO_NUMBER(v('APP_ID'));
    EXCEPTION WHEN OTHERS THEN
      l_app := NULL;
    END;

    IF l_user IS NULL OR l_app IS NULL THEN
      RETURN FALSE;
    END IF;

    RETURN has_permission(l_user, l_app, p_feature_key, p_action);
  END is_authorized_for;

END app_security_pkg;
/
COMMIT;


Explicación: is_authorized_for usa las variables de sesión de APEX APP_USER y APP_ID para que puedas llamarla directamente desde un Authorization Scheme.

3) Crear Authorization Scheme(s) en APEX y asignarlos

Crear Authorization Scheme genérico por feature+acción: Shared Components → Security → Authorization Schemes → Create → From Scratch.

Name: e.g. Has permission CUSTOMERS_VIEW

Scheme Type: PL/SQL Function Returning Boolean

PL/SQL Function (poner exactamente):

return app_security_pkg.is_authorized_for('CUSTOMERS','VIEW');


Evaluation Point: Run once per session si quieres cachear la comprobación (mejor rendimiento) — o Run once per page view si prefieres cambios inmediatos sin pedir recache/log out. 
docs.oracle.com
+1

Asignar el Authorization Scheme:

Para una página: Page Designer → Page → Security → Authorization Scheme → selecciona el scheme creado.

Para una región, botón o columna de informe: en el atributo Security/Authorization Scheme asignas el mismo scheme. Esto oculta/niega la UI y evita procesos ejecutarse. 
docs.oracle.com

Escala: puedes automatizar la creación de schemes (manualmente si son pocos). Si hay muchas features, crea un scheme por acción común (*_VIEW, *_EDIT) o usa un pequeño script que cree por ti (APEX no tiene API simple para crear schemes masivamente; normalmente se crean desde UI o export/import). 
Oracle APEX

4) UI de administración (página para administrar roles/permissions)

Crea páginas en APEX (Interactive Grid) para mantener: app_roles, app_features, role_permissions, user_roles, user_permissions.

Después de guardar cambios en role_permissions o user_roles, añade un proceso PL/SQL en el Submit que ejecute:

BEGIN
  apex_authorization.reset_cache; -- fuerza re-evaluar autorizaciones para la sesión actual
END;


Esto es útil si tus Authorization Schemes están Run once per session. Nota: el reset sólo afecta la sesión que ejecuta el proceso; los otros usuarios deben volver a autenticarse o usar una estrategia de notificación/refresh. 
docs.oracle.com
+1

5) Mostrar/ocultar columnas o elementos condicionalmente

En una columna de informe: en Server-side Condition → Authorization Scheme pones el scheme correspondiente.

Para botones/acciones dinámicas: usa Condition -> Authorization Scheme o controla con una Dynamic Action que consulte app_security_pkg.has_permission(...).

6) Estrategias de rendimiento y caching

Cachea (Run once per session) si las asignaciones cambian raramente. Esto reduce consultas por cada componente. Si cambias permisos con frecuencia, usa Run once per page view o llama a apex_authorization.reset_cache tras los cambios. 
docs.oracle.com

Índices: tener índices en role_permissions(feature_id, action_code) y user_roles(username, app_id) acelera las EXISTS.

Evitar SELECT INTO con excepciones en bucles intensos: usa EXISTS en consultas SQL cuando sea posible.

Hacer la resolución de feature_id por clave (feature_key) es más estable que por page_id numérico (si renumeras páginas).

7) Buenas prácticas y consideraciones de diseño

Principio de menor privilegio: por defecto negar; crea un role default con permisos mínimos.

Separación: módulo administrativo distinto del sitio de usuarios. Diferentes apps pueden compartir la misma tabla (filtrando por app_id) o tener tablas separadas si son completamente distintas.

Auditoría: añade role_permissions_audit / triggers para registrar quién y cuándo cambia permisos.

Pruebas: crear cuentas de prueba para cada rol y usar APEX Debug/Session para verificar apex_authorization.is_authorized y que los schemes se evalúan como esperas. 
docs.oracle.com

Integración con IdP / grupos externos: si usas un proveedor de identidad (OpenID/OAuth), mapea grupos/roles al login y usa APEX_AUTHORIZATION.ENABLE_DYNAMIC_GROUPS en post-login para habilitar grupos dinámicos en la sesión (útil para sincronizar grupos sin persistirlos). 
docs.oracle.com
+1

Evitar lógica de autorización dispersa: centraliza toda la lógica en app_security_pkg para facilitar auditoría y tests unitarios (procedimientos p.ej. has_permission), y no dispersar IF user = 'ADMIN' por todo el app.

8) Cosas frecuentes que fallan (y cómo evitarlas)

Cambias permisos pero no se reflejan: APEX cachea el resultado del scheme; llama a apex_authorization.reset_cache o pide re-login. 
docs.oracle.com

Asignaciones por error a APP_USER vs username: decide si vas a usar emails, user_id numérico o APP_USER y manténlo consistente.

Perdida de performance al comprobar muchas filas: indexar, y preferir Run once per session cuando sea seguro.

9) Checklist de producción antes del despliegue

Índices y estadísticas actualizadas en tablas de permisos.

Pruebas con usuarios reales (4 roles mínimos).

Páginas admin con logs y botón de “Refresh my rights” que haga apex_authorization.reset_cache.

Documentación de feature_key para desarrolladores.

Revisión de SQL para evitar inyección (usar binds).

Políticas de escalado (quién otorga roles, flujos de solicitud de permiso).

Referencias útiles (documentación oficial y recursos)

Cómo funcionan los Authorization Schemes en APEX. 
docs.oracle.com

Crear/editar Authorization Schemes (pasos, evaluation points). 
docs.oracle.com

APEX cachea autorizaciones; cómo resetear el cache. 
docs.oracle.com
+1

Access Control / Application Access Control (wizard para ACLs). 
docs.oracle.com

API APEX_AUTHORIZATION (ENABLE_DYNAMIC_GROUPS, IS_AUTHORIZED, RESET_CACHE). 
docs.oracle.com

Si quieres, en el siguiente mensaje hago dos cosas concretas (elige una o ambas):

Te devuelvo un script SQL completo ya parametrizado para tu APP_ID (reemplazo automático del APP_ID, roles iniciales: ADMIN/COLABORADOR/AUDITOR/USUARIO_BASICO y ejemplos de features como CUSTOMERS, ORDERS).

Te doy el paso a paso con capturas dentro del APEX Builder (dónde pegar el código exactamente, screenshots de Shared Components y Page Designer).

Dime cuál prefieres y lo genero ya (sin esperas).




Integración del Sistema de Permisos en Páginas APEX
Te muestro cómo implementar los controles de permisos en tus páginas específicas:

1. Configuración de Autorización por Página
1.1 En la Página 10 (Registro Visitas)
Propiedades de Página → Autorización Esquema:

Tipo: Función que devuelve Booleano

Nombre de la función: f_has_page_access(10, 'VIEW')

sql
CREATE OR REPLACE FUNCTION f_has_page_access(
    p_page_id IN NUMBER,
    p_permission IN VARCHAR2 DEFAULT 'VIEW'
) RETURN BOOLEAN
AS
BEGIN
    RETURN pkg_apex_auth_v2.has_permission(
        :APP_USER,
        :APP_ID,
        'PAGE_' || p_page_id,
        p_permission
    ) = 'Y';
END;
/
2. Configuración de Componentes en Página 15 (Registro Incidencias)
2.1 Classic Report - Control de Columnas
En la definición del Classic Report, usar condiciones en columnas:

sql
-- Columna "Acciones" - Solo mostrar si tiene permiso EDIT
SELECT 
    incidencia_id,
    descripcion,
    fecha,
    -- Columna de acciones condicional
    CASE 
        WHEN f_has_perm('PAGE_15', 'EDIT') = 'Y' THEN
            '<button class="t-Button t-Button--small" onclick="editarIncidencia('||incidencia_id||')">Editar</button>'
        ELSE
            NULL
    END as acciones
FROM incidencias
2.2 Condiciones en Botones
Botón "Nueva Incidencia":

Tipo de Condición: Función PL/SQL que devuelve Booleano

Expresión: RETURN f_has_perm('PAGE_15', 'CREATE') = 'Y';

Botón "Imprimir Reporte":

Tipo de Condición: Función PL/SQL que devuelve BooleAN

Expresión: RETURN f_has_perm('PAGE_15', 'PRINT') = 'Y';

Botón "Exportar Excel":

Tipo de Condición: Función PL/SQL que devuelve BooleAN

Expresión: RETURN f_has_perm('PAGE_15', 'DOWNLOAD') = 'Y';

2.3 Proceso de Eliminación - Validación de Permisos
Crear proceso de eliminación con validación:

sql
DECLARE
    l_has_delete_permission BOOLEAN;
BEGIN
    -- Verificar permiso antes de eliminar
    l_has_delete_permission := f_has_perm('PAGE_15', 'DELETE');
    
    IF NOT l_has_delete_permission THEN
        apex_error.add_error(
            p_message => 'No tiene permisos para eliminar incidencias',
            p_display_location => apex_error.c_inline_in_notification
        );
        RETURN;
    END IF;
    
    -- Procedimiento de eliminación
    DELETE FROM incidencias 
    WHERE incidencia_id = :P15_INCIDENCIA_ID;
    
    :P15_SUCCESS_MESSAGE := 'Incidencia eliminada correctamente';
END;
3. Configuración de Regions Dinámicas
3.1 Region con Información Sensible
En propiedades de la Region:

Condición: Función PL/SQL que devuelve Booleano

Expresión: RETURN f_has_perm('PAGE_15', 'VIEW') = 'Y';

3.2 Region de Estadísticas (solo para editores)
sql
-- Condición de la region
RETURN f_has_perm('PAGE_15', 'EDIT') = 'Y';
4. JavaScript Dinámico para Ocultar Elementos
4.1 Crear Dynamic Action en la Página 15
Evento: Page Load
Condición: Ninguna

Acción True:

Tipo: Ejecutar Código JavaScript

Código:

javascript
// Ocultar/mostrar elementos basado en permisos
function aplicarPermisosPagina() {
    // Verificar permisos via AJAX
    apex.server.process(
        'CHECK_PERMISSIONS',
        {
            pageId: 15,
            x01: 'VIEW,EDIT,CREATE,DELETE,PRINT,DOWNLOAD'
        },
        {
            success: function(data) {
                // Ocultar botón Imprimir si no tiene permiso
                if (!data.permissions.PRINT) {
                    $('.js-print-btn').hide();
                }
                
                // Ocultar botón Exportar si no tiene permiso
                if (!data.permissions.DOWNLOAD) {
                    $('.js-export-btn').hide();
                }
                
                // Ocultar columna acciones si no tiene EDIT
                if (!data.permissions.EDIT) {
                    $('.js-actions-col').hide();
                }
                
                // Deshabilitar botón Eliminar
                if (!data.permissions.DELETE) {
                    $('.js-delete-btn').prop('disabled', true).addClass('is-disabled');
                }
            }
        }
    );
}

// Ejecutar al cargar la página
apicarPermisosPagina();
4.2 Proceso AJAX para Verificar Múltiples Permisos
sql
-- Proceso APEX: CHECK_PERMISSIONS
DECLARE
    l_permissions VARCHAR2(200) := apex_application.g_x01;
    l_page_id NUMBER := :APP_PAGE_ID;
    l_permission_list apex_t_varchar2;
BEGIN
    l_permission_list := apex_string.split(l_permissions, ',');
    
    apex_json.open_object;
    
    FOR i IN 1..l_permission_list.count LOOP
        apex_json.write(
            l_permission_list(i),
            CASE 
                WHEN pkg_apex_auth_v2.has_permission(
                    :APP_USER, :APP_ID, 'PAGE_' || l_page_id, l_permission_list(i)
                ) = 'Y' THEN 'true'
                ELSE 'false'
            END
        );
    END LOOP;
    
    apex_json.close_object;
END;
5. Configuración de Tabs y Navegación
5.1 Condición en Tabs de Navegación
Para el Tab "Registro Visitas":

Condición: Función PL/SQL

Expresión: RETURN f_has_page_access(10) = TRUE;

Para el Tab "Registro Incidencias":

Condición: Función PL/SQL

Expresión: RETURN f_has_page_access(15) = TRUE;

6. Validación en Procesos de DML
6.1 Proceso de Actualización con Validación
sql
DECLARE
    l_has_edit_permission BOOLEAN;
BEGIN
    -- Validar permiso de edición
    l_has_edit_permission := f_has_perm('PAGE_15', 'EDIT');
    
    IF NOT l_has_edit_permission THEN
        RAISE_APPLICATION_ERROR(-20001, 'No tiene permisos para editar incidencias');
    END IF;
    
    -- Actualizar registro
    UPDATE incidencias 
    SET descripcion = :P15_DESCRIPCION,
        estado = :P15_ESTADO
    WHERE incidencia_id = :P15_INCIDENCIA_ID;
END;
7. Configuración para PEPITO Específico
7.1 Script de Configuración para PEPITO
sql
-- PEPITO puede ver página 15 pero con restricciones
BEGIN
    -- Permiso para VER página 15
    pkg_apex_auth_v2.grant_user_permission(
        p_username => 'PEPITO',
        p_feature_code => 'PAGE_15',
        p_permission => 'VIEW',
        p_application_id => 100,
        p_granted_by => 'ADMIN'
    );
    
    -- DENEGAR permiso para EDITAR en página 15
    pkg_apex_auth_v2.grant_user_permission(
        p_username => 'PEPITO',
        p_feature_code => 'PAGE_15',
        p_permission => 'EDIT',
        p_application_id => 100,
        p_is_granted => 'N', -- DENEGAR
        p_granted_by => 'ADMIN'
    );
    
    -- DENEGAR permiso para ELIMINAR
    pkg_apex_auth_v2.grant_user_permission(
        p_username => 'PEPITO',
        p_feature_code => 'PAGE_15',
        p_permission => 'DELETE',
        p_application_id => 100,
        p_is_granted => 'N',
        p_granted_by => 'ADMIN'
    );
    
    -- DENEGAR permiso para IMPRIMIR
    pkg_apex_auth_v2.grant_user_permission(
        p_username => 'PEPITO',
        p_feature_code => 'PAGE_15',
        p_permission => 'PRINT',
        p_application_id => 100,
        p_is_granted => 'N',
        p_granted_by => 'ADMIN'
    );
    
    -- DENEGAR permiso para DESCARGAR
    pkg_apex_auth_v2.grant_user_permission(
        p_username => 'PEPITO',
        p_feature_code => 'PAGE_15',
        p_permission => 'DOWNLOAD',
        p_application_id => 100,
        p_is_granted => 'N',
        p_granted_by => 'ADMIN'
    );
    
    COMMIT;
END;
/
8. Función de Utilidad Mejorada
sql
CREATE OR REPLACE FUNCTION f_has_perm(
    p_feature_code IN VARCHAR2,
    p_permission IN VARCHAR2 DEFAULT 'VIEW'
) RETURN VARCHAR2
AS
    l_result VARCHAR2(1);
BEGIN
    -- Si es una página, agregar prefijo
    IF REGEXP_LIKE(p_feature_code, '^[0-9]+$') THEN
        l_result := pkg_apex_auth_v2.has_permission(
            :APP_USER,
            :APP_ID,
            'PAGE_' || p_feature_code,
            p_permission
        );
    ELSE
        l_result := pkg_apex_auth_v2.has_permission(
            :APP_USER,
            :APP_ID,
            p_feature_code,
            p_permission
        );
    END IF;
    
    RETURN l_result;
END;
/

-- Uso simplificado en condiciones:
-- f_has_perm('15', 'VIEW') = 'Y'  -- Para página 15
-- f_has_perm('REPORT_EXPORT', 'DOWNLOAD') = 'Y'  -- Para feature específico
9. Template de Página con Seguridad Integrada
9.1 Crear Plantilla de Página Segura
En el HTML Header de la plantilla:

html
<script>
// Verificar permisos al cargar la página
$(document).ready(function() {
    // Verificar si el usuario tiene acceso a la página
    apex.server.process('CHECK_PAGE_ACCESS', {
        pageId: &APP_PAGE_ID.
    }, {
        success: function(data) {
            if (!data.hasAccess) {
                // Redirigir a página de acceso denegado
                window.location.href = 'f?p=&APP_ID.:999:&APP_SESSION.';
            }
        }
    });
});
</script>
10. Monitorización y Debug
10.1 Página de Debug de Permisos (solo Admin)
sql
-- Reporte para ver permisos actuales de PEPITO
SELECT 
    f.feature_code,
    f.feature_name,
    'ROL' as tipo,
    rp.permission_level,
    rp.is_granted
FROM apex_role_permissions rp
JOIN apex_features f ON rp.feature_id = f.feature_id
JOIN apex_user_roles ur ON rp.role_id = ur.role_id
WHERE ur.username = 'PEPITO'
  AND ur.application_id = :APP_ID

UNION ALL

SELECT 
    f.feature_code,
    f.feature_name,
    'USUARIO' as tipo,
    up.permission_level,
    up.is_granted
FROM apex_user_permissions up
JOIN apex_features f ON up.feature_id = f.feature_id
WHERE up.username = 'PEPITO'
  AND up.application_id = :APP_ID

ORDER BY feature_code, tipo;
Con esta implementación, PEPITO podrá:

✅ Ver la página 15 (Registro Incidencias)

❌ No ver botones de Editar/Eliminar

❌ No ver botón de Imprimir

❌ No ver botón de Exportar

❌ No poder ejecutar acciones de modificación

Y para la página 10 (Registro Visitas), simplemente no tendrá el permiso VIEW, por lo que no podrá acceder en absoluto.









































***********************************************************************************************************


Perfecto! Entonces necesitas actualizar todas las referencias de las tablas en el paquete. Aquí está la versión completa corregida con todos los nombres CO_:

Paquete Completo Corregido con Nombres CO_
sql
CREATE OR REPLACE PACKAGE pkg_apex_auth_v2 AS
    
    -- Constantes
    C_PERM_VIEW     CONSTANT VARCHAR2(10) := 'VIEW';
    C_PERM_EDIT     CONSTANT VARCHAR2(10) := 'EDIT';
    C_PERM_CREATE   CONSTANT VARCHAR2(10) := 'CREATE';
    C_PERM_DELETE   CONSTANT VARCHAR2(10) := 'DELETE';
    C_PERM_PRINT    CONSTANT VARCHAR2(10) := 'PRINT';
    C_PERM_DOWNLOAD CONSTANT VARCHAR2(10) := 'DOWNLOAD';
    C_PERM_FULL     CONSTANT VARCHAR2(10) := 'FULL';
    C_PERM_DENY     CONSTANT VARCHAR2(10) := 'DENY';
    
    -- Función principal mejorada que considera usuario + rol
    FUNCTION has_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2 DEFAULT C_PERM_VIEW
    ) RETURN VARCHAR2;
    
    -- Función para obtener permisos específicos del usuario
    FUNCTION get_user_specific_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_id    IN NUMBER,
        p_permission    IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- Función para obtener permisos del rol
    FUNCTION get_role_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_id    IN NUMBER,
        p_permission    IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- Procedimiento para asignar permiso específico a usuario
    PROCEDURE grant_user_permission(
        p_username      IN VARCHAR2,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2,
        p_application_id IN NUMBER,
        p_is_granted    IN VARCHAR2 DEFAULT 'Y',
        p_granted_by    IN VARCHAR2
    );
    
    -- Procedimiento para revocar permiso específico
    PROCEDURE revoke_user_permission(
        p_username      IN VARCHAR2,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2,
        p_application_id IN NUMBER,
        p_revoked_by    IN VARCHAR2
    );
    
    -- Función para listar permisos de usuario (rol + específicos)
    FUNCTION get_user_permissions(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER
    ) RETURN SYS_REFCURSOR;
    
    -- Función para verificar herencia activa
    FUNCTION is_inheritance_active(
        p_application_id IN NUMBER,
        p_inherit_type   IN VARCHAR2
    ) RETURN BOOLEAN;

END pkg_apex_auth_v2;
/

CREATE OR REPLACE PACKAGE BODY pkg_apex_auth_v2 AS

    FUNCTION get_user_specific_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_id    IN NUMBER,
        p_permission    IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_result VARCHAR2(1) := NULL;
    BEGIN
        SELECT up.is_granted
        INTO l_result
        FROM co_user_permissions up  -- ← CORREGIDO
        WHERE up.username = p_username
          AND up.feature_id = p_feature_id
          AND up.application_id = p_application_id
          AND up.is_granted IN ('Y','N')
          AND (up.permission_level = p_permission 
               OR up.permission_level = C_PERM_FULL
               OR up.permission_level = C_PERM_DENY);
        
        RETURN l_result;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN TOO_MANY_ROWS THEN
            BEGIN
                SELECT MAX(is_granted) KEEP (
                    DENSE_RANK FIRST ORDER BY 
                    CASE permission_level 
                        WHEN C_PERM_DENY THEN 1
                        WHEN C_PERM_FULL THEN 2
                        ELSE 3 
                    END
                )
                INTO l_result
                FROM co_user_permissions  -- ← CORREGIDO
                WHERE username = p_username
                  AND feature_id = p_feature_id
                  AND application_id = p_application_id;
                
                RETURN l_result;
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN NULL;
            END;
    END get_user_specific_permission;

    FUNCTION get_role_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_id    IN NUMBER,
        p_permission    IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_result VARCHAR2(1) := 'N';
    BEGIN
        SELECT MAX('Y')
        INTO l_result
        FROM co_role_permissions rp  -- ← CORREGIDO
        JOIN co_user_roles ur ON rp.role_id = ur.role_id  -- ← CORREGIDO
        WHERE ur.username = p_username
          AND ur.application_id = p_application_id
          AND ur.is_active = 'Y'
          AND rp.feature_id = p_feature_id
          AND rp.is_granted = 'Y'
          AND (rp.permission_level = p_permission 
               OR rp.permission_level = C_PERM_FULL
               OR (p_permission = C_PERM_VIEW AND rp.permission_level IN (C_PERM_EDIT, C_PERM_CREATE, C_PERM_DELETE)));
        
        RETURN NVL(l_result, 'N');
        
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'N';
    END get_role_permission;

    FUNCTION has_permission(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2 DEFAULT C_PERM_VIEW
    ) RETURN VARCHAR2
    IS
        l_feature_id    NUMBER;
        l_user_perm     VARCHAR2(1);
        l_role_perm     VARCHAR2(1);
        l_inheritance   BOOLEAN;
    BEGIN
        SELECT feature_id INTO l_feature_id
        FROM co_features  -- ← CORREGIDO
        WHERE feature_code = p_feature_code
          AND application_id = p_application_id;

        l_user_perm := get_user_specific_permission(
            p_username, p_application_id, l_feature_id, p_permission
        );
        
        IF l_user_perm IS NOT NULL THEN
            RETURN l_user_perm;
        END IF;
        
        l_inheritance := is_inheritance_active(p_application_id, 'ROLE_TO_USER');
        
        IF l_inheritance THEN
            l_role_perm := get_role_permission(
                p_username, p_application_id, l_feature_id, p_permission
            );
            
            RETURN l_role_perm;
        ELSE
            RETURN 'N';
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'N'; -- Feature no existe
        WHEN OTHERS THEN
            RETURN 'N';
    END has_permission;

    PROCEDURE grant_user_permission(
        p_username      IN VARCHAR2,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2,
        p_application_id IN NUMBER,
        p_is_granted    IN VARCHAR2 DEFAULT 'Y',
        p_granted_by    IN VARCHAR2
    )
    IS
        l_feature_id NUMBER;
    BEGIN
        SELECT feature_id INTO l_feature_id
        FROM co_features  -- ← CORREGIDO
        WHERE feature_code = p_feature_code
          AND application_id = p_application_id;
        
        MERGE INTO co_user_permissions up  -- ← CORREGIDO
        USING (SELECT p_username as username, l_feature_id as feature_id FROM dual) src
        ON (up.username = src.username AND up.feature_id = src.feature_id AND up.permission_level = p_permission)
        WHEN MATCHED THEN
            UPDATE SET 
                up.is_granted = p_is_granted,
                up.updated_by = p_granted_by,
                up.updated_date = SYSDATE
        WHEN NOT MATCHED THEN
            INSERT (username, feature_id, permission_level, is_granted, application_id, created_by)
            VALUES (p_username, l_feature_id, p_permission, p_is_granted, p_application_id, p_granted_by);
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error al asignar permiso: ' || SQLERRM);
    END grant_user_permission;

    PROCEDURE revoke_user_permission(
        p_username      IN VARCHAR2,
        p_feature_code  IN VARCHAR2,
        p_permission    IN VARCHAR2,
        p_application_id IN NUMBER,
        p_revoked_by    IN VARCHAR2
    )
    IS
        l_feature_id NUMBER;
    BEGIN
        SELECT feature_id INTO l_feature_id
        FROM co_features  -- ← CORREGIDO
        WHERE feature_code = p_feature_code
          AND application_id = p_application_id;
        
        DELETE FROM co_user_permissions  -- ← CORREGIDO
        WHERE username = p_username
          AND feature_id = l_feature_id
          AND permission_level = p_permission
          AND application_id = p_application_id;
        
        COMMIT;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- El permiso no existía, no hay problema
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20003, 'Error al revocar permiso: ' || SQLERRM);
    END revoke_user_permission;

    FUNCTION get_user_permissions(
        p_username      IN VARCHAR2,
        p_application_id IN NUMBER
    ) RETURN SYS_REFCURSOR
    IS
        l_cursor SYS_REFCURSOR;
    BEGIN
        OPEN l_cursor FOR
        WITH user_roles AS (
            SELECT r.role_id, r.role_name
            FROM co_user_roles ur  -- ← CORREGIDO
            JOIN co_roles r ON ur.role_id = r.role_id  -- ← CORREGIDO
            WHERE ur.username = p_username
              AND ur.application_id = p_application_id
              AND ur.is_active = 'Y'
              AND r.is_active = 'Y'
        ),
        role_permissions AS (
            SELECT 
                f.feature_code,
                f.feature_name,
                rp.permission_level,
                'ROLE' as permission_type,
                ur.role_name,
                rp.is_granted
            FROM co_role_permissions rp  -- ← CORREGIDO
            JOIN co_features f ON rp.feature_id = f.feature_id  -- ← CORREGIDO
            JOIN user_roles ur ON rp.role_id = ur.role_id
            WHERE rp.application_id = p_application_id
        ),
        user_permissions AS (
            SELECT 
                f.feature_code,
                f.feature_name,
                up.permission_level,
                'USER' as permission_type,
                NULL as role_name,
                up.is_granted
            FROM co_user_permissions up  -- ← CORREGIDO
            JOIN co_features f ON up.feature_id = f.feature_id  -- ← CORREGIDO
            WHERE up.username = p_username
              AND up.application_id = p_application_id
        )
        SELECT * FROM role_permissions
        UNION ALL
        SELECT * FROM user_permissions
        ORDER BY feature_code, permission_type DESC, permission_level;
        
        RETURN l_cursor;
    END get_user_permissions;

    FUNCTION is_inheritance_active(
        p_application_id IN NUMBER,
        p_inherit_type   IN VARCHAR2
    ) RETURN BOOLEAN
    IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO l_count
        FROM co_permission_inheritance  -- ← CORREGIDO (asumiendo que también la renombraste)
        WHERE application_id = p_application_id
          AND inherit_type = p_inherit_type
          AND is_active = 'Y';
        
        RETURN l_count > 0;
    END is_inheritance_active;

END pkg_apex_auth_v2;
/
Verificación de Todas las Tablas CO_
Antes de ejecutar, verifica que tengas todas las tablas con el prefijo CO_:

sql
-- Verificar todas tus tablas CO_
SELECT table_name FROM user_tables 
WHERE table_name LIKE 'CO\_%' ESCAPE '\'
ORDER BY table_name;
Si Faltara Alguna Tabla, Aquí Están los CREATE TABLE Corregidos:
sql
-- Tabla de Roles
CREATE TABLE co_roles (
    role_id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name        VARCHAR2(100) NOT NULL UNIQUE,
    role_description VARCHAR2(500),
    application_id   NUMBER NOT NULL,
    is_active        VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y','N')),
    created_by       VARCHAR2(100),
    created_date     DATE DEFAULT SYSDATE,
    updated_by       VARCHAR2(100),
    updated_date     DATE
);

-- Tabla de User Roles
CREATE TABLE co_user_roles (
    user_role_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username         VARCHAR2(100) NOT NULL,
    role_id          NUMBER NOT NULL REFERENCES co_roles(role_id),
    application_id   NUMBER NOT NULL,
    is_active        VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y','N')),
    start_date       DATE DEFAULT SYSDATE,
    end_date         DATE,
    created_by       VARCHAR2(100),
    created_date     DATE DEFAULT SYSDATE
);

-- Tabla de Role Permissions
CREATE TABLE co_role_permissions (
    permission_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_id          NUMBER NOT NULL REFERENCES co_roles(role_id),
    feature_id       NUMBER NOT NULL REFERENCES co_features(feature_id),
    permission_level VARCHAR2(50) CHECK (permission_level IN ('VIEW','EDIT','CREATE','DELETE','PRINT','DOWNLOAD','FULL')),
    is_granted       VARCHAR2(1) DEFAULT 'Y' CHECK (is_granted IN ('Y','N')),
    application_id   NUMBER NOT NULL,
    created_by       VARCHAR2(100),
    created_date     DATE DEFAULT SYSDATE,
    updated_by       VARCHAR2(100),
    updated_date     DATE,
    UNIQUE (role_id, feature_id, permission_level)
);

-- Tabla de User Permissions
CREATE TABLE co_user_permissions (
    user_permission_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username         VARCHAR2(100) NOT NULL,
    feature_id       NUMBER NOT NULL REFERENCES co_features(feature_id),
    permission_level VARCHAR2(50) CHECK (permission_level IN ('VIEW','EDIT','CREATE','DELETE','PRINT','DOWNLOAD','FULL','DENY')),
    is_granted       VARCHAR2(1) DEFAULT 'Y' CHECK (is_granted IN ('Y','N')),
    application_id   NUMBER NOT NULL,
    created_by       VARCHAR2(100),
    created_date     DATE DEFAULT SYSDATE,
    updated_by       VARCHAR2(100),
    updated_date     DATE,
    UNIQUE (username, feature_id, permission_level)
);

-- Tabla de Permission Inheritance
CREATE TABLE co_permission_inheritance (
    inheritance_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    application_id   NUMBER NOT NULL,
    inherit_type     VARCHAR2(20) CHECK (inherit_type IN ('ROLE_TO_USER', 'PARENT_TO_CHILD')),
    is_active        VARCHAR2(1) DEFAULT 'Y',
    created_by       VARCHAR2(100),
    created_date     DATE DEFAULT SYSDATE
);
Función Simplificada para APEX
sql
CREATE OR REPLACE FUNCTION f_has_perm(
    p_feature_code IN VARCHAR2,
    p_permission IN VARCHAR2 DEFAULT 'VIEW'
) RETURN VARCHAR2
AS
BEGIN
    RETURN pkg_apex_auth_v2.has_permission(
        :APP_USER,
        :APP_ID,
        p_feature_code,
        p_permission
    );
END;
/
Ahora el paquete debería compilar sin errores, ya que todas las referencias a tablas están actualizadas al esquema CO_.
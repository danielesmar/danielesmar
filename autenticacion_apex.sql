CREATE OR REPLACE PACKAGE apex_authentication AS

    -- Función principal de login
    FUNCTION login(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN BOOLEAN;
    
    -- Función para verificar si el usuario está autenticado
    FUNCTION is_authenticated RETURN BOOLEAN;
    
    -- Procedimiento para logout
    PROCEDURE logout;
    
    -- Función para obtener el ID de usuario
    FUNCTION get_user_id RETURN NUMBER;
    
    -- Función para obtener el nombre de usuario
    FUNCTION get_username RETURN VARCHAR2;
    
    -- Procedimiento para registrar intento de login fallido
    PROCEDURE register_failed_attempt(
        p_username IN VARCHAR2,
        p_ip_address IN VARCHAR2 DEFAULT NULL
    );
    
    -- Función para verificar si la cuenta está bloqueada
    FUNCTION is_account_locked(
        p_username IN VARCHAR2
    ) RETURN BOOLEAN;

END apex_authentication;
/

CREATE OR REPLACE PACKAGE BODY apex_authentication AS

    -- Tabla de usuarios (debes adaptarla a tu esquema)
    /*
    CREATE TABLE users (
        user_id NUMBER PRIMARY KEY,
        username VARCHAR2(50) UNIQUE NOT NULL,
        password_hash VARCHAR2(100) NOT NULL,
        email VARCHAR2(100),
        is_active CHAR(1) DEFAULT 'Y',
        failed_attempts NUMBER DEFAULT 0,
        last_login_date DATE,
        account_locked_until DATE,
        created_date DATE DEFAULT SYSDATE
    );
    */

    FUNCTION login(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN BOOLEAN
    IS
        l_password_hash VARCHAR2(100);
        l_stored_hash VARCHAR2(100);
        l_user_id NUMBER;
        l_is_active CHAR(1);
        l_failed_attempts NUMBER;
        l_account_locked_until DATE;
        l_max_attempts NUMBER := 5; -- Máximo de intentos fallidos
        l_lock_time NUMBER := 30; -- Tiempo de bloqueo en minutos
    BEGIN
        -- Verificar si la cuenta está bloqueada
        IF is_account_locked(p_username) THEN
            RETURN FALSE;
        END IF;

        -- Obtener información del usuario
        BEGIN
            SELECT user_id, password_hash, is_active, failed_attempts, account_locked_until
            INTO l_user_id, l_stored_hash, l_is_active, l_failed_attempts, l_account_locked_until
            FROM users
            WHERE UPPER(username) = UPPER(p_username);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Registrar intento fallido para usuario inexistente (opcional)
                register_failed_attempt(p_username, APEX_APPLICATION.G_X01);
                RETURN FALSE;
        END;

        -- Verificar si el usuario está activo
        IF l_is_active != 'Y' THEN
            RETURN FALSE;
        END IF;

        -- Generar hash de la contraseña proporcionada (usa tu método preferido)
        l_password_hash := generate_password_hash(p_password);

        -- Verificar contraseña
        IF l_stored_hash = l_password_hash THEN
            -- Login exitoso
            -- Resetear intentos fallidos
            UPDATE users 
            SET failed_attempts = 0,
                account_locked_until = NULL,
                last_login_date = SYSDATE
            WHERE user_id = l_user_id;
            
            COMMIT;

            -- Establecer variables de sesión de APEX
            APEX_UTIL.SET_SESSION_STATE('APP_USER', p_username);
            APEX_UTIL.SET_SESSION_STATE('USER_ID', l_user_id);
            APEX_UTIL.SET_SESSION_STATE('LOGGED_IN', 'YES');

            RETURN TRUE;
        ELSE
            -- Login fallido
            register_failed_attempt(p_username, APEX_APPLICATION.G_X01);
            
            -- Incrementar intentos fallidos
            l_failed_attempts := l_failed_attempts + 1;
            
            -- Bloquear cuenta si excede el máximo de intentos
            IF l_failed_attempts >= l_max_attempts THEN
                UPDATE users 
                SET account_locked_until = SYSDATE + (l_lock_time / 1440), -- Convertir minutos a días
                    failed_attempts = l_failed_attempts
                WHERE user_id = l_user_id;
            ELSE
                UPDATE users 
                SET failed_attempts = l_failed_attempts
                WHERE user_id = l_user_id;
            END IF;
            
            COMMIT;
            RETURN FALSE;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- Log del error (opcional)
            APEX_DEBUG.ERROR('Error en login: ' || SQLERRM);
            RETURN FALSE;
    END login;

    FUNCTION is_authenticated RETURN BOOLEAN
    IS
        l_logged_in VARCHAR2(3);
    BEGIN
        l_logged_in := APEX_UTIL.GET_SESSION_STATE('LOGGED_IN');
        RETURN (l_logged_in = 'YES');
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END is_authenticated;

    PROCEDURE logout
    IS
    BEGIN
        -- Limpiar variables de sesión
        APEX_UTIL.SET_SESSION_STATE('APP_USER', '');
        APEX_UTIL.SET_SESSION_STATE('USER_ID', '');
        APEX_UTIL.SET_SESSION_STATE('LOGGED_IN', 'NO');
        
        -- Opcional: Invalidar sesión de APEX
        APEX_SESSION.DELETE_SESSION(
            p_session_id => APEX_APPLICATION.G_INSTANCE
        );
    END logout;

    FUNCTION get_user_id RETURN NUMBER
    IS
    BEGIN
        RETURN TO_NUMBER(APEX_UTIL.GET_SESSION_STATE('USER_ID'));
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_user_id;

    FUNCTION get_username RETURN VARCHAR2
    IS
    BEGIN
        RETURN APEX_UTIL.GET_SESSION_STATE('APP_USER');
    END get_username;

    PROCEDURE register_failed_attempt(
        p_username IN VARCHAR2,
        p_ip_address IN VARCHAR2 DEFAULT NULL
    )
    IS
        PRAGMA AUTONOMOUS_TRANSACTION; -- Para poder hacer commit independiente
    BEGIN
        -- Insertar en tabla de logs de intentos fallidos (opcional)
        INSERT INTO login_attempts (
            username,
            attempt_date,
            ip_address,
            success
        ) VALUES (
            p_username,
            SYSDATE,
            p_ip_address,
            'N'
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- Ignorar errores en el logging
    END register_failed_attempt;

    FUNCTION is_account_locked(
        p_username IN VARCHAR2
    ) RETURN BOOLEAN
    IS
        l_account_locked_until DATE;
    BEGIN
        SELECT account_locked_until
        INTO l_account_locked_until
        FROM users
        WHERE UPPER(username) = UPPER(p_username);
        
        RETURN (l_account_locked_until IS NOT NULL AND l_account_locked_until > SYSDATE);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END is_account_locked;

    -- Función auxiliar para generar hash de contraseña
    FUNCTION generate_password_hash(
        p_password IN VARCHAR2
    ) RETURN VARCHAR2
    IS
    BEGIN
        -- Ejemplo usando DBMS_CRYPTO (requiere permisos adicionales)
        RETURN LOWER(RAWTOHEX(DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(p_password, 'AL32UTF8'), DBMS_CRYPTO.HASH_SH256)));
        
        -- Alternativa más simple (menos segura):
        -- RETURN p_password; -- NO USAR EN PRODUCCIÓN
    EXCEPTION
        WHEN OTHERS THEN
            -- Fallback simple (solo para desarrollo)
            RETURN p_password;
    END generate_password_hash;

END apex_authentication;
/
Estructura de tablas necesarias:

sql
-- Tabla de usuarios
CREATE TABLE users (
    user_id NUMBER PRIMARY KEY,
    username VARCHAR2(50) UNIQUE NOT NULL,
    password_hash VARCHAR2(100) NOT NULL,
    email VARCHAR2(100),
    is_active CHAR(1) DEFAULT 'Y',
    failed_attempts NUMBER DEFAULT 0,
    last_login_date DATE,
    account_locked_until DATE,
    created_date DATE DEFAULT SYSDATE
);

-- Secuencia para user_id
CREATE SEQUENCE seq_users_id START WITH 1 INCREMENT BY 1;

-- Tabla de logs de intentos de login (opcional)
CREATE TABLE login_attempts (
    attempt_id NUMBER PRIMARY KEY,
    username VARCHAR2(50),
    attempt_date DATE,
    ip_address VARCHAR2(45),
    success CHAR(1)
);

CREATE SEQUENCE seq_login_attempts_id START WITH 1 INCREMENT BY 1;
Uso en APEX:

En el proceso de autenticación de APEX:

Esquema de autenticación: Custom

Función de verificación: apex_authentication.login

En páginas que requieran autenticación, puedes usar:

sql
BEGIN
    IF NOT apex_authentication.is_authenticated THEN
        -- Redirigir a página de login
        APEX_UTIL.REDIRECT_URL('f?p=' || :APP_ID || ':LOGIN_PAGE_ID:' || :APP_SESSION);
    END IF;
END;
Características incluidas:

Validación de credenciales

Control de intentos fallidos

Bloqueo temporal de cuentas

Manejo de sesiones

Logs de seguridad

Funciones auxiliares para gestión de usuarios

¿Necesitas que adapte alguna parte específica o que agregue alguna funcionalidad adicional?
# Informe técnico: Confiabilidad y publicación de aplicaciones públicas con Oracle APEX

**Fecha:** 11 de noviembre de 2026\
**Objetivo:** Evaluar la viabilidad de publicar una aplicación Oracle
APEX de acceso público y establecer los principales requisitos de
arquitectura, seguridad, rendimiento y operación.

------------------------------------------------------------------------

## 1. Resumen ejecutivo

Oracle APEX es una plataforma viable para publicar aplicaciones públicas
en Internet, incluidas soluciones empresariales con usuarios
concurrentes, siempre que la infraestructura y los controles de
seguridad estén correctamente diseñados.

No debe evaluarse únicamente la confiabilidad del motor APEX. La
disponibilidad y seguridad de la solución completa dependen de todos sus
componentes:

-   Oracle APEX.
-   Oracle REST Data Services (ORDS).
-   Oracle Database.
-   Servidores de aplicación y proxy inverso.
-   Red, DNS y certificados TLS.
-   Seguridad perimetral.
-   Monitoreo, respaldos y recuperación.

**Conclusión:** no es necesario descartar APEX por ser una plataforma
Low Code. Es especialmente adecuado para aplicaciones centradas en
datos, formularios, procesos transaccionales, reportes, portales y
servicios REST. La decisión final debe basarse en los requisitos
funcionales, el volumen esperado, la criticidad y el presupuesto de
infraestructura.

## 2. Evaluación general

La siguiente valoración es cualitativa y no representa una garantía de
rendimiento. El resultado real depende del diseño y dimensionamiento de
la solución.

  Área                         Evaluación
  ---------------------------- ---------------------------------------------------
  Rendimiento                  Muy bueno con consultas y procesos optimizados
  Escalabilidad                Muy buena, condicionada por la infraestructura
  Seguridad                    Muy buena con configuración y controles adecuados
  Integración con APIs         Excelente
  Aplicaciones empresariales   Excelente
  Aplicaciones PWA             Buena
  Disponibilidad 24/7          Depende de la arquitectura y operación
  Alto tráfico                 Viable con pruebas y dimensionamiento

No existe un límite universal de usuarios concurrentes que pueda
garantizarse para todas las instalaciones. Influyen la capacidad de la
base de datos, ORDS, el pool de conexiones, la complejidad de las
consultas, los procesos PL/SQL y el patrón de uso.

## 3. Arquitectura recomendada

Para una aplicación pública de producción, se recomienda separar la
exposición a Internet de la base de datos y utilizar una arquitectura
por capas.

``` text
                    INTERNET
                       |
                Usuarios / PWA
                       |
                 WAF / Firewall
                       |
             Reverse Proxy / Balanceador
                       |
             +---------+---------+
             |                   |
           ORDS 1              ORDS 2
             |                   |
             +---------+---------+
                       |
                Oracle Database
                       |
             APEX Engine / PL/SQL
                       |
           Backups / Recuperación
```

### Componentes

1.  **WAF y protección perimetral**
    -   Filtrado de solicitudes maliciosas.
    -   Protección contra bots y ataques comunes.
    -   Reglas de limitación de solicitudes.
    -   Protección DDoS según el proveedor y el servicio contratado.
2.  **Reverse proxy o balanceador**
    -   Terminación HTTPS cuando corresponda.
    -   Distribución de tráfico entre instancias ORDS.
    -   Verificación de salud de los servidores.
    -   Conservación correcta del hostname y protocolo original.
3.  **ORDS**
    -   Publicación de APEX y servicios REST.
    -   Administración del pool de conexiones.
    -   Escalamiento horizontal mediante varias instancias cuando la
        arquitectura lo requiera.
4.  **Oracle Database**
    -   Almacenamiento de datos.
    -   Ejecución de PL/SQL y transacciones.
    -   Integridad y reglas de negocio.
    -   Auditoría y controles de acceso a datos.

**Regla esencial:** la base de datos no debe exponerse directamente a
Internet. Los usuarios deben acceder mediante los componentes de
aplicación y los servicios autorizados.

## 4. Seguridad

La seguridad debe tratarse como un requisito de diseño y no como una
actividad posterior a la publicación.

### 4.1 Controles recomendados

  -----------------------------------------------------------------------
  Control                             Recomendación
  ----------------------------------- -----------------------------------
  HTTPS                               Certificado TLS válido y renovación
                                      controlada

  Autenticación                       OAuth2, OpenID Connect o proveedor
                                      corporativo cuando corresponda

  Autorización                        Control por aplicación, página,
                                      proceso y operación

  Session State Protection            Habilitar y configurar
                                      correctamente

  SQL Injection                       Usar bind variables y consultas
                                      parametrizadas

  XSS                                 Aplicar escape adecuado a contenido
                                      dinámico

  CSRF                                Proteger formularios y operaciones
                                      sensibles

  Archivos                            Validar extensión, MIME, tamaño y
                                      contenido

  API REST                            Autenticar, autorizar y validar
                                      parámetros

  Auditoría                           Registrar accesos y operaciones
                                      relevantes

  Protección perimetral               WAF, rate limiting y mitigación de
                                      bots
  -----------------------------------------------------------------------

### 4.2 Aplicaciones anónimas

Que una aplicación permita acceso sin autenticación no significa que
todos sus procesos deban ser públicos.

Se debe revisar especialmente:

-   Formularios de registro.
-   Procesos AJAX.
-   Procesos PL/SQL públicos.
-   Servicios REST.
-   Carga y descarga de documentos e imágenes.
-   Consultas que puedan exponer información de otros usuarios.

No se debe confiar en un identificador enviado desde el navegador ---por
ejemplo, `P10_ID_CLIENTE`--- para decidir qué registros puede consultar
una persona. La autorización debe verificarse en el servidor y, cuando
sea apropiado, también en la base de datos.

### 4.3 Separación de funcionalidades

Una opción recomendable es separar las funcionalidades públicas de las
privadas. Por ejemplo:

-   Aplicación pública para consultas o solicitudes.
-   Aplicación privada para administración y operaciones internas.
-   APIs y reglas de negocio compartidas, con controles de autorización
    independientes.

## 5. Rendimiento y escalabilidad

APEX utiliza ORDS para atender las solicitudes y administrar conexiones
a la base de datos. Esto permite gestionar concurrencia sin mantener
necesariamente una conexión dedicada a Oracle Database durante toda la
sesión del usuario.

Sin embargo, una configuración incorrecta puede provocar saturación o
tiempos de respuesta elevados.

### 5.1 Base de datos

-   Dimensionar CPU, memoria y almacenamiento.
-   Crear índices según los patrones de consulta.
-   Evitar consultas que recorran grandes volúmenes sin filtros.
-   Revisar planes de ejecución.
-   Controlar procesos PL/SQL de larga duración.
-   Evitar bloqueos y transacciones prolongadas.
-   Medir consumo de CPU, I/O y sesiones.

### 5.2 ORDS

-   Dimensionar el pool de conexiones según la capacidad real de la base
    de datos.
-   Configurar adecuadamente la memoria de la JVM.
-   Establecer límites de solicitudes y tiempos de espera.
-   Monitorear conexiones activas, errores y latencia.
-   Evaluar varias instancias para escenarios de alta disponibilidad.

Aumentar indiscriminadamente el número de conexiones de ORDS no
garantiza mayor rendimiento. Si la base de datos está saturada, puede
empeorar la situación.

### 5.3 Aplicación APEX

-   Evitar regiones que consulten grandes volúmenes innecesariamente.
-   Aplicar paginación.
-   Optimizar Interactive Reports y Faceted Search.
-   Reducir el tamaño de imágenes y documentos.
-   Evitar procesos AJAX excesivamente frecuentes.
-   Revisar código JavaScript y PL/SQL ejecutado en cada solicitud.
-   Medir los tiempos de respuesta de las páginas críticas.

### 5.4 Pruebas de carga

Antes de publicar, realizar pruebas que simulen:

-   Usuarios concurrentes esperados.
-   Picos de tráfico.
-   Inicio y cierre de sesión.
-   Consultas y reportes pesados.
-   Operaciones transaccionales.
-   Carga de archivos.
-   Degradación o caída de una instancia ORDS.

Los resultados deben utilizarse para ajustar ORDS, la base de datos y la
aplicación.

## 6. Disponibilidad y continuidad operativa

Una aplicación pública debe tener un plan para fallos de
infraestructura, errores de despliegue y pérdida de datos.

  Elemento        Recomendación
  --------------- -------------------------------------------
  Base de datos   Alta disponibilidad según criticidad
  ORDS            Instancias redundantes cuando se requiera
  Balanceador     Distribución y detección de fallos
  Backups         Automáticos, protegidos y cifrados
  Recuperación    Procedimiento de restauración probado
  Monitoreo       CPU, RAM, conexiones, errores y latencia
  Logs            Centralizados y con retención definida
  Alertas         Caídas, saturación y errores críticos

### 6.1 RPO y RTO

Definir dos objetivos operativos:

-   **RPO (Recovery Point Objective):** cantidad máxima de información
    que se acepta perder, expresada como tiempo.
-   **RTO (Recovery Time Objective):** tiempo máximo aceptable para
    recuperar el servicio.

Ejemplo ilustrativo para una aplicación crítica:

-   RPO objetivo: 15 minutos.
-   RTO objetivo: 1 hora.

Estos objetivos solo deben establecerse si la infraestructura, las
licencias, la configuración y los procedimientos pueden cumplirlos. No
basta con disponer de backups: es indispensable probar periódicamente la
restauración.

## 7. Ambientes y despliegues

No se recomienda desarrollar directamente en el ambiente productivo.

Como mínimo, separar:

### DEV --- Desarrollo

-   Construcción de páginas y componentes.
-   Cambios de PL/SQL, JavaScript y CSS.
-   Pruebas unitarias.
-   Integración inicial.

### QA / TEST --- Pruebas

-   Pruebas funcionales.
-   Pruebas de seguridad.
-   Pruebas de carga.
-   Validación de integraciones.
-   Aceptación de usuarios.

### PROD --- Producción

-   Aplicación publicada.
-   Acceso administrativo restringido.
-   Monitoreo y auditoría.
-   Cambios controlados.
-   Plan de rollback.

Para aplicaciones críticas, evaluar instancias o servicios
independientes. También puede considerarse Oracle APEX Runtime en
producción para reducir la exposición de herramientas de desarrollo,
como App Builder y SQL Workshop, según el modelo de despliegue y
licenciamiento aplicable.

Mantener APEX y ORDS en versiones soportadas y coordinar las
actualizaciones. Antes de cada actualización, revisar la matriz de
compatibilidad, requisitos, notas de versión y procedimientos de
respaldo y reversión.

## 8. Casos de uso adecuados

  -----------------------------------------------------------------------
  Tipo de aplicación                  Evaluación
  ----------------------------------- -----------------------------------
  Portales informativos               Excelente

  Formularios públicos                Excelente

  Portales de clientes                Muy recomendable

  Sistemas de citas                   Muy recomendable

  Aplicaciones de seguimiento         Muy recomendable

  PWA empresariales                   Recomendable

  Sistemas financieros                Viable con controles estrictos

  Tiempo real intensivo               Evaluar arquitectura complementaria

  Procesamiento multimedia intensivo  Evaluar servicios especializados
  -----------------------------------------------------------------------

APEX resulta especialmente conveniente cuando el negocio depende de
datos relacionales, transacciones, procedimientos almacenados,
formularios y reportes.

No es necesario resolver todas las capacidades dentro de APEX. Para
funcionalidades especializadas, se pueden integrar servicios externos
mediante APIs.

## 9. Distribución tecnológica propuesta

Para una aplicación empresarial basada en Oracle:

  Capa                       Tecnología / responsabilidad
  -------------------------- --------------------------------------
  Interfaz                   Oracle APEX, componentes web y PWA
  Reglas de negocio          PL/SQL y paquetes de base de datos
  Servicios                  ORDS y APIs REST
  Persistencia               Oracle Database
  Seguridad perimetral       WAF y firewall
  Publicación                Reverse proxy o balanceador
  Servicios especializados   Sistemas externos integrados por API
  Operación                  Monitoreo, logs, alertas y backups

Esta distribución aprovecha las capacidades de Oracle y mantiene la
posibilidad de incorporar servicios externos cuando las necesidades del
negocio lo justifiquen.

## 10. Checklist previo a producción

-   [ ] Dominio propio y certificado SSL/TLS válido.
-   [ ] WAF y protección contra tráfico automatizado.
-   [ ] ORDS detrás de reverse proxy o balanceador.
-   [ ] Base de datos sin exposición directa a Internet.
-   [ ] Entorno de producción endurecido y herramientas administrativas
    restringidas.
-   [ ] Autenticación y autorización correctamente configuradas.
-   [ ] Session State Protection habilitado y probado.
-   [ ] Revisión de SQL Injection y XSS.
-   [ ] Validación de procesos AJAX y servicios REST.
-   [ ] Control de carga y descarga de archivos.
-   [ ] Pruebas de concurrencia y rendimiento.
-   [ ] Pruebas de vulnerabilidades y penetración.
-   [ ] Backups protegidos y restauración comprobada.
-   [ ] Monitoreo y alertas operativas.
-   [ ] Ambientes independientes DEV, QA y PROD.
-   [ ] Procedimiento de rollback de despliegues.

## 11. Conclusión y recomendación

Oracle APEX puede utilizarse como plataforma principal para publicar
aplicaciones empresariales en Internet. No es necesario cambiar de
tecnología únicamente porque la aplicación tendrá acceso público.

La recomendación es conservar APEX como capa de presentación y utilizar
una arquitectura de producción con responsabilidades claramente
separadas:

-   **Oracle APEX:** interfaz, formularios, reportes y experiencia PWA.
-   **PL/SQL:** reglas de negocio y transacciones.
-   **ORDS:** publicación y administración de servicios REST.
-   **Oracle Database:** persistencia, integridad y controles de datos.
-   **WAF:** protección perimetral.
-   **Servicios externos:** notificaciones, procesamiento de archivos y
    capacidades especializadas.

La facilidad de desarrollo de APEX no elimina la complejidad operativa.
La seguridad, el rendimiento y la disponibilidad deben diseñarse,
probarse y monitorearse como en cualquier aplicación empresarial.

## 12. Información necesaria para diseñar la arquitectura definitiva

Para dimensionar una solución concreta se deben confirmar tres aspectos.

### 12.1 Tipo de aplicación

-   Portal público sin inicio de sesión.
-   Portal para clientes con autenticación.
-   Aplicación empresarial con usuarios y roles.
-   Aplicación PWA para dispositivos móviles.
-   Sistema transaccional con información confidencial.

### 12.2 Alojamiento

-   Oracle Cloud Infrastructure (OCI).
-   Oracle APEX Cloud / Autonomous Database.
-   Servidor propio (On-Premise).
-   VPS o servidor de terceros.

### 12.3 Usuarios concurrentes estimados

-   Menos de 100.
-   Entre 100 y 500.
-   Entre 500 y 2.000.
-   Más de 2.000.

Con estas respuestas se podrá definir la arquitectura de producción,
infraestructura, seguridad, configuración ORDS, certificados SSL/TLS,
escalabilidad, alta disponibilidad y estimación de costos.

------------------------------------------------------------------------

## Referencias oficiales para validación

Antes de implementar, consultar la documentación oficial vigente y las
notas de versión correspondientes a la versión instalada:

-   Oracle APEX Documentation:
    https://docs.oracle.com/en/database/oracle/apex/
-   Oracle REST Data Services Documentation:
    https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/
-   Oracle APEX Security:
    https://docs.oracle.com/en/database/oracle/apex/
-   Oracle Database Backup and Recovery:
    https://docs.oracle.com/en/database/oracle/oracle-database/

**Nota:** las valoraciones de este informe son orientativas. La
arquitectura final, los niveles de servicio y la capacidad deben
validarse mediante análisis de requisitos, revisión de seguridad y
pruebas en la infraestructura objetivo.

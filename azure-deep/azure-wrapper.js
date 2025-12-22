/**
 * Cliente para Azure DevOps API
 * Proporciona métodos para interactuar con Azure DevOps de manera segura y eficiente
 */

class AzureDevOpsClient {
    constructor(settings) {
        this.settings = settings;
        this.baseHeaders = {
            'Content-Type': 'application/json',
            'Authorization': 'Basic ' + btoa(`${settings.username}:${settings.pat}`)
        };
    }

    /**
     * Construye una URL completa para la API de Azure DevOps
     * @param {string} endpoint - Endpoint de la API
     * @param {Object} params - Parámetros de consulta
     * @returns {string} URL completa
     */
    buildUrl(endpoint, params = {}) {
        // Construir URL base
        let url = `${this.settings.baseUrl}`;
        
        // Agregar proyecto si está en la configuración
        if (this.settings.project) {
            url += `/${this.settings.project}`;
            
            // Agregar equipo si está en la configuración
            if (this.settings.team && !endpoint.includes('/_apis/')) {
                url += `/${this.settings.team}`;
            }
        }
        
        // Agregar endpoint
        url += `/${endpoint}`;
        
        // Agregar parámetros de consulta
        const queryParams = new URLSearchParams();
        
        // Agregar versión de API si no está ya incluida
        if (!endpoint.includes('api-version') && !params['api-version']) {
            queryParams.append('api-version', this.settings.apiVersion);
        }
        
        // Agregar otros parámetros
        Object.keys(params).forEach(key => {
            if (params[key] !== undefined && params[key] !== null) {
                queryParams.append(key, params[key]);
            }
        });
        
        const queryString = queryParams.toString();
        if (queryString) {
            url += endpoint.includes('?') ? '&' + queryString : '?' + queryString;
        }
        
        return url;
    }

    /**
     * Ejecuta una solicitud a la API de Azure DevOps
     * @param {string} endpoint - Endpoint de la API
     * @param {string} method - Método HTTP (GET, POST, etc.)
     * @param {Object} data - Datos para enviar en el cuerpo
     * @param {Object} params - Parámetros de consulta
     * @returns {Promise<Object>} Respuesta de la API
     */
    async request(endpoint, method = 'GET', data = null, params = {}) {
        const url = this.buildUrl(endpoint, params);
        
        const options = {
            method: method,
            headers: this.baseHeaders,
            mode: 'cors'
        };
        
        if (data && (method === 'POST' || method === 'PATCH' || method === 'PUT')) {
            options.body = JSON.stringify(data);
        }
        
        try {
            const response = await fetch(url, options);
            
            // Manejar respuestas no exitosas
            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`Azure DevOps API Error ${response.status}: ${response.statusText} - ${errorText}`);
            }
            
            // Para respuestas sin contenido (204 No Content)
            if (response.status === 204) {
                return { success: true };
            }
            
            // Parsear respuesta JSON
            return await response.json();
        } catch (error) {
            console.error('Error en la solicitud a Azure DevOps:', error);
            throw error;
        }
    }

    /**
     * Obtiene un work item por ID
     * @param {number} id - ID del work item
     * @param {string} expand - Nivel de expansión (none, relations, fields, all, links)
     * @returns {Promise<Object>} Work item
     */
    async getWorkItem(id, expand = 'all') {
        return await this.request(
            `_apis/wit/workitems/${id}`,
            'GET',
            null,
            { '$expand': expand }
        );
    }

    /**
     * Obtiene múltiples work items por IDs
     * @param {Array<number>} ids - IDs de los work items
     * @param {string} expand - Nivel de expansión
     * @param {Array<string>} fields - Campos a incluir
     * @returns {Promise<Object>} Lista de work items
     */
    async getWorkItems(ids, expand = 'none', fields = []) {
        const params = {
            ids: ids.join(','),
            '$expand': expand
        };
        
        if (fields.length > 0) {
            params.fields = fields.join(',');
        }
        
        return await this.request('_apis/wit/workitems', 'GET', null, params);
    }

    /**
     * Ejecuta una consulta WIQL (Work Item Query Language)
     * @param {string} wiql - Consulta WIQL
     * @returns {Promise<Object>} Resultados de la consulta
     */
    async executeWiql(wiql) {
        return await this.request('_apis/wit/wiql', 'POST', { query: wiql });
    }

    /**
     * Obtiene work items por tipo
     * @param {string} workItemType - Tipo de work item
     * @param {number} top - Número máximo de resultados
     * @returns {Promise<Array>} Lista de work items
     */
    async getWorkItemsByType(workItemType, top = 100) {
        const wiql = `SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo], [System.CreatedDate] 
                     FROM WorkItems 
                     WHERE [System.TeamProject] = '${this.settings.project}' 
                     AND [System.WorkItemType] = '${workItemType}' 
                     ORDER BY [System.CreatedDate] DESC`;
        
        const result = await this.executeWiql(wiql);
        
        if (!result.workItems || result.workItems.length === 0) {
            return [];
        }
        
        // Obtener detalles de los work items
        const ids = result.workItems.slice(0, top).map(item => item.id);
        const details = await this.getWorkItems(ids, 'relations');
        
        return details.value || [];
    }

    /**
     * Obtiene el trabajo de un sprint
     * @param {string} iterationPath - Ruta de la iteración (sprint)
     * @param {Array<string>} workItemTypes - Tipos de work items a incluir
     * @param {Array<string>} states - Estados a incluir
     * @returns {Promise<Array>} Lista de work items del sprint
     */
    async getSprintWork(iterationPath, workItemTypes = ['Task', 'Issue', 'Bug'], states = ['To Do', 'In Progress', 'Done']) {
        const typeConditions = workItemTypes.map(type => `[System.WorkItemType] = '${type}'`).join(' OR ');
        const stateConditions = states.map(state => `[System.State] = '${state}'`).join(' OR ');
        
        const wiql = `SELECT [System.Id], [System.Title], [System.WorkItemType], [System.State], [System.AssignedTo] 
                     FROM WorkItems 
                     WHERE [System.TeamProject] = '${this.settings.project}' 
                     AND ([System.IterationPath] UNDER '${iterationPath}')
                     AND (${typeConditions})
                     AND (${stateConditions})
                     ORDER BY [System.State], [System.AssignedTo]`;
        
        const result = await this.executeWiql(wiql);
        
        if (!result.workItems || result.workItems.length === 0) {
            return [];
        }
        
        // Obtener detalles de los work items
        const ids = result.workItems.map(item => item.id);
        const details = await this.getWorkItems(ids);
        
        return details.value || [];
    }

    /**
     * Obtiene work items asignados a un usuario
     * @param {string} user - Usuario (email o display name)
     * @param {Array<string>} states - Estados a incluir
     * @returns {Promise<Array>} Lista de work items asignados
     */
    async getWorkItemsByAssignedUser(user, states = ['To Do', 'In Progress']) {
        const stateConditions = states.map(state => `[System.State] = '${state}'`).join(' OR ');
        
        const wiql = `SELECT [System.Id], [System.Title], [System.WorkItemType], [System.State], [System.CreatedDate] 
                     FROM WorkItems 
                     WHERE [System.TeamProject] = '${this.settings.project}' 
                     AND [System.AssignedTo] = '${user}'
                     AND (${stateConditions})
                     ORDER BY [System.CreatedDate] DESC`;
        
        const result = await this.executeWiql(wiql);
        
        if (!result.workItems || result.workItems.length === 0) {
            return [];
        }
        
        // Obtener detalles de los work items
        const ids = result.workItems.map(item => item.id);
        const details = await this.getWorkItems(ids);
        
        return details.value || [];
    }

    /**
     * Obtiene work items recientes (creados o modificados en los últimos días)
     * @param {number} days - Número de días hacia atrás
     * @returns {Promise<Array>} Lista de work items recientes
     */
    async getRecentWorkItems(days = 7) {
        const limitDate = new Date();
        limitDate.setDate(limitDate.getDate() - days);
        const formattedDate = limitDate.toISOString().split('T')[0];
        
        const wiql = `SELECT [System.Id], [System.Title], [System.WorkItemType], [System.State], [System.AssignedTo], [System.CreatedDate], [System.ChangedDate] 
                     FROM WorkItems 
                     WHERE [System.TeamProject] = '${this.settings.project}' 
                     AND ([System.CreatedDate] >= '${formattedDate}' OR [System.ChangedDate] >= '${formattedDate}')
                     ORDER BY [System.ChangedDate] DESC`;
        
        const result = await this.executeWiql(wiql);
        
        if (!result.workItems || result.workItems.length === 0) {
            return [];
        }
        
        // Obtener detalles de los work items (limitado a 100)
        const ids = result.workItems.slice(0, 100).map(item => item.id);
        const details = await this.getWorkItems(ids);
        
        return details.value || [];
    }

    /**
     * Obtiene información del proyecto
     * @returns {Promise<Object>} Información del proyecto
     */
    async getProjectInfo() {
        return await this.request(`_apis/projects/${this.settings.project}`);
    }

    /**
     * Obtiene las iteraciones (sprints) del equipo
     * @returns {Promise<Array>} Lista de iteraciones
     */
    async getTeamIterations() {
        if (!this.settings.team) {
            throw new Error('El equipo no está configurado');
        }
        
        return await this.request(`_apis/work/teamsettings/iterations`);
    }
}

// Exportar la clase
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AzureDevOpsClient;
}
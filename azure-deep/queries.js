/**
 * Consultas predefinidas para Azure DevOps
 * Proporciona plantillas de consultas comunes para el sistema
 */

const PREDEFINED_QUERIES = {
    // Consultas de work items
    workItemDetails: {
        name: 'Detalles de Work Item',
        description: 'Obtiene todos los detalles de un work item específico',
        category: 'Work Items',
        icon: 'fa-info-circle',
        endpoint: '_apis/wit/workitems/{id}',
        method: 'GET',
        params: {
            id: {
                type: 'number',
                required: true,
                label: 'ID del Work Item',
                placeholder: '12345'
            },
            expand: {
                type: 'select',
                required: false,
                label: 'Nivel de expansión',
                options: [
                    { value: 'none', label: 'Ninguno' },
                    { value: 'relations', label: 'Relaciones' },
                    { value: 'fields', label: 'Campos' },
                    { value: 'all', label: 'Todo' },
                    { value: 'links', label: 'Enlaces' }
                ],
                default: 'all'
            }
        }
    },

    workItemsByType: {
        name: 'Work Items por Tipo',
        description: 'Obtiene work items filtrados por tipo',
        category: 'Work Items',
        icon: 'fa-filter',
        endpoint: '_apis/wit/wiql',
        method: 'POST',
        params: {
            workItemType: {
                type: 'select',
                required: true,
                label: 'Tipo de Work Item',
                options: [
                    { value: 'Iniciativa', label: 'Iniciativa' },
                    { value: 'Epica', label: 'Épica' },
                    { value: 'Feature', label: 'Feature' },
                    { value: 'Product Backlog Item', label: 'Product Backlog Item' },
                    { value: 'Task', label: 'Task' },
                    { value: 'Issue', label: 'Issue' },
                    { value: 'Bug', label: 'Bug' },
                    { value: 'User Story', label: 'User Story' }
                ],
                default: 'Task'
            },
            maxResults: {
                type: 'number',
                required: false,
                label: 'Máximo de resultados',
                placeholder: '100',
                default: 100,
                min: 1,
                max: 1000
            },
            states: {
                type: 'multiselect',
                required: false,
                label: 'Estados',
                options: [
                    { value: 'New', label: 'New' },
                    { value: 'Active', label: 'Active' },
                    { value: 'Resolved', label: 'Resolved' },
                    { value: 'Closed', label: 'Closed' },
                    { value: 'Removed', label: 'Removed' },
                    { value: 'To Do', label: 'To Do' },
                    { value: 'In Progress', label: 'In Progress' },
                    { value: 'Done', label: 'Done' }
                ],
                default: ['To Do', 'In Progress', 'Done']
            }
        },
        buildBody: function(params, projectName) {
            const stateConditions = params.states && params.states.length > 0 
                ? params.states.map(state => `[System.State] = '${state}'`).join(' OR ')
                : '1=1';
            
            return {
                query: `SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo], [System.CreatedDate] 
                       FROM WorkItems 
                       WHERE [System.TeamProject] = '${projectName}' 
                       AND [System.WorkItemType] = '${params.workItemType}'
                       AND (${stateConditions})
                       ORDER BY [System.CreatedDate] DESC`
            };
        }
    },

    sprintWorkItems: {
        name: 'Trabajo del Sprint',
        description: 'Obtiene todos los work items de un sprint específico',
        category: 'Sprints',
        icon: 'fa-running',
        endpoint: '_apis/wit/wiql',
        method: 'POST',
        params: {
            sprintPath: {
                type: 'text',
                required: true,
                label: 'Ruta del Sprint',
                placeholder: 'Iteration\\Sprint 1',
                help: 'Ejemplo: "Iteration\\Sprint 1" o "Sprint 1"'
            },
            workItemTypes: {
                type: 'multiselect',
                required: false,
                label: 'Tipos de Work Items',
                options: [
                    { value: 'Task', label: 'Task' },
                    { value: 'Issue', label: 'Issue' },
                    { value: 'Bug', label: 'Bug' },
                    { value: 'Product Backlog Item', label: 'Product Backlog Item' },
                    { value: 'User Story', label: 'User Story' }
                ],
                default: ['Task', 'Issue', 'Bug']
            },
            states: {
                type: 'multiselect',
                required: false,
                label: 'Estados',
                options: [
                    { value: 'To Do', label: 'To Do' },
                    { value: 'In Progress', label: 'In Progress' },
                    { value: 'Done', label: 'Done' },
                    { value: 'New', label: 'New' },
                    { value: 'Active', label: 'Active' },
                    { value: 'Resolved', label: 'Resolved' },
                    { value: 'Closed', label: 'Closed' }
                ],
                default: ['To Do', 'In Progress', 'Done']
            },
            fields: {
                type: 'text',
                required: false,
                label: 'Campos a incluir',
                placeholder: 'System.Id,System.Title,System.State,System.AssignedTo',
                default: 'System.Id,System.Title,System.State,System.AssignedTo,System.WorkItemType',
                help: 'Separar campos por coma'
            }
        },
        buildBody: function(params, projectName) {
            const typeConditions = params.workItemTypes && params.workItemTypes.length > 0
                ? params.workItemTypes.map(type => `[System.WorkItemType] = '${type}'`).join(' OR ')
                : '1=1';
            
            const stateConditions = params.states && params.states.length > 0
                ? params.states.map(state => `[System.State] = '${state}'`).join(' OR ')
                : '1=1';
            
            const fields = params.fields || 'System.Id,System.Title,System.State,System.AssignedTo,System.WorkItemType';
            
            return {
                query: `SELECT ${fields} 
                       FROM WorkItems 
                       WHERE [System.TeamProject] = '${projectName}' 
                       AND ([System.IterationPath] UNDER '${params.sprintPath}')
                       AND (${typeConditions})
                       AND (${stateConditions})
                       ORDER BY [System.State], [System.AssignedTo]`
            };
        }
    },

    userAssignedWork: {
        name: 'Tareas Asignadas por Usuario',
        description: 'Obtiene work items asignados a usuarios específicos',
        category: 'Usuarios',
        icon: 'fa-user-friends',
        endpoint: '_apis/wit/wiql',
        method: 'POST',
        params: {
            users: {
                type: 'text',
                required: true,
                label: 'Usuarios (separados por coma)',
                placeholder: 'usuario1@ejemplo.com, usuario2@ejemplo.com',
                help: 'Puede ser email o display name'
            },
            timeRange: {
                type: 'select',
                required: false,
                label: 'Rango de tiempo',
                options: [
                    { value: '7', label: 'Última semana' },
                    { value: '30', label: 'Último mes' },
                    { value: '90', label: 'Último trimestre' },
                    { value: '365', label: 'Último año' },
                    { value: '0', label: 'Todo el tiempo' }
                ],
                default: '30'
            },
            workItemTypes: {
                type: 'multiselect',
                required: false,
                label: 'Tipos de Work Items',
                options: [
                    { value: 'Task', label: 'Task' },
                    { value: 'Issue', label: 'Issue' },
                    { value: 'Bug', label: 'Bug' },
                    { value: 'Product Backlog Item', label: 'Product Backlog Item' }
                ],
                default: ['Task', 'Issue', 'Bug']
            },
            states: {
                type: 'multiselect',
                required: false,
                label: 'Estados',
                options: [
                    { value: 'To Do', label: 'To Do' },
                    { value: 'In Progress', label: 'In Progress' },
                    { value: 'Done', label: 'Done' }
                ],
                default: ['To Do', 'In Progress']
            }
        },
        buildBody: function(params, projectName) {
            const users = params.users.split(',').map(u => u.trim());
            const userConditions = users.map(user => `[System.AssignedTo] = '${user}'`).join(' OR ');
            
            const typeConditions = params.workItemTypes && params.workItemTypes.length > 0
                ? params.workItemTypes.map(type => `[System.WorkItemType] = '${type}'`).join(' OR ')
                : '1=1';
            
            const stateConditions = params.states && params.states.length > 0
                ? params.states.map(state => `[System.State] = '${state}'`).join(' OR ')
                : '1=1';
            
            let dateCondition = '';
            if (params.timeRange && params.timeRange !== '0') {
                const days = parseInt(params.timeRange);
                const limitDate = new Date();
                limitDate.setDate(limitDate.getDate() - days);
                const formattedDate = limitDate.toISOString().split('T')[0];
                dateCondition = ` AND ([System.CreatedDate] >= '${formattedDate}' OR [System.ChangedDate] >= '${formattedDate}')`;
            }
            
            return {
                query: `SELECT [System.Id], [System.Title], [System.WorkItemType], [System.State], [System.AssignedTo], [System.CreatedDate], [System.ChangedDate] 
                       FROM WorkItems 
                       WHERE [System.TeamProject] = '${projectName}' 
                       AND (${userConditions})
                       AND (${typeConditions})
                       AND (${stateConditions})${dateCondition}
                       ORDER BY [System.AssignedTo], [System.State], [System.ChangedDate] DESC`
            };
        }
    },

    recentActivity: {
        name: 'Actividad Reciente',
        description: 'Work items creados o modificados recientemente',
        category: 'Monitoreo',
        icon: 'fa-history',
        endpoint: '_apis/wit/wiql',
        method: 'POST',
        params: {
            days: {
                type: 'number',
                required: true,
                label: 'Días hacia atrás',
                placeholder: '7',
                default: 7,
                min: 1,
                max: 365
            },
            workItemTypes: {
                type: 'multiselect',
                required: false,
                label: 'Tipos de Work Items',
                options: [
                    { value: 'Task', label: 'Task' },
                    { value: 'Issue', label: 'Issue' },
                    { value: 'Bug', label: 'Bug' },
                    { value: 'Product Backlog Item', label: 'Product Backlog Item' },
                    { value: 'Feature', label: 'Feature' },
                    { value: 'Epica', label: 'Épica' },
                    { value: 'Iniciativa', label: 'Iniciativa' }
                ],
                default: ['Task', 'Issue', 'Bug', 'Product Backlog Item']
            }
        },
        buildBody: function(params, projectName) {
            const limitDate = new Date();
            limitDate.setDate(limitDate.getDate() - params.days);
            const formattedDate = limitDate.toISOString().split('T')[0];
            
            const typeConditions = params.workItemTypes && params.workItemTypes.length > 0
                ? params.workItemTypes.map(type => `[System.WorkItemType] = '${type}'`).join(' OR ')
                : '1=1';
            
            return {
                query: `SELECT [System.Id], [System.Title], [System.WorkItemType], [System.State], [System.AssignedTo], [System.CreatedDate], [System.ChangedDate] 
                       FROM WorkItems 
                       WHERE [System.TeamProject] = '${projectName}' 
                       AND ([System.CreatedDate] >= '${formattedDate}' OR [System.ChangedDate] >= '${formattedDate}')
                       AND (${typeConditions})
                       ORDER BY [System.ChangedDate] DESC`
            };
        }
    },

    workItemsByTag: {
        name: 'Work Items por Etiqueta',
        description: 'Obtiene work items filtrados por etiqueta',
        category: 'Work Items',
        icon: 'fa-tag',
        endpoint: '_apis/wit/wiql',
        method: 'POST',
        params: {
            tag: {
                type: 'text',
                required: true,
                label: 'Etiqueta',
                placeholder: 'urgente, bloqueado, etc.'
            },
            maxResults: {
                type: 'number',
                required: false,
                label: 'Máximo de resultados',
                placeholder: '50',
                default: 50,
                min: 1,
                max: 200
            }
        },
        buildBody: function(params, projectName) {
            return {
                query: `SELECT [System.Id], [System.Title], [System.WorkItemType], [System.State], [System.AssignedTo], [System.Tags] 
                       FROM WorkItems 
                       WHERE [System.TeamProject] = '${projectName}' 
                       AND [System.Tags] CONTAINS '${params.tag}' 
                       ORDER BY [System.CreatedDate] DESC`
            };
        }
    }
};

// Categorías de consultas
const QUERY_CATEGORIES = [
    { id: 'work-items', name: 'Work Items', icon: 'fa-tasks' },
    { id: 'sprints', name: 'Sprints', icon: 'fa-running' },
    { id: 'users', name: 'Usuarios', icon: 'fa-users' },
    { id: 'monitoring', name: 'Monitoreo', icon: 'fa-chart-line' }
];

// Función para obtener consultas por categoría
function getQueriesByCategory(categoryId) {
    return Object.entries(PREDEFINED_QUERIES)
        .filter(([key, query]) => query.category.toLowerCase() === categoryId.toLowerCase())
        .reduce((obj, [key, value]) => {
            obj[key] = value;
            return obj;
        }, {});
}

// Función para obtener todas las consultas
function getAllQueries() {
    return PREDEFINED_QUERIES;
}

// Función para obtener una consulta por nombre
function getQueryByName(name) {
    return Object.values(PREDEFINED_QUERIES).find(query => query.name === name);
}

// Función para obtener una consulta por ID
function getQueryById(id) {
    return PREDEFINED_QUERIES[id];
}

// Exportar funciones y constantes
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        PREDEFINED_QUERIES,
        QUERY_CATEGORIES,
        getQueriesByCategory,
        getAllQueries,
        getQueryByName,
        getQueryById
    };
}
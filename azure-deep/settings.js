// Configuración por defecto del sistema
const DEFAULT_SETTINGS = {
    baseUrl: 'https://dev.azure.com/{organization}',
    username: '',
    pat: '',
    project: '',
    team: '',
    apiVersion: '7.1',
    
    // Configuración de consultas predefinidas
    predefinedQueries: {
        workItemDetails: {
            name: 'Detalles de Work Item',
            description: 'Obtiene todos los detalles de un work item específico',
            endpoint: '_apis/wit/workitems/{id}?$expand=all',
            method: 'GET'
        },
        workItemsByType: {
            name: 'Work Items por Tipo',
            description: 'Obtiene work items filtrados por tipo',
            endpoint: '_apis/wit/wiql',
            method: 'POST',
            bodyTemplate: {
                query: "SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo] FROM WorkItems WHERE [System.TeamProject] = '{project}' AND [System.WorkItemType] = '{type}'"
            }
        },
        sprintWork: {
            name: 'Trabajo del Sprint',
            description: 'Obtiene todos los work items de un sprint específico',
            endpoint: '_apis/wit/wiql',
            method: 'POST',
            bodyTemplate: {
                query: "SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo] FROM WorkItems WHERE [System.TeamProject] = '{project}' AND [System.IterationPath] UNDER '{sprint}'"
            }
        }
    },
    
    // Tipos de work items comunes en Azure DevOps
    workItemTypes: [
        'Iniciativa',
        'Epica', 
        'Feature',
        'Product Backlog Item',
        'Task',
        'Issue',
        'Bug',
        'User Story',
        'Test Case'
    ],
    
    // Estados comunes de work items
    workItemStates: [
        'New',
        'Active',
        'Resolved',
        'Closed',
        'Removed',
        'To Do',
        'In Progress',
        'Done'
    ]
};

// Función para cargar configuración desde localStorage
function loadSettings() {
    const settings = { ...DEFAULT_SETTINGS };
    
    // Cargar configuración del usuario si existe
    try {
        const savedSettings = localStorage.getItem('azureDevOpsSettings');
        if (savedSettings) {
            const userSettings = JSON.parse(savedSettings);
            Object.assign(settings, userSettings);
        }
    } catch (error) {
        console.error('Error al cargar configuración:', error);
    }
    
    return settings;
}

// Función para guardar configuración en localStorage
function saveSettings(settings) {
    try {
        // No guardar toda la configuración por defecto, solo la del usuario
        const userSettings = {
            baseUrl: settings.baseUrl,
            username: settings.username,
            pat: settings.pat,
            project: settings.project,
            team: settings.team,
            apiVersion: settings.apiVersion
        };
        
        localStorage.setItem('azureDevOpsSettings', JSON.stringify(userSettings));
        return true;
    } catch (error) {
        console.error('Error al guardar configuración:', error);
        return false;
    }
}

// Función para validar configuración
function validateSettings(settings) {
    const errors = [];
    
    if (!settings.baseUrl || settings.baseUrl.includes('{organization}')) {
        errors.push('La URL base debe contener una organización válida');
    }
    
    if (!settings.username) {
        errors.push('El nombre de usuario es requerido');
    }
    
    if (!settings.pat) {
        errors.push('El Personal Access Token es requerido');
    }
    
    if (!settings.project) {
        errors.push('El nombre del proyecto es requerido');
    }
    
    if (!settings.apiVersion) {
        errors.push('La versión de API es requerida');
    }
    
    return {
        isValid: errors.length === 0,
        errors: errors
    };
}

// Exportar funciones y configuración
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        DEFAULT_SETTINGS,
        loadSettings,
        saveSettings,
        validateSettings
    };
}
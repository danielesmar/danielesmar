    const AzureDevOpsAPI = {
    async fetchGeneric(endpoint, method = 'GET', body = null) {
        const auth = btoa(`${settings.user}:${settings.pat}`);
        const url = `${settings.baseUrl}/${settings.organization}/${settings.project}/_apis/${endpoint}`;
        
        const options = {
            method: method,
            headers: {
                'Authorization': `Basic ${auth}`,
                'Content-Type': 'application/json'
            }
        };

        if (body) {
            options.body = JSON.stringify(body);
        }

        const response = await fetch(url, options);
        if (!response.ok) throw new Error(`Error: ${response.statusText}`);
        return await response.json();
    },

    // Consulta de un Work Item específico por ID
    async getWorkItem(id) {
        return await this.fetchGeneric(`wit/workitems/${id}?api-version=7.0`);
    },

    // Consulta del Working (Work Items) de un Sprint/Iteración
    async getSprintItems(teamName, iterationPath) {
        const wiql = {
            query: `SELECT [System.Id], [System.Title], [System.State] 
                    FROM WorkItems 
                    WHERE [System.IterationPath] = '${iterationPath}'`
        };
        return await this.fetchGeneric(`${teamName}/_apis/wit/wiql?api-version=7.0`, 'POST', wiql);
    }
};
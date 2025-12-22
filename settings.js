const settings = {
    baseUrl: "https://dev.azure.com/{tu_organizacion}",
    organization: "{tu_organizacion}",
    project: "{tu_proyecto}",
    // El PAT se enviará como Basic Auth (usuario:PAT codificado en Base64)
    pat: "TU_PERSONAL_ACCESS_TOKEN_AQUI",
    user: "" // Puede quedar vacío si usas un PAT
};
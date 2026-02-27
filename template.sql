Aquí tienes la arquitectura para esta funcionalidad:

1. El Atributo configJSON
En el Page Designer, el usuario configurará algo como esto en el atributo del plugin:

JSON
{
  "titleField": "NAME",
  "subtitleField": "CATEGORIA",
  "fields": [
    {"label": "Precio", "field": "PRECIO", "prefix": "$"},
    {"label": "Estado", "field": "STATUS_DS"}
  ],
  "buttons": [
    {"label": "Ver Detalle", "url": "f?p=&APP_ID.:2:&SESSION.:::2:P2_ID:", "urlField": "ID"}
  ]
}
2. Función AJAX Dinámica (PL/SQL)
Esta función ya no busca "ID" o "LAT" específicamente; recorre todas las columnas disponibles en el contexto y crea un objeto JSON donde las llaves son los nombres de las columnas.

SQL
function ajax_mapa (
    p_region in apex_plugin.t_region,
    p_plugin in apex_plugin.t_plugin )
    return apex_plugin.t_region_ajax_result
is
    l_context      apex_exec.t_context;
    l_col_count    pls_integer;
    l_col_info     apex_exec.t_column;
    l_return       apex_plugin.t_region_ajax_result;
begin
    l_context := apex_exec.open_query_context(
        p_location  => apex_exec.c_location_local_db,
        p_sql_query => p_region.source
    );

    l_col_count := apex_exec.get_column_count(l_context);

    apex_json.open_object;
    apex_json.open_array('data');

    while apex_exec.next_row(l_context) loop
        apex_json.open_object;
        for i in 1 .. l_col_count loop
            l_col_info := apex_exec.get_column_info(l_context, i);
            
            -- Escribimos dinámicamente cada columna según su tipo
            case l_col_info.data_type
                when apex_exec.c_datatype_number then
                    apex_json.write(l_col_info.name, apex_exec.get_number(l_context, i));
                else
                    apex_json.write(l_col_info.name, apex_exec.get_varchar2(l_context, i));
            end case;
        end loop;
        apex_json.close_object;
    end loop;

    apex_json.close_array;
    -- Pasamos también la configuración para que el JS sepa qué hacer
    apex_json.write('config', p_region.attribute_01); 
    apex_json.close_object;

    apex_exec.close(l_context);
    return l_return;
exception when others then
    apex_exec.close(l_context); raise;
end;
3. El Renderizado del Popup (JavaScript)
Ahora en el JS, creamos una función "Template Engine" que procesa la configuración contra los datos de cada fila.

JavaScript
function initGenericMap(regionId, ajaxId) {
    apex.server.plugin(ajaxId, {}, {
        success: function(response) {
            const config = JSON.parse(response.config);
            const map = L.map('map_' + regionId).setView([0,0], 2);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);

            response.data.forEach(row => {
                const popupHTML = buildPopup(row, config);
                L.marker([row.LAT, row.LON]) // Asumimos que siempre hay LAT/LON
                 .bindPopup(popupHTML)
                 .addTo(map);
            });
        }
    });
}

function buildPopup(row, config) {
    // Plantilla HTML con estilos genéricos (puedes meter esto en un CSS aparte)
    let html = `
        <div class="map-popup-card" style="min-width:200px">
            <h3 style="margin:0; color:#1a73e8">${row[config.titleField] || ''}</h3>
            <p style="margin:4px 0; color:#666; font-size:12px">${row[config.subtitleField] || ''}</p>
            <hr style="border:0; border-top:1px solid #eee">
            <table style="width:100%; font-size:13px">`;

    // Mapeo de campos dinámicos
    if (config.fields) {
        config.fields.forEach(f => {
            const val = row[f.field] || '';
            html += `<tr>
                        <td style="font-weight:bold; padding:2px 0">${f.label}:</td>
                        <td>${f.prefix || ''}${val}</td>
                     </tr>`;
        });
    }

    html += `</table>`;

    // Botones dinámicos
    if (config.buttons) {
        config.buttons.forEach(b => {
            const finalUrl = b.url + (row[b.urlField] || '');
            html += `<a href="${finalUrl}" class="t-Button t-Button--small t-Button--hot" 
                        style="display:block; text-align:center; margin-top:10px; text-decoration:none">
                        ${b.label}
                     </a>`;
        });
    }

    html += `</div>`;
    return html;
}
¿Por qué esta solución es la mejor?
Independencia de Columnas: El plugin ya no "sabe" qué columnas existen. El usuario puede agregar TELEFONO, DIRECCION, o STOCK en su SQL y simplemente mapearlas en el JSON de configuración.

Links Dinámicos: La lógica de botones permite construir URLs de APEX (f?p=...) inyectando el ID de la fila al final, permitiendo navegación desde el mapa hacia otras páginas.

Diseño Profesional: Al usar clases como t-Button dentro del popup, el mapa se siente como una parte nativa del Universal Theme de Oracle APEX.

Siguiente paso recomendado:
¿Te gustaría que te ayude a crear un CSS específico para el Popup dentro del plugin, para que los campos se vean alineados y los botones tengan el estilo exacto de tu aplicación? Sería agregarlo en la sección CSS > File URLs del plugin.
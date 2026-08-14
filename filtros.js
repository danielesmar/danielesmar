function renderPills() {
    var filters = [
        { id: 'P10_PRODUCTO',    label: 'Producto' },
        { id: 'P10_FECHA_DESDE', label: 'Desde' },
        { id: 'P10_FECHA_HASTA', label: 'Hasta' },
        { id: 'P10_BUSQUEDA',    label: 'Buscar' },
        { id: 'P10_ACTIVO',     label: 'Estado' }
    ];
    
    var html = '';
    var activeCount = 0;

    filters.forEach(function(f) {
        var val = $v(f.id);
        if (val !== null && val !== '') {
            activeCount++;
            html += '<span class="t-Badge t-Badge--pill t-Badge--info u-margin-xs js-pill">';
            html += '  <span class="js-edit-pill" style="cursor:pointer;" data-item="' + f.id + '">' + apex.util.escapeHTML(f.label) + ': ' + apex.util.escapeHTML(val) + '</span>';
            html += '  <button type="button" class="a-Button a-Button--noUI js-remove-pill u-margin-left-xs" data-item="' + f.id + '" title="Eliminar filtro">';
            html += '    <span class="fa fa-times" aria-hidden="true"></span>';
            html += '  </button>';
            html += '</span>';
        }
    });

    if (activeCount > 0) {
        html += '<button type="button" class="a-Button a-Button--link js-clear-all-pills u-margin-left-sm">Limpiar todo</button>';
    }

    $('#pills-container').html(html);
}

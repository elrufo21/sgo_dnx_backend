"""Filtra diferencias usando llamadas HTTP del frontend y metodos alcanzables."""
import collections
import argparse
import csv
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--carpeta', type=pathlib.Path, default=ROOT / 'artifacts/analisis-dxncomas-20261018')
OUT = parser.parse_args().carpeta.resolve()

def read(name):
    return json.loads((OUT/name).read_text(encoding='utf-8-sig'))

def write_csv(name, rows):
    rows=list(rows)
    fields=list(dict.fromkeys(k for r in rows for k in r)) or ['sin_resultados']
    with (OUT/name).open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)

front=read('frontend_llamadas.json')
classes={c['name']:c for c in read('backend_metodos.json')}
source=read('DXN_ICA15102026.json');target=read('DXNCOMAS.json')
objects={('dbo.'+r['name']).lower():r for r in source['modules']+source['tables']}
aliases={r['name'].lower():k for k,r in objects.items()}
target_objects={('dbo.'+r['name']).lower() for r in target['modules']+target['tables']}
impl=collections.defaultdict(set)
methods={};byname=collections.defaultdict(list)
for c in classes.values():
    for base in c['bases']:impl[base].add(c['name'])
    for m in c['methods']:
        mid=f"{c['name']}.{m['name']}:{m['line']}"
        methods[mid]=(c,m);byname[(c['name'],m['name'])].append(mid)
for interface,cls in re.findall(r'Add(?:Scoped|Transient)<(\w+),\s*(\w+)>',(ROOT/'src/Api/Program.cs').read_text(encoding='utf-8-sig')):
    impl[interface]={cls}

def attr_values(attrs,name):
    return [next((arg['value'] for arg in a['args'] or [] if not arg['name']), '') for a in attrs if a['name'].removesuffix('Attribute')==name]

routes=[]
for mid,(c,m) in methods.items():
    if not c['name'].endswith('Controller'):continue
    base=attr_values(c['attrs'],'Route')
    for a in m['attrs']:
        if a['name'] not in ('HttpGet','HttpPost','HttpPut','HttpPatch','HttpDelete'):continue
        http=a['name'][4:].upper()
        suffix=next((x['value'] for x in a['args'] or [] if not x['name']), '')
        for b in base or ['']:
            b=b.replace('[controller]',c['name'].removesuffix('Controller'))
            route=suffix.lstrip('~/') if suffix.startswith(('/','~/')) else b.rstrip('/')+'/'+suffix
            route='/'+route.strip('/')
            pattern=re.escape(route)
            pattern=re.sub(r'\\\{.*?\\\}',r'[^/]+',pattern)
            routes.append({'http':http,'route':route,'pattern':re.compile('^'+pattern+'/?$',re.I),'method':mid,'specificity':len(re.sub(r'\{.*?\}','',route))})

unused={
 ('src/store/cashFlow/cashFlow.store.ts','getActiveCashFlow'):'Accion del store sin consumidores; las pantallas usan otros endpoints de caja.',
 ('src/store/users/users.store.ts','addUser'):'Sin consumidores; las altas actuales usan addMaintenanceUser.',
 ('src/store/users/users.store.ts','deleteUser'):'Sin consumidores; mantenimiento usa deleteMaintenanceUser.',
 ('src/store/employees/employees.store.ts','addEmployee'):'Sin consumidores; las altas usan addMaintenanceEmployee.',
 ('src/store/employees/employees.store.ts','updateEmployee'):'Sin consumidores; la edicion usa updateMaintenanceEmployee.',
 ('src/store/employees/employees.store.ts','deleteEmployee'):'Solo referida por la entrada employees de listRegistry; ninguna pantalla instancia GenericList con ese moduleKey. EmployeeListPage usa deleteMaintenanceEmployee.',
 ('src/store/maintenance/maintenance.store.ts','deleteCategory'):'Sin consumidores; la pantalla usa deleteCategoryApi -> /Linea/maintenance/{id}.',
 ('src/store/orderNote/orderNote.store.ts','fetchNoteDetail'):'Sin consumidores; /Nota/sp/{id} no se solicita desde las pantallas actuales.',
 ('src/store/orderNote/orderNote.store.ts','updateNoteDetail'):'Sin consumidores; PUT editarOrden se mantiene por PaymentPage.',
 ('src/features/maintenance/holidays/holidays.api.ts','fetchHolidayByIdApi'):'Sin consumidores; holidayEdit carga el listado y busca el registro en memoria.',
}
excluded=[];matched=[];unmatched=[];external=[]
for i,call in enumerate(front['calls']):
    file=call['frontend'].rsplit(':',1)[0]
    reason=unused.get((file,call['owner']))
    if reason:
        excluded.append({'frontend':call['frontend'],'accion':call['owner'],'url':'; '.join(call['urls']),'motivo':reason});continue
    if file=='src/shared/helpers/apiRequest.ts':continue
    found=[]
    local_urls=[]
    for url in set(call['urls']):
        if url.startswith(('http:','https:','{PRINT_AGENT}')):
            external.append({'frontend':call['frontend'],'url':url,'accion':call['owner']});continue
        if not url.startswith('/api/'):
            if call['owner']!='handleConsultarDocumento':unmatched.append({'frontend':call['frontend'],'url':url,'accion':call['owner'],'motivo':'URL no resuelta'} )
            continue
        path=url.split('?',1)[0]
        path=re.sub(r'\{query\}$','',path)
        local_urls.append(path)
        for http in call['method']:
            possible=[r for r in routes if r['http']==http and r['pattern'].fullmatch(path)]
            if possible:
                r=max(possible,key=lambda r:r['specificity'])
                found.append({'frontend':call['frontend'],'accion_front':call['owner'],'consumidores_front':'; '.join(call['owner_usages']),'http':http,'endpoint':r['route'],'backend':r['method'],'url_front':url})
    if local_urls and not found:
        unmatched.append({'frontend':call['frontend'],'url':'; '.join(local_urls),'accion':call['owner'],'motivo':'Sin endpoint coincidente'})
    matched.extend(found)

edges=collections.defaultdict(set)
for mid,(c,m) in methods.items():
    fields={f['name']:f['type'] for f in c['fields']}
    params={p['name']:p['type'] for p in m['parameters']}
    for call in m['calls']:
        receiver=call['receiver'];name=call['name']
        targets=set()
        if receiver in ('','this'):targets.add(c['name'])
        elif receiver in classes:targets.add(receiver)
        elif receiver in fields or receiver in params:
            typ=fields.get(receiver,params.get(receiver))
            targets.update(impl.get(typ,set()))
            if typ in classes:targets.add(typ)
        for cls in targets:
            edges[mid].update(byname.get((cls,name),[]))
    attrs=c['attrs']+m['attrs']
    if attr_values(attrs,'RequirePermission'):edges[mid].update(byname.get(('RequirePermissionFilter','OnAuthorizationAsync'),[]))
    if attr_values(attrs,'RequireAttendance'):edges[mid].update(byname.get(('RequireAttendanceFilter','OnAuthorizationAsync'),[]))

fallback_methods={('ProductoRepository','GuardarProductoLegacyAsync'),('UsuarioRepository','LoginIdentityAsync')}
fallback_names={'usplistarproducto'}
object_roots=collections.defaultdict(set);method_roots=collections.defaultdict(set)
sql_evidence=collections.defaultdict(list);unknown_roots=collections.defaultdict(set);fallback=[]
roots={r['backend'] for r in matched}
for root in roots:
    seen=set();queue=[root]
    while queue:
        mid=queue.pop()
        if mid in seen:continue
        seen.add(mid);c,m=methods[mid]
        if (c['name'],m['name']) in fallback_methods:
            fallback.append({'endpoint_backend':root,'metodo':mid,'motivo':'Alternativa heredada; no necesaria al instalar el contrato principal WEB.'});continue
        method_roots[mid].add(root)
        for lit in m['strings']+m['interpolated']:
            value=lit['value'];evidence=f"{c['file']}:{lit['line']}"
            simple=re.fullmatch(r'(?:dbo\.)?([A-Za-z_]\w*)',value)
            if simple:
                name=simple[1].lower()
                if name in fallback_names:
                    fallback.append({'endpoint_backend':root,'metodo':mid,'motivo':f'{value}: SP opcional con catch 2812 y consulta directa alternativa.'});continue
                obj=aliases.get(name)
                if obj in objects and objects[obj].get('type_desc','').endswith(('PROCEDURE','FUNCTION')):
                    object_roots[obj].add(root)
                    sql_evidence[obj].append((evidence,mid))
                elif name.startswith('usp') and name not in aliases:
                    unknown_roots['dbo.'+name].add(root)
                    sql_evidence['dbo.'+name].append((evidence,mid))
            if re.search(r'\b(?:SELECT|INSERT|UPDATE|DELETE|EXEC)\b',value,re.I):
                for x in re.finditer(r'\b(?:FROM|JOIN|UPDATE|INTO|EXEC(?:UTE)?)\s+(?:\[?dbo\]?\.)?\[?(\w+)\]?',value,re.I):
                    obj=aliases.get(x[1].lower())
                    if obj:
                        object_roots[obj].add(root);sql_evidence[obj].append((evidence,mid))
                for x in re.finditer(r'\bdbo\.\[?(\w+)\]?\s*\(',value,re.I):
                    obj=aliases.get(x[1].lower())
                    if obj and 'FUNCTION' in objects[obj].get('type_desc',''):
                        object_roots[obj].add(root);sql_evidence[obj].append((evidence,mid))
        queue.extend(edges[mid]-seen)

sql_edges=collections.defaultdict(set)
for d in source['dependencies']:
    if d['referenced_database_name'] or d['referenced_server_name']:continue
    owner=(d['schema_name']+'.'+d['object_name']).lower();name=(d['referenced_entity_name']or'').lower()
    dep=aliases.get(name)
    if dep:sql_edges[owner].add(dep)
for k,v in objects.items():
    text=re.sub(r'--[^\n]*|/\*[\s\S]*?\*/','',v.get('definition')or'')
    for m in re.finditer(r'\b(?:FROM|JOIN|UPDATE|INTO|EXEC(?:UTE)?)\s+(?:\[?dbo\]?\.)?\[?(\w+)\]?',text,re.I):
        dep=aliases.get(m[1].lower())
        if dep:sql_edges[k].add(dep)
# Contratos que la web llama pero no estan instalados: solo sus definiciones
# identificadas en el repo, sin incorporar procedimientos vecinos del mismo archivo.
candidate_files={
 'dbo.uspguardarunidadmedidaproducto':ROOT.parent/'sgo_dnx_frontend/docs/uspGuardarUnidadMedidaProducto.sql',
 'dbo.usplistarcomprasweb':ROOT/'scripts/sql/20260825_uspListarComprasweb.sql',
 'dbo.usplistadocumentosweb':ROOT/'scripts/sql/20261016_uspListaDocumentosWEB_icbper.sql',
}
candidate_definitions={}
candidate_sources={}
for obj,path in candidate_files.items():
    if obj not in unknown_roots:continue
    text=path.read_text(encoding='utf-8-sig')
    candidate_definitions[obj]=text
    candidate_sources[obj]=str(path.relative_to(ROOT.parent)).replace('\\','/')
    object_roots[obj].update(unknown_roots[obj])
    for m in re.finditer(r'\b(?:FROM|JOIN|UPDATE|INTO|EXEC(?:UTE)?)\s+(?:\[?dbo\]?\.)?\[?(\w+)\]?',text,re.I):
        dep=aliases.get(m[1].lower())
        if dep:sql_edges[obj].add(dep)
historical=ROOT/'scripts/sql/bdactual.sql'
historical_text=historical.read_text(encoding='utf-8-sig',errors='replace')
for obj in unknown_roots:
    if obj in candidate_definitions:continue
    match=re.search(r'CREATE\s+(?:OR\s+ALTER\s+)?PROC(?:EDURE)?\s+(?:\[?dbo\]?\.)?\[?'+re.escape(obj.split('.')[-1])+r'\b.*?(?=\nGO\s*(?:\n|$)|\Z)',historical_text,re.I|re.S)
    if not match:continue
    text=match[0]
    candidate_definitions[obj]=text
    candidate_sources[obj]=f"scripts/sql/bdactual.sql:{historical_text.count(chr(10),0,match.start())+1}"
    object_roots[obj].update(unknown_roots[obj])
    for m in re.finditer(r'\b(?:FROM|JOIN|UPDATE|INTO|EXEC(?:UTE)?)\s+(?:\[?dbo\]?\.)?\[?(\w+)\]?',text,re.I):
        dep=aliases.get(m[1].lower())
        if dep:sql_edges[obj].add(dep)
parents=collections.defaultdict(set)
queue=list(object_roots)
while queue:
    owner=queue.pop()
    for dep in sql_edges[owner]:
        parents[dep].add(owner)
        new=object_roots[owner]-object_roots[dep]
        if new:object_roots[dep].update(new);queue.append(dep)

front_by_root=collections.defaultdict(list)
for row in matched:front_by_root[row['backend']].append(row)
object_rows=[]
for obj in sorted(object_roots.keys()|unknown_roots.keys()):
    r=objects.get(obj);active=object_roots.get(obj,unknown_roots.get(obj,set()))
    object_rows.append({'objeto':obj,'tipo':r.get('type_desc','TABLE') if r else 'PROCEDIMIENTO_AUSENTE_EN_REFERENCIA','estado_comas':'Existe' if obj in target_objects else 'Falta','origen':'SQL directo desde endpoint' if sql_evidence[obj] else 'Dependencia SQL','endpoints':'; '.join(sorted({row['http']+' '+row['endpoint'] for root in active for row in front_by_root[root]})),'frontend':'; '.join(sorted({row['frontend'] for root in active for row in front_by_root[root]})),'backend_sql':'; '.join(sorted({x[0] for x in sql_evidence[obj]})),'metodos_sql':'; '.join(sorted({x[1] for x in sql_evidence[obj]})),'dependiente_de':'; '.join(sorted(parents[obj]))})
write_csv('web_objetos_confirmados.csv',object_rows)
write_csv('web_definiciones_candidatas.csv',({'procedimiento':obj,'fuente':path,'estado':'Definicion en archivo; ausente en ambas bases. Revisar antes de instalar.'} for obj,path in sorted(candidate_sources.items())))
legacy={'dbo.uspobtenercajaactivaweb','dbo.uspretornaboletaporticketweb','dbo.uspobtenernotapedido','dbo.uspingresarpersonal','dbo.uspeliminarpersonal','dbo.uspeliminarusuario','dbo.usplistawebproducto','dbo.uspbuscawebproducto','dbo.usplistarproducto','dbo.uspingresarproducto'}
assert not legacy & {r['objeto'] for r in object_rows}, 'Se reincorporo un contrato sin cadena frontend principal.'
assert not unmatched, 'Revisar llamadas HTTP sin endpoint antes de presentar el alcance.'
assert all(r['frontend'] and r['endpoints'] for r in object_rows)
assert any(r['objeto']=='dbo.uspinsertarusuario' and 'PUT /api/v1/UsuariosCrud/{id:int}' in r['endpoints'] for r in object_rows)
with (OUT/'columnas.csv').open(encoding='utf-8-sig') as f:
    raw_columns=list(csv.DictReader(f))
column_rows=[]
for row in raw_columns:
    if row['estado'] not in ('Columna faltante','Tabla faltante','Diferente'):continue
    schema,table,column=row['columna'].split('.')
    tablekey=(schema+'.'+table).lower()
    evidence=[]
    for mid in method_roots:
        c,m=methods[mid]
        for lit in m['strings']+m['interpolated']:
            if re.search(r'\b'+re.escape(table)+r'\b',lit['value'],re.I) and re.search(r'\b'+re.escape(column)+r'\b',lit['value'],re.I):
                evidence.append(f"{c['file']}:{lit['line']} ({mid})")
    for obj in object_roots:
        definition=(objects.get(obj,{}).get('definition') or candidate_definitions.get(obj,''))
        if re.search(r'\b'+re.escape(table)+r'\b',definition,re.I) and re.search(r'\b'+re.escape(column)+r'\b',definition,re.I):
            evidence.append(obj)
    if tablekey not in object_roots and not evidence:continue
    if row['estado']=='Tabla faltante' and tablekey not in object_roots:continue
    classification='Contrato alcanzado desde frontend'
    if row['columna'] in ('dbo.NotaPedido.Almacen','dbo.NotaPedido.Hora'):
        classification='Complementaria: el actualizador comprueba existencia y tolera ausencia'
    elif row['estado']=='Diferente':classification='Evaluar contrato; diferencia de tipo no prueba bloqueo'
    column_rows.append({'columna':row['columna'],'estado':row['estado'],'clasificacion':classification,'evidencia':'; '.join(sorted(set(evidence))),'definicion_referencia':row['definicion_referencia'],'definicion_destino':row['definicion_destino']})
write_csv('web_columnas_con_trazabilidad.csv',column_rows)
with (OUT/'indices_y_restricciones.csv').open(encoding='utf-8-sig') as f:
    write_csv('web_indices_y_restricciones.csv',(r for r in csv.DictReader(f) if '.'.join(r['objeto'].lower().split('.')[:2]) in object_roots))
write_csv('web_endpoints_confirmados.csv',matched)
write_csv('web_llamadas_excluidas.csv',excluded)
write_csv('web_llamadas_externas.csv',external)
write_csv('web_llamadas_no_resueltas.csv',unmatched)
write_csv('web_alternativas_no_obligatorias.csv',fallback)
write_csv('web_metodos_alcanzados.csv',({'metodo':mid,'archivo':methods[mid][0]['file'],'endpoints_backend':'; '.join(sorted(roots))} for mid,roots in sorted(method_roots.items())))
write_csv('web_endpoints_sin_llamada.csv',({'http':r['http'],'endpoint':r['route'],'metodo':r['method']} for r in routes if r['method'] not in roots))
summary={'archivos_front_alcanzables':len(front['reachable_files']),'llamadas_http_inspeccionadas':len(front['calls']),'llamadas_excluidas':len(excluded),'endpoints_confirmados':len({(r['http'],r['endpoint']) for r in matched}),'llamadas_sin_resolver':len(unmatched),'objetos_requeridos':len(object_rows),'faltantes_por_tipo':dict(collections.Counter(r['tipo'] for r in object_rows if r['estado_comas']=='Falta')),'ausentes_en_ambas':[r['objeto'] for r in object_rows if r['tipo']=='PROCEDIMIENTO_AUSENTE_EN_REFERENCIA'],'tablas_faltantes':[r['objeto'] for r in object_rows if r['tipo']=='TABLE' and r['estado_comas']=='Falta']}
(OUT/'diagnostico_solo_lectura.sql').write_text("""-- DIAGNOSTICO FILTRADO POR FRONTEND. Solo SELECT; no instala migraciones.
-- Fuente de alcance: web_endpoints_confirmados.csv y web_objetos_confirmados.csv.
-- Los objetos ausentes en ambas bases se mantienen solo cuando la web los llama.
;WITH Requeridos(nombre) AS (SELECT nombre FROM (VALUES
"""+',\n'.join(" (N'"+r['objeto']+"')" for r in object_rows)+"""
) v(nombre))
SELECT r.nombre, s.type_desc tipo_referencia,d.type_desc tipo_comas,
 CASE WHEN s.object_id IS NULL THEN 'Ausente en referencia' ELSE 'Existe' END referencia,
 CASE WHEN d.object_id IS NULL THEN 'Falta en COMAS' ELSE 'Existe' END comas
FROM Requeridos r
LEFT JOIN DXN_ICA15102026.sys.schemas ss ON ss.name=PARSENAME(r.nombre,2)
LEFT JOIN DXN_ICA15102026.sys.objects s ON s.name=PARSENAME(r.nombre,1) AND s.schema_id=ss.schema_id
LEFT JOIN DXNCOMAS.sys.schemas ds ON ds.name=PARSENAME(r.nombre,2)
LEFT JOIN DXNCOMAS.sys.objects d ON d.name=PARSENAME(r.nombre,1) AND d.schema_id=ds.schema_id
ORDER BY r.nombre;
GO
""",encoding='utf-8-sig')
(OUT/'web_resumen.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# Procedimientos faltantes con cadena frontend -> endpoint -> SQL\n',
       'Lista filtrada por la web actual. Los nombres se muestran normalizados a minusculas; ambas bases usan collation CI.\n',
       '| Procedimiento | Situacion | Endpoint que lo requiere | Evidencia frontend | Evidencia SQL |',
       '| --- | --- | --- | --- | --- |']
for r in object_rows:
    if r['estado_comas']!='Falta' or r['tipo']=='TABLE':continue
    situation='Existe en ICA; falta en COMAS' if r['tipo']=='SQL_STORED_PROCEDURE' else 'Falta en ambas copias'
    lines.append('| `'+r['objeto']+'` | '+situation+' | '+r['endpoints'].replace('; ','<br>')+' | '+r['frontend'].replace('; ','<br>')+' | '+(r['backend_sql'] or r['dependiente_de']).replace('; ','<br>')+' |')
(OUT/'web_procedimientos_faltantes.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False,indent=2))

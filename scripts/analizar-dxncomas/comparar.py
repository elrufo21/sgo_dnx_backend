"""Compara snapshots de exportar.ps1 y registra evidencia estatica del codigo."""
import argparse
import collections
import csv
import difflib
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
TOKEN = re.compile(r"N?'(?:''|[^'])*'|--[^\n]*|/\*[\s\S]*?\*/|\[[^\]]+\]|[\w@#$]+|[^\s]", re.I)
CS = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|\$*"{3,}[\s\S]*?"{3,}|\$?@"(?:""|[^"])*"|\$?"(?:\\.|[^"\\])*"', re.M)

def normalized(sql):
    parts = []
    for m in TOKEN.finditer(sql or ''):
        token = m.group()
        if token.startswith(('--', '/*')):
            continue
        if re.match(r"N?'", token, re.I):
            parts.append(token)
        else:
            parts.append(token.strip('[]').lower())
    if parts and parts[0] in ('create', 'alter'):
        parts[0] = 'create'
    return tuple(parts)

def key(row, fields=('schema_name', 'name')):
    return '.'.join(str(row[f]).lower() for f in fields)

def display(row, fields=('schema_name', 'name')):
    return '.'.join(str(row[f]) for f in fields)

def index(rows, fields=('schema_name', 'name')):
    return {key(r, fields): r for r in rows}

def dump_csv(folder, name, rows, fields=None):
    rows = list(rows)
    fields = fields or list(dict.fromkeys(k for row in rows for k in row)) or ['sin_diferencias']
    with (folder / name).open('w', encoding='utf-8-sig', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)

def csv_value(v):
    return json.dumps(v, ensure_ascii=False, sort_keys=True)

def grouped(rows, fields):
    result = collections.defaultdict(list)
    for row in rows:
        result[key(row, fields)].append(row)
    return result

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--carpeta', type=pathlib.Path, default=ROOT / 'artifacts/analisis-dxncomas-20261018')
    parser.add_argument('--referencia', default='DXN_ICA15102026')
    parser.add_argument('--destino', default='DXNCOMAS')
    args = parser.parse_args()
    out = args.carpeta.resolve()
    snapshots = []
    for name in (args.referencia, args.destino):
        data = json.loads((out / f'{name}.json').read_text(encoding='utf-8-sig'))
        snapshots.append({k: v if v is not None else [] for k, v in data.items()})
    source, target = snapshots
    sm, tm = index(source['modules']), index(target['modules'])
    st, tt = index(source['tables']), index(target['tables'])
    objects = sm | st
    aliases = {r['name'].lower(): k for k, r in objects.items()}
    direct = collections.defaultdict(set)
    unknown = collections.defaultdict(set)
    sql_literals = []
    for path in sorted((ROOT / 'src').rglob('*.cs')):
        if any(x in path.parts for x in ('bin', 'obj', 'artifacts', 'Migrations')):
            continue
        text = path.read_text(encoding='utf-8-sig')
        for m in CS.finditer(text):
            literal = m.group()
            if literal.startswith(('//', '/*')):
                continue
            value = re.sub(r'^\$*@?', '', literal).strip('"')
            evidence = f"{path.relative_to(ROOT).as_posix()}:{text.count(chr(10), 0, m.start()) + 1}"
            if re.fullmatch(r'(?:dbo\.)?[A-Za-z_]\w*', value):
                name = value.removeprefix('dbo.').lower()
                obj = aliases.get(name)
                if obj in sm:
                    direct[obj].add(evidence)
                elif name.startswith('usp'):
                    unknown[name].add(evidence)
            if re.search(r'\b(SELECT|UPDATE|INSERT|DELETE|EXEC|FROM|JOIN)\b', value, re.I):
                sql_literals.append((value, evidence))
                for match in re.finditer(r'\b(?:FROM|JOIN|UPDATE|INTO|EXEC(?:UTE)?)\s+(?:\[?dbo\]?\.)?\[?([A-Za-z_]\w*)\]?', value, re.I):
                    obj = aliases.get(match[1].lower())
                    if obj:
                        direct[obj].add(evidence)
                for match in re.finditer(r'\bdbo\.\[?(\w+)\]?\s*\(', value, re.I):
                    obj = aliases.get(match[1].lower())
                    if obj in sm:
                        direct[obj].add(evidence)
    # Las relaciones SQL del catalogo se complementan con nombres de tablas en modulos.
    edges = collections.defaultdict(set)
    crossdb = []
    for dep in source['dependencies']:
        owner = key(dep, ('schema_name', 'object_name'))
        if dep['referenced_database_name'] or dep['referenced_server_name']:
            crossdb.append(dep)
            continue
        name = str(dep['referenced_entity_name'] or '').lower()
        obj = (str(dep['referenced_schema_name']).lower() + '.' + name) if dep['referenced_schema_name'] else aliases.get(name)
        if obj in objects:
            edges[owner].add(obj)
    for owner, row in sm.items():
        sql = row['definition'] or ''
        # Solo nombres en sentencias; evita marcar columnas homonimas como dependencias.
        sql = re.sub(r'--[^\n]*|/\*[\s\S]*?\*/', '', sql)
        for match in re.finditer(r'\b(?:FROM|JOIN|UPDATE|INTO|EXEC(?:UTE)?)\s+(?:\[?dbo\]?\.)?\[?(\w+)\]?', sql, re.I):
            obj = aliases.get(match[1].lower())
            if obj:
                edges[owner].add(obj)
    parents = collections.defaultdict(set)
    reachable = set(direct)
    queue = list(reachable)
    while queue:
        owner = queue.pop()
        for obj in edges[owner]:
            parents[obj].add(owner)
            if obj not in reachable:
                reachable.add(obj)
                queue.append(obj)
    evidence = lambda k: '; '.join(sorted(direct.get(k, set())))
    scope = lambda k: 'Backend directo' if k in direct else ('Dependencia SQL' if k in reachable else 'Sin uso web identificado')
    stats = {'referencia': args.referencia, 'destino': args.destino, 'captura': source['captured_at']}
    stats['inventario'] = {name: {kind: (len(grouped(data[kind], ('schema_name','table_name','name'))) if kind in ('indexes','foreign_keys') else len(data[kind])) for kind in ('tables', 'columns', 'modules', 'indexes', 'foreign_keys')} for name, data in zip((args.referencia,args.destino), snapshots)}
    stats['modulos_por_tipo'] = {name: dict(collections.Counter(x['type_desc'] for x in data['modules'])) for name,data in zip((args.referencia,args.destino),snapshots)}
    module_rows = []
    diff_lines = []
    param_s = grouped(source['parameters'], ('schema_name', 'object_name'))
    param_t = grouped(target['parameters'], ('schema_name', 'object_name'))
    for k in sorted(sm):
        a, b = sm[k], tm.get(k)
        state = 'Faltante' if b is None else ('Diferente' if normalized(a['definition']) != normalized(b['definition']) or any(a[f] != b[f] for f in ('uses_ansi_nulls','uses_quoted_identifier')) else 'Igual')
        fields = ('name','parameter_id','type_name','max_length','precision','scale','is_output')
        params = lambda d: [{f: r[f] for f in fields} for r in d.get(k, [])]
        module_rows.append({'objeto': display(a), 'tipo': a['type_desc'], 'estado': state, 'alcance': scope(k), 'parametros_distintos': params(param_s) != params(param_t) if b else '', 'evidencia_backend': evidence(k), 'llamado_por_sql': '; '.join(sorted(parents[k]))})
        if b and state == 'Diferente':
            diff_lines.extend(difflib.unified_diff((b['definition'] or '').splitlines(True),(a['definition'] or '').splitlines(True),fromfile=f"{args.destino}/{display(a)}",tofile=f"{args.referencia}/{display(a)}"))
    dump_csv(out, 'procedimientos_y_modulos.csv', module_rows)
    (out / 'diferencias_modulos.diff').write_text(''.join(diff_lines), encoding='utf-8')
    stats['modulos_estados'] = dict(collections.Counter(r['estado'] for r in module_rows))
    stats['faltantes_por_alcance'] = dict(collections.Counter(r['alcance'] for r in module_rows if r['estado']=='Faltante'))
    table_rows = []
    for k in sorted(st.keys() | tt.keys()):
        a,b = st.get(k),tt.get(k)
        table_rows.append({'tabla':display(a or b),'estado':'Solo destino' if not a else ('Faltante' if not b else 'En ambas'),'alcance':scope(k),'filas_referencia_aprox':a['approximate_rows'] if a else '', 'filas_destino_aprox':b['approximate_rows'] if b else '', 'evidencia_backend':evidence(k),'dependientes_sql':'; '.join(sorted(parents[k]))})
    dump_csv(out, 'tablas.csv', table_rows)
    stats['tablas_estados'] = dict(collections.Counter(r['estado'] for r in table_rows))
    sc,tc = index(source['columns'],('schema_name','table_name','name')),index(target['columns'],('schema_name','table_name','name'))
    column_rows = []
    attrs = ('type_name','max_length','precision','scale','is_nullable','is_identity','is_computed','collation_name','default_definition','computed_definition','identity_seed','identity_increment')
    for k in sorted(sc.keys() | tc.keys()):
        a,b = sc.get(k),tc.get(k)
        changed = [f for f in attrs if (normalized(a[f]) != normalized(b[f]) if f in ('default_definition','computed_definition') else a[f] != b[f])] if a and b else []
        if a and b and not changed:
            continue
        row = a or b
        table_key = key(row, ('schema_name','table_name'))
        direct_mentions = [e for sql,e in sql_literals if re.search(r'\b'+re.escape(row['name'])+r'\b',sql,re.I) and re.search(r'\b'+re.escape(row['table_name'])+r'\b',sql,re.I)]
        column_rows.append({'columna':display(row,('schema_name','table_name','name')),'estado':'Solo destino' if not a else ('Tabla faltante' if table_key not in tt else ('Columna faltante' if not b else 'Diferente')),'alcance_tabla':scope(table_key),'atributos_distintos':'; '.join(changed),'definicion_referencia':csv_value({f:a[f] for f in attrs}) if a else '', 'definicion_destino':csv_value({f:b[f] for f in attrs}) if b else '', 'evidencia_sql_directo':'; '.join(sorted(set(direct_mentions)))})
    dump_csv(out,'columnas.csv',column_rows)
    stats['columnas_estados'] = dict(collections.Counter(r['estado'] for r in column_rows))
    # Compara indices por estructura y no por nombres generados automaticamente.
    structural = []
    definitions = {
      'indexes':(('schema_name','table_name','name'),('type_desc','is_unique','is_primary_key','is_unique_constraint','is_disabled','filter_definition','column_name','key_ordinal','is_descending_key','is_included_column')),
      'foreign_keys':(('schema_name','table_name','name'),('column_name','referenced_schema','referenced_table','referenced_column','constraint_column_id','delete_referential_action_desc','update_referential_action_desc','is_disabled','is_not_trusted')),
      'checks':(('schema_name','table_name','name'),('definition','is_disabled','is_not_trusted'))}
    for kind,(keys,fields) in definitions.items():
        groups = [grouped(d[kind],keys) for d in snapshots]
        def signature(rows):
            return (key(rows[0],('schema_name','table_name')),tuple(sorted(tuple(csv_value(r[f]) for f in fields) for r in rows)))
        sigsets = [{signature(v) for v in g.values()} for g in groups]
        for side,gr in enumerate(groups):
            for rows in gr.values():
                if signature(rows) not in sigsets[1-side]:
                    structural.append({'tipo':kind,'objeto':display(rows[0],keys),'estado':'Faltante o diferente' if side==0 else 'Solo destino o diferente','definicion':csv_value([{f:r[f] for f in fields} for r in rows])})
    dump_csv(out,'indices_y_restricciones.csv',structural)
    stats['estructura'] = dict(collections.Counter(r['tipo']+' '+r['estado'] for r in structural))
    dump_csv(out,'referencias_no_encontradas.csv',({'nombre':n,'evidencia':'; '.join(sorted(e))} for n,e in sorted(unknown.items())))
    dump_csv(out,'dependencias_entre_bases.csv',crossdb)
    dump_csv(out,'indicadores_referencia_sin_valores.csv',source['indicator_keys'])
    dump_csv(out,'controles_datos.csv',({'base':name,**r} for name,data in zip((args.referencia,args.destino),snapshots) for r in data.get('readiness',[])))
    positional = []
    changed_tables = {key(r,('schema_name','table_name')) for k,r in sc.items() if k not in tc and key(r,('schema_name','table_name')) in tt}
    for row in target['modules']:
        sql = re.sub(r'--[^\n]*|/\*[\s\S]*?\*/', '', row['definition'] or '')
        for m in re.finditer(r'\bINSERT\s+(?:INTO\s+)?(?:\[?dbo\]?\.)?\[?(\w+)\]?\s+(?:VALUES|SELECT)\b', sql, re.I):
            if 'dbo.'+m[1].lower() in changed_tables:
                positional.append({'procedimiento':display(row),'tabla':m[1],'riesgo':'Agregar columnas altera INSERT sin lista explicita','sentencia':m[0]})
    dump_csv(out,'inserts_posicionales_a_revisar.csv',positional)
    # Script de diagnostico: solo SELECT; incluye contratos faltantes en ambas copias.
    called = {k for k in direct if k in sm and sm[k]['type'].strip()=='P'} | {'dbo.'+k.removeprefix('dbo.') for k in unknown}
    assert all(k in called for k in direct if k in sm and sm[k]['type_desc']=='SQL_STORED_PROCEDURE')
    values = ',\n'.join("    (N'"+n.replace("'","''")+"')" for n in sorted(called))
    sql = f"""-- Diagnostico DXNCOMAS. Generado desde el codigo local; NO instala migraciones.
-- Servidor de la captura: localhost\\SQLEXPRESS01. Solo consultas SELECT.
-- Los conteos normalizados y el analisis de alcance estan en el informe Markdown.
SELECT name, compatibility_level, collation_name FROM sys.databases
WHERE name IN (N'{args.referencia}',N'{args.destino}');
GO
;WITH R AS (
 SELECT s.name esquema,t.name tabla FROM [{args.referencia}].sys.tables t
 JOIN [{args.referencia}].sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0
), D AS (
 SELECT s.name esquema,t.name tabla FROM [{args.destino}].sys.tables t
 JOIN [{args.destino}].sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0
)
SELECT COALESCE(R.esquema,D.esquema) esquema,COALESCE(R.tabla,D.tabla) tabla,
 CASE WHEN R.tabla IS NULL THEN 'Solo destino: conservar' ELSE 'Falta en DXNCOMAS' END estado
FROM R FULL JOIN D ON R.esquema=D.esquema AND R.tabla=D.tabla
WHERE R.tabla IS NULL OR D.tabla IS NULL;
GO
;WITH Requeridos(nombre) AS (SELECT nombre FROM (VALUES
{values}
) v(nombre))
SELECT r.nombre,
 CASE WHEN s.object_id IS NULL THEN 'Ausente en referencia' ELSE 'Existe en referencia' END referencia,
 CASE WHEN d.object_id IS NULL THEN 'Ausente en DXNCOMAS' ELSE 'Existe en DXNCOMAS' END destino
FROM Requeridos r
LEFT JOIN [{args.referencia}].sys.procedures s ON s.name=PARSENAME(r.nombre,1)
 AND s.schema_id=(SELECT schema_id FROM [{args.referencia}].sys.schemas WHERE name=PARSENAME(r.nombre,2))
LEFT JOIN [{args.destino}].sys.procedures d ON d.name=PARSENAME(r.nombre,1)
 AND d.schema_id=(SELECT schema_id FROM [{args.destino}].sys.schemas WHERE name=PARSENAME(r.nombre,2))
ORDER BY r.nombre;
GO
SELECT s.name esquema,t.name tabla,c.name columna,ty.name tipo,c.max_length,c.precision,c.scale,c.is_nullable,
 CASE WHEN dt.object_id IS NULL THEN 'Tabla faltante' ELSE 'Columna faltante' END estado
FROM [{args.referencia}].sys.tables t
JOIN [{args.referencia}].sys.schemas s ON s.schema_id=t.schema_id
JOIN [{args.referencia}].sys.columns c ON c.object_id=t.object_id
JOIN [{args.referencia}].sys.types ty ON ty.user_type_id=c.user_type_id
LEFT JOIN [{args.destino}].sys.schemas ds ON ds.name=s.name
LEFT JOIN [{args.destino}].sys.tables dt ON dt.name=t.name AND dt.schema_id=ds.schema_id
LEFT JOIN [{args.destino}].sys.columns dc ON dc.object_id=dt.object_id AND dc.name=c.name
WHERE t.is_ms_shipped=0 AND dc.column_id IS NULL
ORDER BY s.name,t.name,c.column_id;
GO
"""
    (out/'diagnostico_inventario_solo_lectura.sql').write_text(sql,encoding='utf-8-sig')
    dump_csv(out,'dependencias_web.csv',({'objeto':display(objects[k]),'tipo':objects[k].get('type_desc','TABLE'),'alcance':scope(k),'evidencia_backend':evidence(k),'llamado_por_sql':'; '.join(sorted(parents[k]))} for k in sorted(reachable)))
    (out/'resumen.json').write_text(json.dumps(stats,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(stats,ensure_ascii=False,indent=2))

if __name__ == '__main__':
    assert normalized("ALTER PROC [dbo].[p] AS SELECT 'A  B' -- comentario") == normalized("create proc dbo.p as select 'A  B'")
    assert normalized("SELECT 'A  B'") != normalized("SELECT 'A B'")
    assert normalized("SELECT 'Ab'") != normalized("SELECT 'ab'")
    assert index([{'schema_name':'dbo','name':'Test'}])['dbo.test']['name'] == 'Test'
    main()

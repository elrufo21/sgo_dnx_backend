// Inventario AST de llamadas HTTP desde modulos alcanzables por main.tsx.
const fs = require('node:fs');
const path = require('node:path');
const backend = path.resolve(__dirname, '../..');
const front = path.resolve(backend, '../sgo_dnx_frontend');
const ts = require(path.join(front, 'node_modules/typescript'));
const config = ts.readConfigFile(path.join(front, 'tsconfig.app.json'), ts.sys.readFile);
const parsed = ts.parseJsonConfigFileContent(config.config, ts.sys, front);
const program = ts.createProgram(parsed.fileNames, parsed.options);
const checker = program.getTypeChecker();
const sources = new Map(program.getSourceFiles().filter(s => s.fileName.replaceAll('\\','/').startsWith(front.replaceAll('\\','/')+'/src/')).map(s => [path.resolve(s.fileName), s]));
const reachable = new Set();
function visitImports(filename) {
  filename = path.resolve(filename);
  if (reachable.has(filename) || !sources.has(filename)) return;
  reachable.add(filename);
  function walk(n) {
    let spec;
    if ((ts.isImportDeclaration(n) && !n.importClause?.isTypeOnly) || ts.isExportDeclaration(n)) spec = n.moduleSpecifier;
    if (ts.isCallExpression(n) && n.expression.kind === ts.SyntaxKind.ImportKeyword) spec = n.arguments[0];
    if (spec && ts.isStringLiteral(spec)) {
      const result = ts.resolveModuleName(spec.text, filename, parsed.options, ts.sys).resolvedModule;
      if (result) visitImports(result.resolvedFileName);
    }
    ts.forEachChild(n, walk);
  }
  walk(sources.get(filename));
}
visitImports(path.join(front, 'src/main.tsx'));
const files = [...reachable].map(f => sources.get(f));
const reads = new Map();
function nameOf(n) { return n && (ts.isIdentifier(n) || ts.isStringLiteral(n)) ? n.text : ''; }
function evidence(n) { const sf=n.getSourceFile(); return path.relative(front,sf.fileName).replaceAll('\\','/')+':'+(sf.getLineAndCharacterOfPosition(n.getStart()).line+1); }
for (const sf of files) {
  function walk(n) {
    if (ts.isIdentifier(n)) {
      const p = n.parent;
      const declName = (ts.isPropertyAssignment(p)||ts.isPropertySignature(p)||ts.isMethodSignature(p)||ts.isVariableDeclaration(p)||ts.isFunctionDeclaration(p)||ts.isMethodDeclaration(p)||ts.isParameter(p)) && p.name===n;
      if (!declName && !ts.isImportSpecifier(p) && !ts.isImportClause(p) && !ts.isTypeReferenceNode(p)) {
        if (!reads.has(n.text)) reads.set(n.text, []);
        reads.get(n.text).push(evidence(n));
      }
    }
    ts.forEachChild(n,walk);
  }
  walk(sf);
}
function declaration(n) {
  let s=checker.getSymbolAtLocation(n);
  if (s && (s.flags & ts.SymbolFlags.Alias)) s=checker.getAliasedSymbol(s);
  return s?.valueDeclaration || s?.declarations?.[0];
}
function evalText(n, depth=0, seen=new Set()) {
  if (!n || depth>14 || seen.has(n)) return ['{dynamic}'];
  seen=new Set(seen); seen.add(n);
  const ev=x=>evalText(x,depth+1,seen);
  if (ts.isStringLiteral(n)||ts.isNoSubstitutionTemplateLiteral(n)) return [n.text];
  if (ts.isParenthesizedExpression(n)||ts.isAsExpression(n)||ts.isNonNullExpression(n)) return ev(n.expression);
  if (ts.isConditionalExpression(n)) return [...ev(n.whenTrue),...ev(n.whenFalse)];
  if (ts.isBinaryExpression(n)&&n.operatorToken.kind===ts.SyntaxKind.PlusToken) return ev(n.left).flatMap(a=>ev(n.right).map(b=>a+b));
  if (ts.isTemplateExpression(n)) {
    let values=[n.head.text];
    for (const s of n.templateSpans) values=values.flatMap(a=>ev(s.expression).map(b=>a+b+s.literal.text));
    return values;
  }
  if (ts.isIdentifier(n)) {
    if (n.text==='API_BASE_URL') return ['/api/v1'];
    if (n.text==='PRINT_AGENT_BASE_URL') return ['{PRINT_AGENT}'];
    if (n.text==='API_ROOT_URL') return [''];
    if (/^(query|queryString|queryParams|params|suffix)$/i.test(n.text)) return ['{query}'];
    const d=declaration(n);
    if (d && ts.isVariableDeclaration(d) && d.initializer) return ev(d.initializer);
    return ['{'+n.text+'}'];
  }
  if (ts.isPropertyAccessExpression(n)) {
    const d=declaration(n.name);
    if(d&&ts.isPropertyAssignment(d))return ev(d.initializer);
    return ['{'+n.name.text+'}'];
  }
  if (ts.isCallExpression(n)) {
    const name=n.expression.getText();
    if(name==='buildApiUrl')return ev(n.arguments[0]).map(s=>'/api/v1'+(s.startsWith('/')?'':'/')+s);
    if(name==='buildRootApiUrl')return ev(n.arguments[0]);
    const d=declaration(ts.isPropertyAccessExpression(n.expression)?n.expression.name:n.expression);
    const fn=d&&(ts.isVariableDeclaration(d)?d.initializer:d);
    if(fn&&(ts.isArrowFunction(fn)||ts.isFunctionDeclaration(fn))) {
      const body=fn.body;
      if(body&&!ts.isBlock(body))return ev(body);
      const returns=body?.statements?.filter(ts.isReturnStatement)||[];
      if(returns.length===1)return ev(returns[0].expression);
    }
    return ['{'+name+'}'];
  }
  return ['{dynamic}'];
}
function ownerOf(n) {
  for(let p=n.parent;p;p=p.parent) {
    if(ts.isArrowFunction(p)||ts.isFunctionExpression(p)) {
      const q=p.parent;
      if(ts.isPropertyAssignment(q)||ts.isVariableDeclaration(q)) return {name:nameOf(q.name),node:q};
    }
    if(ts.isFunctionDeclaration(p)||ts.isMethodDeclaration(p))return {name:nameOf(p.name),node:p};
  }
  return {name:'<module>',node:n.getSourceFile()};
}
const calls=[];
for(const sf of files) {
  function walk(n) {
    if(ts.isCallExpression(n)) {
      const expr=n.expression.getText();
      if(expr==='apiRequest'||expr==='fetch'||/^axios(?:\.(?:get|post|put|delete|patch))?$/.test(expr)) {
        let arg=n.arguments[0],url,method=['GET'];
        const opts=arg&&ts.isObjectLiteralExpression(arg)?arg:(expr==='fetch'?n.arguments[1]:undefined);
        if(opts&&ts.isObjectLiteralExpression(opts)) {
          for(const p of opts.properties)if(ts.isPropertyAssignment(p)) {
            if(nameOf(p.name)==='url')url=p.initializer;
            if(nameOf(p.name)==='method')method=evalText(p.initializer);
          }
        }
        if(expr==='fetch'||expr.startsWith('axios.'))url=arg;
        if(expr.startsWith('axios.'))method=[expr.split('.')[1].toUpperCase()];
        const owner=ownerOf(n);
        const usages=(reads.get(owner.name)||[]).filter(e=>!e.startsWith(path.relative(front,sf.fileName).replaceAll('\\','/')+':') || Number(e.split(':').at(-1))<sf.getLineAndCharacterOfPosition(owner.node.getStart()).line+1 || Number(e.split(':').at(-1))>sf.getLineAndCharacterOfPosition(owner.node.getEnd()).line+1);
        calls.push({frontend:evidence(n),owner:owner.name,owner_usages:[...new Set(usages)],method:method,urls:evalText(url),url_expression:url?.getText()||'',client:expr});
      }
    }
    ts.forEachChild(n,walk);
  }
  walk(sf);
}
const output=path.join(backend,'artifacts/analisis-dxncomas-20261018/frontend_llamadas.json');
fs.writeFileSync(output,JSON.stringify({entry:'src/main.tsx',reachable_files:files.map(f=>path.relative(front,f.fileName).replaceAll('\\','/')).sort(),unreachable_files:[...sources.keys()].filter(f=>!reachable.has(f)).map(f=>path.relative(front,f).replaceAll('\\','/')).sort(),calls},null,2));
console.log(JSON.stringify({reachable:files.length,unreachable:sources.size-files.length,calls:calls.length,output}));

from pathlib import Path
import sys
sys.path.insert(0, str(Path('tmp/sql-format-tools').resolve()))
import sqlparse
from sqlparse import tokens as T

root = Path('scripts/sql/kardex-dxncomas0611-20261109')
source = root / 'aplicacion'
target = root / 'sin-comentarios'
target.mkdir(exist_ok=True)

def strip_comments(text):
    out=[]; i=0; n=len(text); state='code'; depth=0
    while i<n:
        c=text[i]; pair=text[i:i+2]
        if state=='code':
            if pair=='--': out.append(' '); i+=2; state='line'; continue
            if pair=='/*': out.append(' '); i+=2; depth=1; state='block'; continue
            if c=="'": state='string'
            elif c=='"': state='quoted'
            elif c=='[': state='bracket'
            out.append(c); i+=1
        elif state=='line':
            if c in '\r\n': out.append(c); state='code'
            i+=1
        elif state=='block':
            if pair=='/*': depth+=1; i+=2
            elif pair=='*/':
                depth-=1; i+=2
                if depth==0: state='code'
            else:
                if c in '\r\n': out.append(c)
                i+=1
        else:
            out.append(c); i+=1
            end = "'" if state=='string' else '"' if state=='quoted' else ']'
            if c==end:
                if i<n and text[i]==end: out.append(text[i]); i+=1
                else: state='code'
    if state not in ('code','line'): raise ValueError(f'Unclosed {state}')
    return ''.join(out)

def significant(sql):
    return [(str(token.ttype), token.value) for stmt in sqlparse.parse(sql) for token in stmt.flatten() if token.ttype not in T.Whitespace and token.ttype not in T.Comment]

outputs=[]
for path in sorted(source.glob('*.sql')):
    clean=strip_comments(path.read_text(encoding='utf-8-sig'))
    formatted=sqlparse.format(clean, reindent=True, indent_width=4, strip_whitespace=True)
    if significant(clean) != significant(formatted): raise ValueError(f'Tokens changed in {path.name}')
    if strip_comments(formatted)!=formatted: raise ValueError(f'Comment remains in {path.name}')
    formatted=formatted.strip()+'\n'
    (target/path.name).write_text(formatted, encoding='utf-8', newline='\n')
    outputs.append(formatted)
    print(path.name, len(formatted.splitlines()), 'líneas')
if len(outputs)!=6: raise ValueError('Expected six procedures')
(target/'todos-los-procedimientos.sql').write_text('\nGO\n\n'.join(x.rstrip() for x in outputs)+'\nGO\n', encoding='utf-8', newline='\n')

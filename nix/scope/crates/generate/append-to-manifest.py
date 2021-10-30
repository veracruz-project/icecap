import sys
import json
import toml
from collections import OrderedDict

class TomlOrderedDecoder(toml.TomlPreserveCommentDecoder):

    def __init__(self):
        super(self.__class__, self).__init__(_dict=OrderedDict)


class TomlNixEncoder(toml.TomlPreserveCommentEncoder):

    def __init__(self):
        super(self.__class__, self).__init__(_dict=OrderedDict, preserve=True)

manifest = toml.load(sys.stdin, decoder=TomlOrderedDecoder())

with open(sys.argv[1]) as f:
    extra = json.load(f)

if 'features' in extra:
    if 'default' in extra['features']:
        manifest['features']['default'] = extra['features']['default']
        del extra['features']['default']
    manifest['features'].update(extra['features'])
    del extra['features']

if 'lib' in extra:
    assert extra['lib']['proc-macro'] is True # literally True
    manifest['lib']['proc-macro'] = extra['lib']['proc-macro']
    del extra['lib']['proc-macro']
    assert len(extra['lib']) == 0
    del extra['lib']

dep_tables = [
    'dependencies',
    'dev-dependencies',
    'build-dependencies',
    ]

def do_table(t_in):
    items = []
    for k, v in t_in.items():
        if not isinstance(v, str):
            d = TomlOrderedDecoder().get_empty_inline_table()
            if 'version' in v:
                d['version'] = v['version']
                del v['version']
            if 'path' in v:
                d['path'] = v['path']
                del v['path']
            d.update(v)
            v = d
        items.append((k, v))

    def is_local(v):
        return not isinstance(v, str) and 'path' in v

    def key(pair):
        return (is_local(pair[1]), pair[0])

    items.sort(key=key)
    table = TomlOrderedDecoder().get_empty_table()
    table.update(items)
    return table

for table in dep_tables:
    if table in extra:
        manifest[table] = do_table(extra[table])
        del extra[table]

if 'target' in extra:
    manifest['target'] = TomlOrderedDecoder().get_empty_table()
    for targetSpec, attrs in extra['target'].items():
        manifest['target'][targetSpec] = TomlOrderedDecoder().get_empty_table()
        for table in dep_tables:
            if table in attrs:
                manifest['target'][targetSpec][table] = do_table(attrs[table])
                del attrs[table]
        assert len(attrs) == 0
    del extra['target']

if len(extra) != 0:
    print(extra, file=sys.stderr)
    raise Exception()

toml.dump(manifest, sys.stdout, encoder=TomlNixEncoder())

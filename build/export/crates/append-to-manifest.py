import sys
import json
import toml
from collections import OrderedDict

class TomlOrderedDecoder(toml.TomlDecoder):

    def __init__(self):
        super(self.__class__, self).__init__(_dict=OrderedDict)


class TomlPreserveInlineOrderedEncoder(toml.TomlPreserveInlineDictEncoder):

    def __init__(self):
        super(self.__class__, self).__init__(_dict=OrderedDict)

manifest = toml.load(sys.stdin, decoder=TomlOrderedDecoder())

with open(sys.argv[1]) as f:
    extra = json.load(f)

# print(extra, file=sys.stderr)

for k, v in extra['depAttrs'].items():
    manifest['dependencies'][k].update(v)

if 'features' in extra['rest']:
    del extra['rest']['features']

if 'lib' in extra['rest']:
    if len(extra['rest']['lib']) != 1 or extra['rest']['lib'].get('proc-macro') != True:
        print(extra['rest'], file=sys.stderr)
        assert 0
    del extra['rest']['lib']

if 'dependencies' in extra['rest']:
    for k, v in extra['rest']['dependencies'].items():
        if not isinstance(v, str):
            del v['version']
            manifest['dependencies'][k].update(v)

    del extra['rest']['dependencies']

if len(extra['rest']) != 0:
    print(extra['rest'], file=sys.stderr)
    assert 0

toml.dump(manifest, sys.stdout, encoder=TomlPreserveInlineOrderedEncoder())

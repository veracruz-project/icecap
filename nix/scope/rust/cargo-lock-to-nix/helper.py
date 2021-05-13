import re
import sys
import toml
from collections import namedtuple

# TODO handle [[patch.unused]]

Lock = namedtuple('Lock', ['packages', 'checksums'])

Package = namedtuple('Package', ['name', 'version', 'source'])
Source = namedtuple('Source', ['type', 'value'])
Entry = namedtuple('Entry', ['package', 'dependencies', 'checksum'])
Meta = namedtuple('Meta', ['type', 'value'])
Checksum = namedtuple('Checksum', ['package', 'sha256'])

package_re = re.compile(r'(?P<name>[^ ]+)( (?P<version>[^ ]+)( \((?P<raw_source>[^ ]+)\))?)?')
source_re = re.compile(r'(?P<type>[^+]+)\+(?P<value>.+)')
git_re = re.compile(r'(?P<url>[^?]+)\?(?P<param_key>rev|branch|tag)=(?P<param_value>[^#]+)#(?P<actual_rev>[0-9a-f]{40})')

allowed_entry_keys = frozenset(('name', 'version', 'source', 'dependencies', 'checksum'))

def parse_entry(d):
    keys = frozenset(d.keys())
    if not keys.issubset(allowed_entry_keys):
        print(keys, file=sys.stderr)
    assert keys.issubset(allowed_entry_keys)
    source = None if 'source' not in keys else parse_source(d['source'])
    package = Package(d['name'], d['version'], source)
    dependencies = set()
    if 'dependencies' in keys:
        for raw_package in d['dependencies']:
            dependencies.add(parse_package(raw_package))
    checksum = d.get('checksum')
    return Entry(package, dependencies, checksum)

def parse_package(s):
    m = package_re.fullmatch(s)
    if m is None:
        print('bad', s, file=sys.stderr)
    assert m is not None
    raw_source = m['raw_source']
    source = None if raw_source is None else parse_source(raw_source)
    return Package(m['name'], m['version'], source)

def parse_source(s):
    m = source_re.fullmatch(s)
    assert m is not None
    return Source(**m.groupdict())

def parse_meta(k, v):
    type_, value = k.split(' ', 1)
    assert type_ == 'checksum'
    package = parse_package(value)
    return Meta('checksum', Checksum(package, v))

def parse_lock(d):
    packages = dict()
    checksums = dict()
    for raw_entry in d['package']:
        entry = parse_entry(raw_entry)
        packages[entry.package] = entry.dependencies
        if entry.checksum is not None:
            checksums[entry.package] = entry.checksum
    if 'metadata' in d:
        for raw_meta in d['metadata'].items():
            meta = parse_meta(*raw_meta)
            assert meta.type == 'checksum'
            checksum = meta.value
            checksums[checksum.package] = checksum.sha256
    return Lock(packages, checksums)

def emit_package(package):
    if package.source is not None:
        if package.source.type == 'registry':
            assert package.source.value == 'https://github.com/rust-lang/crates.io-index'
            yield '    "{}-{}" = fetchCratesIOCrate {{'.format(package.name, package.version)
            yield '      name = "{}";'.format(package.name)
            yield '      version = "{}";'.format(package.version)
            yield '      sha256 = "{}";'.format(lock.checksums[package])
            yield '    };'
        elif package.source.type == 'git':
            m = git_re.fullmatch(package.source.value)
            assert m is not None
            yield '    "{}-{}#{}" = fetchGitCrate {{'.format(package.name, package.version, m['actual_rev']) # HACK
            yield '      name = "{}";'.format(package.name)
            yield '      version = "{}";'.format(package.version)
            yield '      url = "{}";'.format(m['url'])
            yield '      rev = "{}";'.format(m['actual_rev'])
            yield '      param = {{ key = "{}"; value = "{}"; }};'.format(m['param_key'], m['param_value'])
            yield '    };'
        else:
            assert False

def gen_nix(lock):
    yield '{ fetchCratesIOCrate, fetchGitCrate }:'
    yield ''
    yield '{'
    yield '  source = {'
    for package in lock.packages:
        yield from emit_package(package)
    yield '  };'
    yield ''
    yield '  graph = {'
    for package, deps in lock.packages.items():
        yield '    "{}-{}" = {{'.format(package.name, package.version)
        for dep in deps:
            yield '      "{}-{}" = null;'.format(dep.name, dep.version)
        yield '    };'
    yield '  };'
    yield '}'

# with open('Cargo.lock') as f:
#     raw_lock = toml.load(f)
raw_lock = toml.load(sys.stdin)

lock = parse_lock(raw_lock)

for line in gen_nix(lock):
    print(line)

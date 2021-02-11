import os
import json
import yaml

from capdl.Object import register_object_sizes

from icedl.composition import Composition

def start():
    with open(os.environ['CONFIG']) as f:
        config = json.load(f)
    with open(config['object_sizes']) as f:
        object_sizes = yaml.load(f, Loader=yaml.FullLoader)
    register_object_sizes(object_sizes)
    return Composition(out_dir=os.environ['OUT_DIR'], config=config)

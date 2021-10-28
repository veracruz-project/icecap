#!/usr/bin/env python3

import os
import sys

icecap_root = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(icecap_root, 'build'))

import icecap_build
icecap_build.main()

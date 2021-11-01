#!/usr/bin/env python3

import os
import sys

here = os.path.dirname(os.path.abspath(__file__))
sys.path.append(here)

import icecap_build
icecap_build.main()

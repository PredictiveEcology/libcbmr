#!/bin/bash

## Use code2flow <https://github.com/scottrogowski/code2flow> to generate static call graphs

# sudo apt install graphviz -y
# pip3 install code2flow
# code2flow --help

code2flow ~/GitHub/PredictiveEcology/libcbmr/inst/python/libcbm/libcbm/input --language py --output inst/python/libcbm_input.png
code2flow ~/GitHub/PredictiveEcology/libcbmr/inst/python/libcbm/libcbm/model --language py --output inst/python/libcbm_model.png
code2flow ~/GitHub/PredictiveEcology/libcbmr/inst/python/libcbm/libcbm/storage --language py --output inst/python/libcbm_storage.png
#code2flow ~/GitHub/PredictiveEcology/libcbmr/inst/python/libcbm/libcbm/wrapper --language py --output inst/python/libcbm_wrapper.png

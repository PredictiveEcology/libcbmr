#!/bin/bash

## Use code2flow <https://github.com/scottrogowski/code2flow> to generate static call graphs

# sudo apt install graphviz -y
# pip3 install code2flow
# code2flow --help

code2flow ~/GitHub/PredictiveEcology/libcbmr/inst/python/libcbm/libcbm/input --language py --output inst/python/libcbm_call_graphs/libcbm_input.png
code2flow ~/GitHub/PredictiveEcology/libcbmr/inst/python/libcbm/libcbm/model --language py --output inst/python/libcbm_call_graphs/libcbm_model.png
code2flow ~/GitHub/PredictiveEcology/libcbmr/inst/python/libcbm/libcbm/model/cbm --language py --output inst/python/libcbm_call_graphs/libcbm_model_cbm.png
code2flow ~/GitHub/PredictiveEcology/libcbmr/inst/python/libcbm/libcbm/model/cbm_exn --language py --output inst/python/libcbm_call_graphs/libcbm_model_cbm_exn.png
code2flow ~/GitHub/PredictiveEcology/libcbmr/inst/python/libcbm/libcbm/model/model_definition --language py --output inst/python/libcbm_call_graphs/libcbm_model_model_definition.png
code2flow ~/GitHub/PredictiveEcology/libcbmr/inst/python/libcbm/libcbm/model/moss_c --language py --output inst/python/libcbm_call_graphs/libcbm_model_moss_c.png
code2flow ~/GitHub/PredictiveEcology/libcbmr/inst/python/libcbm/libcbm/storage --language py --output inst/python/libcbm_call_graphs/libcbm_storage.png
#code2flow ~/GitHub/PredictiveEcology/libcbmr/inst/python/libcbm/libcbm/wrapper --language py --output inst/python/libcbm_call_graphs/libcbm_wrapper.png

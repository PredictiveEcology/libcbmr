# libcbmr

R interface to the carbon budget model library based on CBM-CFS3 (<https://github.com/cat-cfs/libcbm_py/tree/cbm_exn>).

## R package installation

```r
remotes::install_github("PredictiveEcology/libcbmr")
```

## Python configuration and dependency installation

```r
library(reticulate)
library(libcbmr)

use_condaenv("r-reticulate")

install_libcbm()
```

## Using `libcbmr`

```r
library(reticulate)
library(libcbmr)

use_condaenv("r-reticulate")
```

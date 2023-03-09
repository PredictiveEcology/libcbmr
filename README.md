# libcbmr

R interface to the carbon budget model library based on CBM-CFS3 (<https://github.com/cat-cfs/libcbm_py/tree/cbm_exn>).

## R package installation

### local installation

```r
# install.packages("devtools")
devtools::install("~/GitHub/libcbmr") ## source package directory
```

### from GitHub

```r
# install.packages("remotes")
remotes::install_github("PredictiveEcology/libcbmr")
```

## Python configuration and dependency installation

Use **one** of the installation methods below.

1. Install using conda:

**NOTE:** the full installation path cannot contain spaces, e.g. in your Windows user name.

```r
## install python
library(reticulate)

condaVersion <- tryCatch(conda_version(conda = "auto"),
                         error = function(e) NA_character_)
if (is.na(condaVersion)) {
  reticulate::install_miniconda() ## full path cannot contain spaces!
  conda_create("r-reticulate")
}

## install libcbm (python package)
library(libcbmr)

use_condaenv("r-reticulate")

install_libcbm(method = "conda")
```

2. Install using pyenv/pyenv-win:

```r
## install python
library(reticulate)

pypath <- install_python()

envname <- "r-reticulate" ## default used by reticulate
envpath <- reticulate:::virtualenv_path(envname)
if (!dir.exists(envpath)) {
  dir.create(envpath, recursive = TRUE)
}
virtualenv_create(envname, pypath)

use_virtualenv(envname)

install_libcbm(method = "virtualenv", envname = envname)
```


## Using `libcbmr`

```r
library(reticulate)
library(libcbmr)

py_use_env(envname)
```

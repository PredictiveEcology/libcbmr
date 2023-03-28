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

## Prerequisites for users on NRCAN machines

Users on NRCAN machines may need to configure the use of the NRCAN root certificate in order to resolve SSL issues accessing HTTPS sites from R and python.

### Download NRCAN root certificate

1. Open Firefox and go to any website with https, for example <https://www.anaconda.com/>.
2. Click on the lock icon in the address bar to view the website's security certificate.
3. In the "Connection Secure" window, click on "More Information" to open the "Page Info" window.
4. In the "Page Info" window, click on the "Security" tab.
5. Click on "View Certificate" to open the "Certificate Viewer" tab.
6. Click on the "NRCAN-RootCA" tab.
7. Scroll down to the "Miscellaneous" section and select download pem (cert).
8. Save this file to a convenient location (make note of the full file path you use).

### Set the `REQUESTS_CA_BUNDLE` environment variable

Use either of the approaches below (not both) to set the variable for all R sessions or system-wide.

#### Setting for your R sessions

Use `usethis::edit_r_environ("user")` to edit your user's `.Renviron` file.

Add the following (using the actual path to the certificate file):

```
REQUESTS_CA_BUNDLE='/path/to/NRCAN-RootCA'
```

#### Setting system-wide

Setting this system-wide will affect all programs, not just R.

1. Press the Windows key and type "env" to search for the "Environment Variables" settings.
2. Create a new environment variable for your user named `REQUESTS_CA_BUNDLE` and set its value to the full file path of the certificate you downloaded.
3. Click Apply and OK to apply the changes.

## Python and `libcbmr` installation and configuration

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
envname <- "r-reticulate" ## default used by reticulate
install_libcbm(method = "conda", envname = envname)
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

library(libcbmr)
install_libcbm(method = "virtualenv", envname = envname)
```

## Using `libcbmr`

```r
library(reticulate)
library(libcbmr)

py_use_env(envname)
```

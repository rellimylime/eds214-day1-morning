## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                                                            --
## ------------------------ ENVIRONMENT INITIALIZATION---------------------------
##                                                                            --
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Vector of required packages
package_list <- c("tidyverse", "here", "lubridate", "dplyr")

# Check if package is installed and load
for (package in package_list) {
  if (!requireNamespace(package, quietly = TRUE)) {
    install.packages(package)
  }
}

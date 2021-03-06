##############################
## Interactive Exploratory Data Analysis
##
## Karl Cottenie
##
## 2019-09-30
##
##############################

library(tidyverse)
library(viridis)
# + scale_color/fill_viridis(discrete = T/F)
theme_set(theme_light())

# Startup ends here

## Comment codes ------
# Coding explanations (#, often after the code, but not exclusively)
# Code organization (## XXXXX -----)
# Justification for a section of code ## XXX
# Dead end analyses because it did not work, or not pursuing this line of inquiry (but leave it in as a trace of it, to potentially solve this issue, or avoid making the same mistake in the future # (>_<) 
# Solutions/results/interpretations (#==> XXX)
# Reference to manuscript pieces, figures, results, tables, ... # (*_*)
# TODO items #TODO
# names for data frames (dfName), for lists (lsName), for vectors (vcName) (Thanks Jacqueline May)

## Interactive EDA - Use your brain! -----
# based on https://arxiv.org/abs/1904.02101#
# cautionary tale: https://www.vox.com/future-perfect/2019/10/3/20895240/study-typo-religion-children-generosity-retraction

# install these packages if you don't have them yet
# install.packages("dataMaid")
# install.packages("janitor")
# install.packages("skimr")
# install.packages("GGally")
# install.packages("MASS")
# install.packages("devtools")
# devtools::install_github("vqv/ggbiplot")
# devtools::install_github("easystats/correlation")
# remotes::install_github("allisonhorst/palmerpenguins")

# I did not load all packages at the start, but called all functions with ::
# that way, you can just use the one function from the package w/o loading the whole package

# I recommend loading data with read_csv()

df_eda = palmerpenguins::penguins
df_eda

# Cleaning up column names
# Often columns names imported from spreadsheets don't convert well in R
# the penguins data set is already nice, so nothing happens for the example
df_eda = df_eda %>% as_tibble %>% janitor::clean_names()

# Data Description
df_eda %>% skimr::skim()

# Data validity - missing values at the data set level
df_eda %>% na.exclude() %>% skimr::skim()

df_eda %>% .[!complete.cases(.), ]

# Univariate data validity - 0s, outliers, invalid values
# outliers = Tukey boxplot outliers
df_eda %>% dataMaid::check()

df_eda %>% dataMaid::visualize()

# The line below is necessary because dataMaid outputs graphics to a new window
dev.off()

# Bivariate data validity
# If categorical variables have lots of categories, this will throw error message
# To avoid this, increase cardinality_threshold = 15 parameter
df_eda %>% GGally::ggpairs()

df_eda %>% correlation::correlation(include_factors = T, method = "auto")

df_eda %>% 
  na.exclude() %>%
  correlation::correlation(include_factors = T, method = "auto")

# Multivariate outliers = minimum covariance determinant, multivariate extension of normal distibution outliers
# https://willhipson.netlify.com/post/outliers/outliers/
# works only with quantitative data!
# df_edaQ = df_eda %>% fastDummies::dummy_cols(remove_first_dummy = T) 

df_eda_complete = df_eda %>% 
  select_if(is.numeric) %>% 
  na.exclude()

dfMVoutlier = df_eda_complete %>% 
  MASS::cov.mcd(., quantile.used = nrow(.)*.75)

dfMVoutlier = df_eda_complete %>% 
  mahalanobis(., dfMVoutlier$center, dfMVoutlier$cov)

vcMVoutlier = which(dfMVoutlier > 
                      (qchisq(p = 1 - 0.001, 
                              df = ncol(select_if(df_eda_complete, is.numeric)))))
# adjust 0.001 up/down to make the detection more/less sensitive

df_eda_complete[-vcMVoutlier, ] # w/o multivariate outliers

df_eda_complete[vcMVoutlier, ] # only multivariate outliers

# one way to plot the multivariate outliers, correlation biplot
df_eda_complete %>% 
  prcomp(center = T, scale. = T) %>% 
  ggbiplot::ggbiplot(circle = T, 
                     groups = rownames(df_eda_complete) %in% as.character(vcMVoutlier)) + 
  scale_colour_viridis(discrete = T)


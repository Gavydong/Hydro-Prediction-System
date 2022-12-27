setwd("D:/Hydro-prediction-System/ui")
Sys.setenv(TZ='America/Toronto')

source("Make_prediction.R")
source("plot_function.R")
today<-Sys.Date()
list_of_fwts<-make_prediction_testing(today,"fwts")
list_of_brts<-make_prediction_testing(today,"brts")
list_of_pats<-make_prediction_testing(today,"pats")



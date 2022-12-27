require("keras")
require("jsonlite")
require("lubridate")
require("htmlwidgets")
require("RMySQL")
require("RODBC")
require("tidyverse")
require("DMwR")
require("zoo")
require("ggplot2")
require("mailR")
require("recipes")
require("dplyr")
require("htmlwidgets")
require("Cubist")
require("caTools")
require("rpart")
require ("dplyr")
require("caret")
require("rpart.plot")
require("reticulate")
require("readr")
require("plotly")
require("stringr")
require("keras")
require("recipes")
require("xgboost")
require("h2o")
require("hrbrthemes")
require("chron")
require("Metrics")
require("scales")
if(!require(philentropy)){
  install.packages("philentropy")
  library(philentropy)
}
if(!require(webshot)){
  install.packages("webshot")
  webshot::install_phantomjs()
  library(webshot)
}
if(!require(taskscheduleR)){
  install.packages("taskscheduleR")
  library(taskscheduleR)
}
library(shiny)
library(shinydashboard)
if(!require(shinyFiles)){
  install.packages("shinyFiles")
  library(shinyFiles)
}
if(!require(reticulate)){
  install.packages("reticulate")
  library(reticulate)
}
setwd("D:/Hydro-prediction-System/ui")
Sys.setenv(TZ='America/Toronto')

data <- read.csv("total_dataset.csv", header=TRUE, sep=",", na.strings=c("NA", "NULL"),stringsAsFactors=FALSE)
data<-data[5546:nrow(data),]
scale_fwts<-scale(data$fwts)
scale_brts<-scale(data$brts)
scale_pats<-scale(data$pats)
data$fwts<-scale(data$fwts)
data$brts<-scale(data$brts)
data$pats<-scale(data$pats)


#load functions
source('Make_prediction.R')
source('Monthly.R')
source("plot_function.R")
source("Monthly_plot.R")
source("weekly.R")
source("weekly_plot.R")


#open dashboard in browser
runApp('dashboard.R', launch.browser = TRUE)

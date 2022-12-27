report_image<-function(date){
  
data <- read.csv("total_dataset.csv", header=TRUE, sep=",", na.strings=c("NA", "NULL"),stringsAsFactors=FALSE)
scale_data<-scale(data$fwts)
data$fwts<-scale(data$fwts)
source('Make_prediction.R')
source('Monthly.R')
source("plot_function.R")

battery_size<-4000
l_of_p<-make_prediction_monthly(date)
monthreport_shaved<-ifelse(!is.na(l_of_p$peak_period),l_of_p$test-battery_size,l_of_p$test)

peak_period<-l_of_p$peak_period
low_peak_period<- l_of_p$low_peak_period
normal_period<-l_of_p$normal_period

monthly<-plot_ly(
  mode = 'lines+markers'
) %>%
  add_trace(
    y =  ~ l_of_p$test,
    x =  ~ l_of_p$hours,
    mode = 'lines',
    type = 'scatter',
    name = "Test Data",
    line = list(color = ("black"))
  ) %>%
  add_trace(
    y =  ~ peak_period,
    x =  ~ l_of_p$hours,
    mode = 'lines',
    type = 'scatter',
    name = paste("Discharging Period"),
    line = list(color = 'yellow')
  ) %>%
  add_trace(
    y =  ~ low_peak_period,
    x =  ~ l_of_p$hours,
    mode = 'lines',
    type = 'scatter',
    name = paste("Charging Period"),
    line = list(color = 'blue')
  ) %>%
  add_trace(
    y =  ~ normal_period,
    x =  ~ l_of_p$hours,
    mode = 'lines',
    type = 'scatter',
    name = "Prediction",
    line = list(color = 'red')
  ) %>%
  add_trace(
    x =  ~ l_of_p$xcoord_list$test,
    y =  ~ l_of_p$ymax_list$test,
    mode = 'markers',
    type = 'scatter',
    name = paste("Highest Peak", l_of_p$ymax_list),
    marker = list(color = ("black"),size=13,symbol="triangle-up")
  )%>%
  layout(
    title = paste(strftime(as.POSIXct(l_of_p$hours[100]), format="%Y-%m-%d"),
                  "---"
                  ,strftime(as.POSIXct(l_of_p$hours[length(l_of_p$hours)]), format="%Y-%m-%d")),
    xaxis = list(
      title = 'Time',
      autotick = TRUE,
      showticklabels = TRUE
    ),
    yaxis = list(title = "Power Consumption")
  )
saveWidget(as.widget(monthly), "monthly.html")
webshot("monthly.html", "monthly.png")



monthly_shaved<-plot_ly(
  mode = 'lines+markers'
) %>%
  add_trace(
    y =  ~ monthreport_shaved,
    x =  ~ l_of_p$hours,
    mode = 'lines',
    type = 'scatter',
    name = "Shaved Data",
    line = list(color = 'red')
  ) %>%
  add_trace(
    y =  ~ l_of_p$test,
    x =  ~ l_of_p$hours,
    mode = 'lines',
    type = 'scatter',
    name = "Actual Data",
    line = list(color = ("black"))
  ) %>%
  add_trace(
    x =  ~ l_of_p$xcoord_list$test,
    y =  ~ l_of_p$ymax_list$test,
    mode = 'markers',
    type = 'scatter',
    name = paste("Acutal Peak point", l_of_p$ymax_list$test),
    marker = list(color = ("black"),size=13,symbol="triangle-up")
  ) %>%
  add_trace(
    x =  ~ l_of_p$hours[which.max(monthreport_shaved)],
    y =  ~ max(monthreport_shaved),
    mode = 'markers',
    type = 'scatter',
    name = paste("Shaved Peak point", max(monthreport_shaved)),
    marker = list(color = ("red"),size=13,symbol="triangle-up")
  ) %>%
  layout(
    title = paste(''),
    xaxis = list(
      title = 'Time',
      autotick = TRUE,
      showticklabels = TRUE
    ),
    yaxis = list(title = "Power Consumption")
  )


saveWidget(as.widget(monthly_shaved), "monthly_shaved.html")

webshot("monthly_shaved.html", "monthly_shaved.png")



highest<-l_of_p$hours[l_of_p$test==l_of_p$ymax_list]

dayreport<-make_prediction_testing(as.Date(highest))
#dayreport
#daily_plot_simple(dayreport)

gap<-25
low_peak <-
  dayreport$hours[which.min(dayreport$AVG)]


charging_range <- interval(dayreport$xcoord_list$mean_s-gap*60, dayreport$xcoord_list$mean_s+gap*60)
peak_period<-ifelse(dayreport$hours %within% charging_range , dayreport$AVG, NA)
charging_range <- interval(dayreport$xcoord_list$mean_s-gap*60+300, dayreport$xcoord_list$mean_s+gap*60-300)
#make range smaller to remove the gap between normal period and peak period

discharging_range <- interval(low_peak-gap*60, low_peak+gap*60)
low_peak_period<-ifelse(dayreport$hours %within% discharging_range , dayreport$AVG, NA)
discharging_range <- interval(low_peak-gap*60+300, low_peak+gap*60-300)


dayreport_shaved<-ifelse(dayreport$hours %within% charging_range,dayreport$test-battery_size,dayreport$test)

daily<-plot_ly(
  mode = 'lines+markers'
) %>%
  add_trace(
    y =  ~ dayreport_shaved,
    x =  ~ dayreport$hours,
    mode = 'lines',
    type = 'scatter',
    name = "Shaved Data",
    line = list(color = 'red')
  ) %>%
  add_trace(
    y =  ~ dayreport$test,
    x =  ~ dayreport$hours,
    mode = 'lines',
    type = 'scatter',
    name = "Actual Data",
    line = list(color = ("black"))
  ) %>%
  add_trace(
    x =  ~ dayreport$xcoord_list$test,
    y =  ~ dayreport$ymax_list$test,
    mode = 'markers',
    type = 'scatter',
    name = paste("Actual Peak point", dayreport$ymax_list$test),
    marker = list(color = ("black"),size=13,symbol="triangle-up")
  ) %>%
  add_trace(
    x =  ~ dayreport$hours[which.max(dayreport_shaved)],
    y =  ~ max(dayreport_shaved),
    mode = 'markers',
    type = 'scatter',
    name = paste("Shaved Peak point", max(dayreport_shaved)),
    marker = list(color = ("red"),size=13,symbol="triangle-up")
  ) %>%
  layout(
    title = paste(strftime(as.POSIXct(dayreport$hours[100]), format="%Y-%m-%d")),
    xaxis = list(
      title = 'Time',
      autotick = TRUE,
      showticklabels = TRUE
    ),
    yaxis = list(title = "Power Consumption")
  )
saveWidget(as.widget(daily), "daily.html")
webshot("daily.html", "daily.png")

model_performance<-daily_plot(dayreport)
saveWidget(as.widget(model_performance), "model_performance.html")
webshot("model_performance.html", "model_performance.png")








for(i in 1:5){
  temp<-daily_plot_simple(dayreport)
  
  l_of_p$test[as.Date(l_of_p$hours)==as.Date(highest)]<-0 #Delete highest peak day test data
  highest<-l_of_p$hours[which.max(l_of_p$test)]     #calculate new highest
  dayreport<-make_prediction_testing(as.Date(highest))
  
  saveWidget(as.widget(temp), paste("day",i,".html",sep = ''))
  webshot(paste("day",i,".html",sep = ''), paste("day",i,".png",sep = ''))
}



}
library(lubridate)


daily_plot<-function(list_of_predictions){
  
  pl <-
    plot_ly(
      mode = 'lines+markers'
    ) %>%
    add_trace(
      y =  ~ list_of_predictions$cubist,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "Cubist",
      line = list(color = 'rgb(255, 215, 0)')
    ) %>%
    add_trace(
      y =  ~ list_of_predictions$xgboost,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "XGBoost",
      line = list(color = ("blue"))
    ) %>%
    add_trace(
      y =  ~ list_of_predictions$NN,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "NN",
      line = list(color = ("pink"))
    ) %>%
    
    add_trace(
      y =  ~ list_of_predictions$RF,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "Random Forest",
      line = list(color = ("green"))
    ) %>%
    
    add_trace(
      y =  ~ list_of_predictions$LSTM,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "LSTM",
      line = list(color = ("purple"))
    ) %>%
    add_trace(
      y =  ~ list_of_predictions$AVG,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "Ensemble",
      line = list(color = 'red')
    ) %>%
    add_trace(
      y =  ~ list_of_predictions$test,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "Test Data",
      line = list(color = ("black"))
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$cubist,
      y =  ~ list_of_predictions$ymax_list$cubist,
      mode = 'markers',
      type = 'scatter',
      name = paste("Cubist Predicted Peak", strftime(list_of_predictions$xcoord_list$cubist,format="%H:%M",tz="UTC")),
      marker = list(color = ("black"),size=9,symbol="circle")
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$xgboost,
      y =  ~ list_of_predictions$ymax_list$xgboost,
      mode = 'markers',
      type = 'scatter',
      name = paste("XGBoost Predicted Peak",strftime(list_of_predictions$xcoord_list$xgboost,format="%H:%M",tz="UTC")),
      marker = list(color = ("black"),size=9,symbol="circle")
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$NN,
      y =  ~ list_of_predictions$ymax_list$NN,
      mode = 'markers',
      type = 'scatter',
      name = paste("NN Predicted Peak",strftime(list_of_predictions$xcoord_list$NN,format="%H:%M",tz="UTC")),
      marker = list(color = ("black"),size=9,symbol="circle")
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$RF,
      y =  ~ list_of_predictions$ymax_list$RF,
      mode = 'markers',
      type = 'scatter',
      name = paste("Random Forest Predicted Peak",strftime(list_of_predictions$xcoord_list$RF,format="%H:%M",tz="UTC")),
      marker = list(color = ("black"),size=9,symbol="circle")
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$LSTM,
      y =  ~ list_of_predictions$ymax_list$LSTM,
      mode = 'markers',
      type = 'scatter',
      name = paste("LSTM Predicted Peak",strftime(list_of_predictions$xcoord_list$LSTM,format="%H:%M",tz="UTC")),
      marker = list(color = ("black"),size=9,symbol="circle")
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$AVG,
      y =  ~ list_of_predictions$ymax_list$AVG,
      mode = 'markers',
      type = 'scatter',
      name = paste("Ensemble Predicted Peak", strftime(list_of_predictions$xcoord_list$AVG,format="%H:%M",tz="UTC")),
      marker = list(color = ("black"),size=9,symbol="circle")
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$test,
      y =  ~ list_of_predictions$ymax_list$test,
      mode = 'markers',
      type = 'scatter',
      name = paste("Real Peak", strftime(list_of_predictions$xcoord_list$test,format="%H:%M",tz="UTC")),
      marker = list(color = ("red"),size=13,symbol="triangle-up")
    )  %>%
#    add_trace(
#      x =  ~ list_of_predictions$xcoord_list$mean_s,
#      y =  ~ list_of_predictions$ymax_list$test + 2000,
#      mode = 'markers',
#      type = 'scatter',
#      name = paste("Mean",strftime(list_of_predictions$xcoord_list$mean_s,format="%H:%M",tz="UTC")),
#      marker = list(color = 'rgb(0, 191, 255)',size=9,symbol="square")
#    ) %>%
    layout(
      #title = paste(strftime(as.POSIXct(list_of_predictions$hours[100]), format="%Y-%m-%d")),
      xaxis = list(
        title = 'Time',
        autotick = TRUE,
        showticklabels = TRUE
      ),
      yaxis = list(title = "Power Consumption")
    )
  
  pl
  
  
  return(pl)
}






library(lubridate)


daily_plot_simple<-function(list_of_predictions){
  gap<-25
  low_peak <-
    list_of_predictions$hours[which.min(list_of_predictions$AVG)]
  
  
  charging_range <- interval(list_of_predictions$xcoord_list$mean_s-gap*60, list_of_predictions$xcoord_list$mean_s+gap*60)
  peak_period<-ifelse(list_of_predictions$hours %within% charging_range , list_of_predictions$AVG, NA)
  charging_range <- interval(list_of_predictions$xcoord_list$mean_s-gap*60+300, list_of_predictions$xcoord_list$mean_s+gap*60-300)
  #make range smaller to remove the gap between normal period and peak period
  
  discharging_range <- interval(low_peak-gap*60, low_peak+gap*60)
  low_peak_period<-ifelse(list_of_predictions$hours %within% discharging_range , list_of_predictions$AVG, NA)
  discharging_range <- interval(low_peak-gap*60+300, low_peak+gap*60-300)
  
  
  
  normal_period<-ifelse((!(list_of_predictions$hours %within% charging_range))&(!(list_of_predictions$hours %within% discharging_range)) , list_of_predictions$AVG, NA)
  
  pl <-
    plot_ly(
      mode = 'lines+markers'
    ) %>%
    add_trace(
      y =  ~ list_of_predictions$test,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "Test Data",
      line = list(color = ("black"))
    ) %>%
    add_trace(
      y =  ~ peak_period,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = paste("Discharging Period"),
      line = list(color = 'yellow')
    ) %>%
    add_trace(
      y =  ~ low_peak_period,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = paste("Charging Period"),
      line = list(color = 'blue')
    ) %>%
    add_trace(
      y =  ~ normal_period,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "Prediction",
      line = list(color = 'red')
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$AVG,
      y =  ~ list_of_predictions$ymax_list$AVG,
      mode = 'markers',
      type = 'scatter',
      name = paste("Predicted Peak", strftime(list_of_predictions$xcoord_list$AVG,format="%H:%M",tz="UTC")),
      marker = list(color = ("yellow"),size=9,symbol="circle")
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$test,
      y =  ~ list_of_predictions$ymax_list$test,
      mode = 'markers',
      type = 'scatter',
      name = paste("Real Peak", strftime(list_of_predictions$xcoord_list$test,format="%H:%M",tz="UTC")),
      marker = list(color = ("black"),size=13,symbol="triangle-up")
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$mean_s,
      y =  ~ list_of_predictions$ymax_list$test + 2000,
      mode = 'markers',
      type = 'scatter',
      name = paste("Mean of predicted peak time",strftime(list_of_predictions$xcoord_list$mean_s,format="%H:%M",tz="UTC")),
      marker = list(color = 'rgb(0, 191, 255)',size=9,symbol="square")
    ) %>%
    layout(
      title = paste(strftime(as.POSIXct(list_of_predictions$hours[100]), format="%Y-%m-%d")),
      xaxis = list(
        title = 'Time',
        autotick = TRUE,
        showticklabels = TRUE
      ),
      yaxis = list(title = "Power Consumption")
    )
  
  pl
  
  
  return(pl)
}








daily_plot_s<-function(list_of_predictions){
  
  pl <-
    plot_ly(
      mode = 'lines+markers'
    ) %>%
    add_trace(
      y =  ~ list_of_predictions$test,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "Test Data",
      line = list(color = ("black"))
    ) %>%
    add_trace(
      y =  ~ list_of_predictions$AVG,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "Prediction",
      line = list(color = 'red')
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$AVG,
      y =  ~ list_of_predictions$ymax_list$AVG,
      mode = 'markers',
      type = 'scatter',
      name = paste("Predicted Peak", strftime(list_of_predictions$xcoord_list$AVG,format="%H:%M",tz="UTC")),
      marker = list(color = ("red"),size=9,symbol="circle")
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$test,
      y =  ~ list_of_predictions$ymax_list$test,
      mode = 'markers',
      type = 'scatter',
      name = paste("Real Peak", strftime(list_of_predictions$xcoord_list$test,format="%H:%M",tz="UTC")),
      marker = list(color = ("black"),size=13,symbol="triangle-up")
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$mean,
      y =  ~ list_of_predictions$ymax_list$test + 2000,
      mode = 'markers',
      type = 'scatter',
      name = paste("Mean of predicted peak time",strftime(list_of_predictions$xcoord_list$mean,format="%H:%M",tz="UTC")),
      marker = list(color = 'rgb(0, 191, 255)',size=9,symbol="square")
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
  
  pl
  
  
  return(pl)
}

daily_plot_peak_enhancement<-function(list_of_predictions,gap){
  range <- interval(list_of_predictions$xcoord_list$AVG-gap*60, list_of_predictions$xcoord_list$AVG+gap*60)
  peak_period<-ifelse(list_of_predictions$hours %within% range , list_of_predictions$AVG, NA)
  range <- interval(list_of_predictions$xcoord_list$AVG-gap*60+300, list_of_predictions$xcoord_list$AVG+gap*60-300)
  #make range smaller to remove the gap between normal period and peak period
  normal_period<-ifelse(!(list_of_predictions$hours %within% range) , list_of_predictions$AVG, NA)
  
  
  pl <-
    plot_ly(
      mode = 'lines+markers'
    ) %>%
    add_trace(
      y =  ~ list_of_predictions$test,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "Test Data",
      line = list(color = ("black"))
    ) %>%
    add_trace(
      y =  ~ peak_period,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "Confident Interval",
      line = list(color = 'red')
    ) %>%
    add_trace(
      y =  ~ normal_period,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "Prediction",
      line = list(color = '#FECB52')
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$AVG,
      y =  ~ list_of_predictions$ymax_list$AVG,
      mode = 'markers',
      type = 'scatter',
      name = paste("Predicted Peak", strftime(list_of_predictions$xcoord_list$AVG,format="%H:%M",tz="UTC")),
      marker = list(color = ("red"),size=9,symbol="circle")
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$test,
      y =  ~ list_of_predictions$ymax_list$test,
      mode = 'markers',
      type = 'scatter',
      name = paste("Real Peak", strftime(list_of_predictions$xcoord_list$test,format="%H:%M",tz="UTC")),
      marker = list(color = ("black"),size=13,symbol="triangle-up")
    ) %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$mean,
      y =  ~ list_of_predictions$ymax_list$test + 2000,
      mode = 'markers',
      type = 'scatter',
      name = paste("Mean of predicted peak time",strftime(list_of_predictions$xcoord_list$mean,format="%H:%M",tz="UTC")),
      marker = list(color = 'rgb(0, 191, 255)',size=9,symbol="square")
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
  
  pl
  
  
  return(pl)
}



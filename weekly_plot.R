weekly_plot<-function(list_of_predictions){
  
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
    )%>%
    add_trace(
      y =  ~ list_of_predictions$AVG,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "AVG",
      line = list(color = 'red')
    ) %>%
    add_trace(
      y =  ~ list_of_predictions$test,
      x =  ~ list_of_predictions$hours,
      mode = 'lines',
      type = 'scatter',
      name = "Test Data",
      line = list(color = ("black"))
    )  %>%
    add_trace(
      x =  ~ list_of_predictions$xcoord_list$test,
      y =  ~ list_of_predictions$ymax_list$test,
      mode = 'markers',
      type = 'scatter',
      name = paste("Highest Peak", strftime(list_of_predictions$xcoord_list$test,format="%H:%M",tz="UTC")),
      marker = list(color = ("red"),size=13,symbol="triangle-up")
    )  %>%
    layout(
      title = paste(strftime(as.POSIXct(list_of_predictions$hours[100]), format="%Y-%m-%d"),
                    "---"
                    ,strftime(as.POSIXct(list_of_predictions$hours[length(list_of_predictions$hours)]), format="%Y-%m-%d")),
      
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


weekly_plot_simple<-function(list_of_predictions){
 
  peak_period<-list_of_predictions$peak_period
  low_peak_period<- list_of_predictions$low_peak_period
  normal_period<-list_of_predictions$normal_period
    
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
      x =  ~ list_of_predictions$xcoord_list$test,
      y =  ~ list_of_predictions$ymax_list$test,
      mode = 'markers',
      type = 'scatter',
      name = paste("Highest Peak", strftime(list_of_predictions$xcoord_list$test,format="%H:%M",tz="UTC")),
      marker = list(color = ("black"),size=13,symbol="triangle-up")
    )%>%
    layout(
      title = paste(strftime(as.POSIXct(list_of_predictions$hours[100]), format="%Y-%m-%d"),
                    "---"
                    ,strftime(as.POSIXct(list_of_predictions$hours[length(list_of_predictions$hours)]), format="%Y-%m-%d")),
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

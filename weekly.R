make_prediction_weekly<-function(date,location){
  date_temp<-as.Date(date)-6
  list_of_prediction<-make_prediction_testing(date_temp,location)
  hour<-list_of_prediction$hours
  RF<-list_of_prediction$RF
  NN<-list_of_prediction$NN
  xgboost<-list_of_prediction$xgboost
  cubist<-list_of_prediction$cubist
  LSTM<-list_of_prediction$LSTM
  test<-list_of_prediction$test
  AVG<-list_of_prediction$AVG
  
  
  error<-abs(list_of_prediction$results$Peak_dif_mean_s)

  
  
  gap<-40
  low_peak <-
    list_of_prediction$hours[which.min(list_of_prediction$AVG)]
  
  
  charging_range <- interval(list_of_prediction$xcoord_list$mean_s-gap*60, list_of_prediction$xcoord_list$mean_s+gap*60)
  peak_period<-ifelse(list_of_prediction$hours %within% charging_range , list_of_prediction$AVG, NA)
  charging_range <- interval(list_of_prediction$xcoord_list$mean_s-gap*60+300, list_of_prediction$xcoord_list$mean_s+gap*60-300)
  #make range smaller to remove the gap between normal period and peak period
  
  discharging_range <- interval(low_peak-gap*60, low_peak+gap*60)
  low_peak_period<-ifelse(list_of_prediction$hours %within% discharging_range , list_of_prediction$AVG, NA)
  discharging_range <- interval(low_peak-gap*60+300, low_peak+gap*60-300)
  
  normal_period<-ifelse((!(list_of_prediction$hours %within% charging_range))&(!(list_of_prediction$hours %within% discharging_range)) , list_of_prediction$AVG, NA)
  
  
  
while(date_temp<date){
  date_temp<-date_temp+1
  list_of_prediction<-make_prediction_testing(date_temp,location)
  hour<-c(hour,list_of_prediction$hours)
  RF<-c(RF,list_of_prediction$RF)
  NN<-c(NN,list_of_prediction$NN)
  xgboost<-c(xgboost,list_of_prediction$xgboost)
  cubist<-c(cubist,list_of_prediction$cubist)
  LSTM<-c(LSTM,list_of_prediction$LSTM)

  test<-c(test,list_of_prediction$test)
  AVG<-c(AVG,list_of_prediction$AVG)
  error<-c(error,abs(list_of_prediction$results$Peak_dif_mean_s))
  
  
  low_peak <-
    list_of_prediction$hours[which.min(list_of_prediction$AVG)]
  
  
  charging_range <- interval(list_of_prediction$xcoord_list$mean_s-gap*60, list_of_prediction$xcoord_list$mean_s+gap*60)
  peak_period<-c(peak_period,ifelse(list_of_prediction$hours %within% charging_range , list_of_prediction$AVG, NA))
  charging_range <- interval(list_of_prediction$xcoord_list$mean_s-gap*60+300, list_of_prediction$xcoord_list$mean_s+gap*60-300)
  #make range smaller to remove the gap between normal period and peak period
  
  discharging_range <- interval(low_peak-gap*60, low_peak+gap*60)
  low_peak_period<-c(low_peak_period,ifelse(list_of_prediction$hours %within% discharging_range , list_of_prediction$AVG, NA))
  discharging_range <- interval(low_peak-gap*60+300, low_peak+gap*60-300)
  
  normal_period<-c(normal_period,ifelse((!(list_of_prediction$hours %within% charging_range))&(!(list_of_prediction$hours %within% discharging_range)) , list_of_prediction$AVG, NA))
  
  
} 
  

  
  #Test data peak
  ymax_test_pred = max(test)
  xcoord_test_pred <-
    hour[which.max(test)]
  
  xcoord_list<-list("test"=xcoord_test_pred)
  ymax_list<-list("test"=ymax_test_pred)
  results<-data.frame(mean(error))
  colnames(results)<- c("Peak_dif_mean_s")
  list_of_prediction<-list("hours"=hour,"test"=test,"cubist"= cubist,
                           "xgboost"=xgboost,
                           "RF"=RF,"NN"=NN,"LSTM"=LSTM,"AVG"=AVG,
                           "peak_period"=peak_period,
                           "low_peak_period"=low_peak_period,
                           "normal_period"=normal_period,
                           "xcoord_list"=xcoord_list, "ymax_list"=ymax_list,"results"=results)
  
  return(list_of_prediction)
}


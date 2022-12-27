make_prediction_testing<-function(date,location){
  
predictionDate <- as.Date(date)
filename<-paste("past_report_",location,".csv",sep="")
past_report<- read.csv(filename, header=TRUE,check.names=TRUE, sep=",", na.strings=c("NA", "NULL"),stringsAsFactors=FALSE)
if(sum(format(as.Date(past_report$hours),"%Y-%m-%d")== date)>0){
  if(predictionDate!=Sys.Date()-1&&mean(is.na(past_report$test[format(as.Date(past_report$hours),"%Y-%m-%d")== predictionDate]))){
    if(location=="fwts"){
      test<-data$fwts[!duplicated(data$datetime)&data$date==predictionDate]
    }else if(location=="brts"){
      test<-data$brts[!duplicated(data$datetime)&data$date==predictionDate]
    }else if(location=="pats"){
      test<-data$pats[!duplicated(data$datetime)&data$date==predictionDate]
    }
    while(length(test)<288){
      test<-append(test[1],test)
    }
    past_report$test[format(as.Date(past_report$hours),"%Y-%m-%d")== predictionDate]<-test
    write.csv(x=past_report, file=filename,row.names=FALSE)
  }
  
  report_day<-past_report[format(as.Date(past_report$hours),"%Y-%m-%d")== date,]
  
  prediction_cubist<-report_day$cubist
  prediction_xgboost<-report_day$xgboost
  prediction_RF<-report_day$RF
  prediction_NN<-report_day$NN
  prediction_LSTM<-report_day$LSTM
    
  testing<-report_day$test
  
  
  
  datetimes <-seq(ymd_hm(paste(predictionDate, "00:00")),
                  ymd_hm(paste(predictionDate, "23:55")), 
                  by = "5 min")
  
  ##################################### Find peak values  ######################################
  
  
  #Cubist Predicted Daily Peak
  peak_start<-180
  ymax_cubist_pred = max(prediction_cubist[peak_start:288])
  xcoord_cubist_pred <-
    datetimes[which.max(prediction_cubist[peak_start:288]) + peak_start-1]
  
  #XGBoost Predicted Daily Peak
  ymax_xgboost_pred = max(prediction_xgboost[peak_start:288])
  xcoord_xgboost_pred <-
    datetimes[which.max(as.vector(prediction_xgboost[peak_start:288])) + peak_start-1]
  
  #Random Forest Predicted Daily Peak
  ymax_RF_pred = max(prediction_RF[peak_start:288])
  xcoord_RF_pred <-
    datetimes[which.max(prediction_RF[peak_start:288]) + peak_start-1]
  #NN Predicted Daily Peak
  ymax_NN_pred = max(prediction_NN[peak_start:288])
  xcoord_NN_pred <-
    datetimes[which.max(prediction_NN[peak_start:288]) + peak_start-1]
  
  #LSTM Predicted Daily Peak
  ymax_LSTM_pred = max(prediction_LSTM[peak_start:288])
  xcoord_LSTM_pred <-
    datetimes[which.max(prediction_LSTM[peak_start:288]) + peak_start-1]
  
  #Test data peak
  ymax_test_pred = max(testing[peak_start:288])
  xcoord_test_pred <-
    mean(datetimes[testing==ymax_test_pred])
  
  
  ####################################Change average here after add new algorithm###################################
  #Avg of all peak times
  prediction_avg = (prediction_xgboost + prediction_cubist  +
                      prediction_RF+prediction_NN+prediction_LSTM) / 5
  
  
  ymax_avg_pred = max(prediction_avg[peak_start:288])
  xcoord_avg_pred <-
    datetimes[which.max(prediction_avg[peak_start:288]) + peak_start-1]
  
  ###############################mean_s kick one out if too far from each other#########################
  
  mean_all<-mean(c(xcoord_cubist_pred,xcoord_xgboost_pred,xcoord_NN_pred,xcoord_RF_pred,xcoord_avg_pred,xcoord_LSTM_pred))
  differ_cubist<-abs(difftime(xcoord_cubist_pred,mean_all, units = "mins"))
  differ_xgboost<-abs(difftime(xcoord_xgboost_pred,mean_all, units = "mins"))
  differ_NN<-abs(difftime(xcoord_NN_pred,mean_all, units = "mins"))
  differ_RF<-abs(difftime(xcoord_RF_pred,mean_all, units = "mins"))
  differ_LSTM<-abs(difftime(xcoord_LSTM_pred,mean_all, units = "mins"))
  differ_AVG<-abs(difftime(xcoord_avg_pred,mean_all, units = "mins"))
  temp_list<-c(xcoord_cubist_pred,xcoord_xgboost_pred,xcoord_NN_pred,xcoord_RF_pred,xcoord_LSTM_pred,xcoord_avg_pred)
  differ_list<-c(differ_cubist,differ_xgboost,differ_NN,differ_RF,differ_LSTM,differ_AVG)
  mean_s<-mean_all
  if(max(differ_list)>60){
    cut<-which.max(differ_list)
    mean_s<-mean(temp_list[-cut])
  }
  
  ######################################################
  
  
  #lists
  xcoord_list<-list("test"=xcoord_test_pred, "cubist"=xcoord_cubist_pred, "xgboost"=xcoord_xgboost_pred, 
                    "RF"=xcoord_RF_pred,"NN"=xcoord_NN_pred,"LSTM"=xcoord_LSTM_pred,"AVG"=xcoord_avg_pred,
                    "mean"=mean_all,
                    "mean_s"=mean_s)
  
  ymax_list<-list("test"=ymax_test_pred, "cubist"=ymax_cubist_pred, "xgboost"=ymax_xgboost_pred,
                  "RF"=ymax_RF_pred,"NN"=ymax_NN_pred,"LSTM"=ymax_LSTM_pred,"AVG"=ymax_avg_pred)
  
  list_of_prediction<-list("hours"=datetimes,"test"=testing,"cubist"= prediction_cubist,
                           "xgboost"=prediction_xgboost,
                           "RF"=prediction_RF,"NN"=prediction_NN,"LSTM"=prediction_LSTM,"AVG"=prediction_avg,"xcoord_list"=xcoord_list,
                           "ymax_list"=ymax_list)
  
  results<-data.frame(as.character(date),rmse(list_of_prediction$test[156:288],list_of_prediction$cubist[156:288])/mean(list_of_prediction$test),
                      rmse(list_of_prediction$test[156:288],list_of_prediction$xgboost[156:288])/mean(list_of_prediction$test),
                      rmse(list_of_prediction$test[156:288],list_of_prediction$RF[156:288])/mean(list_of_prediction$test),
                      rmse(list_of_prediction$test[156:288],list_of_prediction$NN[156:288])/mean(list_of_prediction$test),
                      rmse(list_of_prediction$test[156:288],list_of_prediction$LSTM[156:288])/mean(list_of_prediction$test),
                      rmse(list_of_prediction$test[156:288],list_of_prediction$AVG[156:288])/mean(list_of_prediction$test),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$cubist, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$xgboost, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$RF, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$NN, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$LSTM, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$AVG, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$mean, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$mean_s, units = "mins")))
  colnames(results)<- c("datetime","RMSE_cubist","RMSE_xgboost","RMSE_RF","RMSE_NN","RMSE_LSTM","RMSE_AVG","Peak_dif_cubist","Peak_dif_xgboost","Peak_dif_RF","Peak_dif_NN","Peak_dif_LSTM","Peak_dif_AVG","Peak_dif_mean","Peak_dif_mean_s")
  
  list_of_prediction<-list("hours"=datetimes,"test"=testing,"cubist"= prediction_cubist,
                           "xgboost"=prediction_xgboost,
                           "RF"=prediction_RF,"NN"=prediction_NN,"LSTM"=prediction_LSTM,"AVG"=prediction_avg,
                           "xcoord_list"=xcoord_list, "ymax_list"=ymax_list,"results"=results)
}else{
  list_of_prediction<-make_prediction(date,location)
  report<-list_of_prediction[1:8]
  report$hours<-as.character(report$hours)
  report<-rbind(past_report,report)
  report<-report[order(as_datetime(report$hours)),]
  write.csv(x=report, file=filename,row.names=FALSE)
  if(date!=Sys.Date()){
    {
      pl<-daily_plot_simple(list_of_prediction)
      pl
      htmlwidgets::saveWidget(as_widget(pl), paste("D:/Hydro-prediction-System/ui/",location,"_dailyreport/",predictionDate,".html",sep=''))
    }
  }
}




return(list_of_prediction)
}








############################################################################################################################################################

make_prediction<-function(date,location){
  h2o.init()
  
  predictionDate <- as.Date(date)
  num_of_day<-30
  
  weatherinfo <- read.csv("past_weather.csv", header=TRUE,check.names=TRUE, sep=",", na.strings=c("NA", "NULL"),stringsAsFactors=FALSE)
  weatherinfo$datetime<-as.POSIXct(weatherinfo$datetime,tz="America/Toronto",
                                   origin = "1970-01-01")
  for(i in num_of_day:0){
    #print(predictionDate-i)
    #print(!sum(weatherinfo$datetime==predictionDate-i))
    if(!sum(weatherinfo$datetime==predictionDate-i))
    {
      str_Date <- paste(predictionDate-i, "T", "00:00:00", sep = "")
      url <-
        paste(
          "https://api.darksky.net/forecast/4d35c6b380b2884f29fc75db08ae7e83/48.3809,-89.2477,",
          str_Date,
          "?units=ca&exclude=alerts,minutely,daily,flags,currently",
          sep = ""
        )
      darksky_df <-
        data.frame(fromJSON(url, simplifyDataFrame = TRUE))
      darksky_df$hourly.data.time<-as.POSIXct(darksky_df$hourly.data.time,tz="America/Toronto",
                                              origin = "1970-01-01")
      if(nrow(darksky_df)<24){
        while(nrow(darksky_df)<24){
          darksky_df<-rbind(darksky_df[1,],darksky_df)
        }
        darksky_df$hourly.data.time[1]<-paste(as.Date(darksky_df$hourly.data.time[1]),"00:00:00")
        darksky_df$hourly.data.time[2]<-paste(as.Date(darksky_df$hourly.data.time[1]),"01:00:00")
        darksky_df$hourly.data.time[3]<-paste(as.Date(darksky_df$hourly.data.time[1]),"02:00:00")
        darksky_df$hourly.data.time[4]<-paste(as.Date(darksky_df$hourly.data.time[1]),"03:00:00")
        darksky_df$hourly.data.time[5]<-paste(as.Date(darksky_df$hourly.data.time[1]),"04:00:00")
        darksky_df$hourly.data.time[6]<-paste(as.Date(darksky_df$hourly.data.time[1]),"05:00:00")
        darksky_df$hourly.data.time[7]<-paste(as.Date(darksky_df$hourly.data.time[1]),"06:00:00")
        darksky_df$hourly.data.time[8]<-paste(as.Date(darksky_df$hourly.data.time[1]),"07:00:00")
        darksky_df$hourly.data.time[9]<-paste(as.Date(darksky_df$hourly.data.time[1]),"08:00:00")
        darksky_df$hourly.data.time[10]<-paste(as.Date(darksky_df$hourly.data.time[1]),"09:00:00")
        darksky_df$hourly.data.time[11]<-paste(as.Date(darksky_df$hourly.data.time[1]),"10:00:00")
        darksky_df$hourly.data.time[12]<-paste(as.Date(darksky_df$hourly.data.time[1]),"11:00:00")
        darksky_df$hourly.data.time[13]<-paste(as.Date(darksky_df$hourly.data.time[1]),"12:00:00")
        darksky_df$hourly.data.time[14]<-paste(as.Date(darksky_df$hourly.data.time[1]),"13:00:00")
        darksky_df$hourly.data.time[15]<-paste(as.Date(darksky_df$hourly.data.time[1]),"14:00:00")
        darksky_df$hourly.data.time[16]<-paste(as.Date(darksky_df$hourly.data.time[1]),"15:00:00")
        darksky_df$hourly.data.time[17]<-paste(as.Date(darksky_df$hourly.data.time[1]),"16:00:00")
        darksky_df$hourly.data.time[18]<-paste(as.Date(darksky_df$hourly.data.time[1]),"17:00:00")
        darksky_df$hourly.data.time[19]<-paste(as.Date(darksky_df$hourly.data.time[1]),"18:00:00")
        darksky_df$hourly.data.time[20]<-paste(as.Date(darksky_df$hourly.data.time[1]),"19:00:00")
        darksky_df$hourly.data.time[21]<-paste(as.Date(darksky_df$hourly.data.time[1]),"20:00:00")
        darksky_df$hourly.data.time[22]<-paste(as.Date(darksky_df$hourly.data.time[1]),"21:00:00")
        darksky_df$hourly.data.time[23]<-paste(as.Date(darksky_df$hourly.data.time[1]),"22:00:00")
        darksky_df$hourly.data.time[24]<-paste(as.Date(darksky_df$hourly.data.time[1]),"23:00:00")
      }
      data_set <-
        data.frame(matrix(ncol = 24, nrow = (
          nrow(darksky_df)
        )))
      
      columns = c(
        "datetime",
        "time",
        "fwts",
        "fwts_lag",
        "brts",
        "brts_lag",
        "pats",
        "pats_lag",
        "ssm",
        "sint",
        "cost",
        "temp",
        "dew",
        "hum",
        "wspd",
        "pres",
        "vis",
        "mon",
        "tue",
        "wed",
        "thu",
        "fri",
        "sat",
        "sun"
      )
      colnames(data_set) <- columns
      data_set$datetime <-
        as.POSIXct(darksky_df$hourly.data.time,
                   origin = "1970-01-01")
      data_set$temp <-
        darksky_df$hourly.data.temperature #as degress celcius
      data_set$dew <-
        darksky_df$hourly.data.dewPoint #as degrees celcius
      data_set$hum <-
        darksky_df$hourly.data.humidity #as decimal fraction
      data_set$pres <-
        darksky_df$hourly.data.pressure/10 #as hectopascals
      data_set$vis <- darksky_df$hourly.data.visibility #in kilometers
      data_set$wspd <-
        darksky_df$hourly.data.windSpeed #as kilometers per hour
      
      
      
      #****Create a dataframe with all possible date/times at interval of 5 mins*****#
      dateRange <-
        data.frame(datetime = seq(min(data_set$datetime), max(data_set$datetime) + 3540, by = 5 *
                                    60))
      
      #*******************Right Join dateRange dataframe********************#
      data_set <- data_set %>%
        right_join(dateRange, by = "datetime") %>%
        fill(temp, dew, hum, pres, wspd, vis)
      
      #*********************Fill Time Column******************************#
      data_set$time <- strftime(data_set$datetime, format = "%H:%M:%S")
      
      
      
      #Transform Time into Sine & Cosine
      seconds_in_day <- 24 * 60 * 60
      data_set$ssm <-
        (as.numeric(as.POSIXct(strptime(data_set$time, format = "%H:%M:%S"))) -  as.numeric(as.POSIXct(strptime("0", format = "%S"))))
      data_set$sint <- sin(2 * pi * data_set$ssm / seconds_in_day)
      data_set$cost <- cos(2 * pi * data_set$ssm / seconds_in_day)
      
      
      #Prefill Days of Week Columns to 0
      data_set$mon <- rep(0, nrow(data_set))
      data_set$tue <- rep(0, nrow(data_set))
      data_set$wed <- rep(0, nrow(data_set))
      data_set$thu <- rep(0, nrow(data_set))
      data_set$fri <- rep(0, nrow(data_set))
      data_set$sat <- rep(0, nrow(data_set))
      data_set$sun <- rep(0, nrow(data_set))
      
      
      
      # #Iterate through all rows setting appropriate weekday to 1
      for (j in 1:nrow(data_set)) {
        weekday <- weekdays(data_set$datetime[j])
        if (weekday == "Monday") {
          data_set$mon[j] <- 1
        }
        if (weekday == "Tuesday") {
          data_set$tue[j] <- 1
        }
        if (weekday == "Wednesday") {
          data_set$wed[j] <- 1
        }
        if (weekday == "Thursday") {
          data_set$thu[j] <- 1
        }
        if (weekday == "Friday") {
          data_set$fri[j] <- 1
        }
        if (weekday == "Saturday") {
          data_set$sat[j] <- 1
        }
        if (weekday == "Sunday") {
          data_set$sun[j] <- 1
        }
        
      }
      data_set$datetime<-as.character(data_set$datetime)
      weatherinfo<-rbind(weatherinfo,data_set)
      weatherinfo<-weatherinfo[order(as_datetime(weatherinfo$datetime)),]
    }
  }
  
  
  write.csv(x=weatherinfo, file="past_weather.csv",row.names=FALSE)
  
  ######################
  
  data_set<-weatherinfo[(weatherinfo$datetime>=(predictionDate-num_of_day)&weatherinfo$datetime<predictionDate+1),]
  
  
  training_set<-data_set[data_set$datetime<predictionDate,]
  training_set<-training_set[!duplicated(training_set$datetime),]
  if(location=="fwts"){
    fwts<-data$fwts[!duplicated(data$datetime)&(data$datetime>=(predictionDate-num_of_day)&data$datetime<predictionDate)]
    
  }else if(location=="brts"){
    fwts<-data$brts[!duplicated(data$datetime)&(data$datetime>=(predictionDate-num_of_day)&data$datetime<predictionDate)]
    
  }else if(location=="pats"){
    fwts<-data$pats[!duplicated(data$datetime)&(data$datetime>=(predictionDate-num_of_day)&data$datetime<predictionDate)]
    
  }
  while(length(fwts)<nrow(training_set)){
    fwts<-append(fwts[1],fwts)
  }
  training_set$fwts<-fwts
  
  
  lag_2<-data[(data$datetime>=(predictionDate-num_of_day-2)&data$datetime<predictionDate-num_of_day-1),]
  lag_2<-lag_2[!duplicated(lag_2$datetime),]
  if(nrow(lag_2)<288){
    rows_needed<-288 - nrow(lag_2)
    last_row<-lag_2[nrow(lag_2),]
    new_row<-as.data.frame(last_row)
    #fwts=0,sint=0,cost=0,temp=0,dew=0,hum=0,wspd=0,vis=0,pres=0,mon=0,tue=wed   thu   fri   sat   sun
    for(i in seq(1:rows_needed)){
      
      lag_2 <- rbind(lag_2,new_row)
      
    }
  }
  for(i in (num_of_day+1):3){
    temp<-data[data$datetime>=(predictionDate-i)&data$datetime<(predictionDate-i+1),]
    temp<-temp[!duplicated(temp$datetime),]
    if(nrow(temp) < 288){
      rows_needed<-288 - nrow(temp)
      last_row<-temp[nrow(temp),]
      new_row<-data.frame(last_row)
      #fwts=0,sint=0,cost=0,temp=0,dew=0,hum=0,wspd=0,vis=0,pres=0,mon=0,tue=wed   thu   fri   sat   sun
      for(i in seq(1:rows_needed)){
        temp <- rbind(temp,new_row)
      }
    }
    lag_2<-rbind(lag_2,temp)
  }
  
  lag_1<-data[(data$datetime>=(predictionDate-num_of_day-1)&data$datetime<predictionDate-num_of_day),]
  lag_1<-lag_1[!duplicated(lag_1$datetime),]
  if(nrow(lag_1)<288){
    rows_needed<-288 - nrow(lag_1)
    last_row<-lag_1[nrow(lag_1),]
    new_row<-as.data.frame(last_row)
    #fwts=0,sint=0,cost=0,temp=0,dew=0,hum=0,wspd=0,vis=0,pres=0,mon=0,tue=wed   thu   fri   sat   sun
    for(i in seq(1:rows_needed)){
      
      lag_1 <- rbind(lag_1,new_row)
      
    }
  }
  for(i in num_of_day:2){
    temp<-data[data$datetime>=(predictionDate-i)&data$datetime<(predictionDate-i+1),]
    temp<-temp[!duplicated(temp$datetime),]
    if(nrow(temp) < 288){
      rows_needed<-288 - nrow(temp)
      last_row<-temp[nrow(temp),]
      new_row<-data.frame(last_row)
      #fwts=0,sint=0,cost=0,temp=0,dew=0,hum=0,wspd=0,vis=0,pres=0,mon=0,tue=wed   thu   fri   sat   sun
      for(i in seq(1:rows_needed)){
        temp <- rbind(temp,new_row)
      }
    }
    lag_1<-rbind(lag_1,temp)
  }
  
  
  train<-training_set[training_set$datetime>=(predictionDate-num_of_day)&training_set$datetime<(predictionDate-num_of_day+1),]
  train<-train[!duplicated(train$datetime),]
  
  if(nrow(train) < 288){
    rows_needed<-288 - nrow(train)
    last_row<-train[nrow(train),]
    new_row<-data.frame(last_row)
    #fwts=0,sint=0,cost=0,temp=0,dew=0,hum=0,wspd=0,vis=0,pres=0,mon=0,tue=wed   thu   fri   sat   sun
    for(i in seq(1:rows_needed)){
      
      train <- rbind(train,new_row)
    }
    
  }
  for(i in (num_of_day-1):1){
    temp<-training_set[training_set$datetime>=(predictionDate-i)&training_set$datetime<(predictionDate-i+1),]
    temp<-temp[!duplicated(temp$datetime),]
    if(nrow(temp) < 288){
      rows_needed<-288 - nrow(temp)
      last_row<-temp[nrow(temp),]
      new_row<-data.frame(last_row)
      #fwts=0,sint=0,cost=0,temp=0,dew=0,hum=0,wspd=0,vis=0,pres=0,mon=0,tue=wed   thu   fri   sat   sun
      for(i in seq(1:rows_needed)){
        temp <- rbind(temp,new_row)
      }
    }
    train<-rbind(train,temp)
  }
  
  training_set<-train
  
  testing_set<-data_set[data_set$datetime>=predictionDate,]
  testing_set<-testing_set[!duplicated(testing_set$datetime),]
  
  if(location=="fwts"){
    training_set$fwts_lag_2<-lag_2$fwts
    training_set$fwts_lag_1<-lag_1$fwts    
    fwts<-data$fwts[!duplicated(data$datetime)&data$date==predictionDate]
  }else if(location=="brts"){
    training_set$fwts_lag_2<-lag_2$brts
    training_set$fwts_lag_1<-lag_1$brts    
    fwts<-data$brts[!duplicated(data$datetime)&data$date==predictionDate]
  }else if(location=="pats"){
    training_set$fwts_lag_2<-lag_2$pats
    training_set$fwts_lag_1<-lag_1$pats    
    fwts<-data$pats[!duplicated(data$datetime)&data$date==predictionDate]
  }
  while(length(fwts)<nrow(testing_set)){
    fwts<-append(fwts[1],fwts)
  }
  testing_set$fwts<-fwts
  
  if(nrow(testing_set) < 288){
    rows_needed<-288 - nrow(testing_set)
    last_row<-testing_set[nrow(testing_set),]
    new_row<-data.frame(last_row)
    #fwts=0,sint=0,cost=0,temp=0,dew=0,hum=0,wspd=0,vis=0,pres=0,mon=0,tue=wed   thu   fri   sat   sun
    for(i in seq(1:rows_needed)){
      testing_set <- rbind(testing_set,new_row)
    }
  }
  lag_2<-data[(data$datetime>=(predictionDate-2)&data$datetime<predictionDate-1),]
  lag_1<-data[(data$datetime>=(predictionDate-1)&data$datetime<predictionDate),]
  lag_2<-lag_2[!duplicated(lag_2$datetime),]
  lag_1<-lag_1[!duplicated(lag_1$datetime),]
  
  if(nrow(lag_1)<288){
    rows_needed<-288 - nrow(lag_1)
    last_row<-lag_1[nrow(lag_1),]
    new_row<-as.data.frame(last_row)
    #fwts=0,sint=0,cost=0,temp=0,dew=0,hum=0,wspd=0,vis=0,pres=0,mon=0,tue=wed   thu   fri   sat   sun
    for(i in seq(1:rows_needed)){
      
      lag_1 <- rbind(lag_1,new_row)
      
    }
  }
  if(nrow(lag_2)<288){
    rows_needed<-288 - nrow(lag_2)
    last_row<-lag_2[nrow(lag_2),]
    new_row<-as.data.frame(last_row)
    #fwts=0,sint=0,cost=0,temp=0,dew=0,hum=0,wspd=0,vis=0,pres=0,mon=0,tue=wed   thu   fri   sat   sun
    for(i in seq(1:rows_needed)){
      
      lag_2 <- rbind(lag_2,new_row)
      
    }
  }
  
  
  if(location=="fwts"){
    testing_set$fwts_lag_2<-lag_2$fwts
    testing_set$fwts_lag_1<-lag_1$fwts
  }else if(location=="brts"){
    testing_set$fwts_lag_2<-lag_2$brts
    testing_set$fwts_lag_1<-lag_1$brts
  }else if(location=="pats"){
    testing_set$fwts_lag_2<-lag_2$pats
    testing_set$fwts_lag_1<-lag_1$pats
  }
  
  
  ##################################################prediction model#######################################
  cubist_model<-cubist(x = training_set[,10:26], y = training_set$fwts, committees = 20, neighbors = 5,seed=12345)
  prediction_cubist <- predict(cubist_model, testing_set)
  
  #xgboost
  xgboost_model <- xgboost(data = as.matrix(training_set[,10:26]), label = training_set$fwts, nrounds = 150, max_depth = 3,
                           eta = 0.4, gamma = 0, subsample = 0.75, colsample_bytree = 0.8, rate_drop = 0.01,
                           skip_drop = 0.95, min_child_weight = 1,seed=122345)
  
  prediction_xgboost <-as.vector(predict(xgboost_model, newdata = as.matrix(testing_set[,10:26])))
  #Random Forest
  variables=c('temp','dew','hum','wspd','vis','pres','mon','tue','wed','thu','fri','sat','sun','sint','cost','fwts_lag_1','fwts_lag_2')#,'fwts_lag_1','fwts_lag_2'
  training_set$fwts<-as.vector(training_set$fwts)
  training_set$fwts_lag_1<-as.vector(training_set$fwts_lag_1)
  training_set$fwts_lag_2<-as.vector(training_set$fwts_lag_2)
  RF_model<-h2o.randomForest(x=variables,
                             y="fwts",
                             ntrees=500,
                             max_depth=10,
                             training_frame=as.h2o(training_set[,c(3,10:26)]),
                             seed=1242525)
  testing_set$fwts<-as.vector(testing_set$fwts)
  testing_set$fwts_lag_1<-as.vector(testing_set$fwts_lag_1)
  testing_set$fwts_lag_2<-as.vector(testing_set$fwts_lag_2)
  prediction_RF = as.vector(predict(RF_model, newdata = as.h2o(testing_set[,-c(1,2,3,4:8,9)])))
  
  h2o.removeAll()
  #nerual network
  NN_model<- h2o.deeplearning( 
    training_frame=as.h2o(training_set[,c(3,10:26)]), 
    x=variables,
    y="fwts",
    hidden=c(256,256,256),          ## more hidden layers -> more complex interactions
    epochs=20,                      ## to keep it short enough
    score_validation_samples=10000, ## downsample validation set for faster scoring
    score_duty_cycle=0.025,         ## don't score more than 2.5% of the wall time
    l1=1e-5,                        ## add some L1/L2 regularization
    l2=1e-5,
    max_w2=10,                       ## helps stability for Rectifier
    seed=12345
  )         
  #  momentum_start=0.2,             ## manually tuned momentum
  #momentum_stable=0.4, 
  #momentum_ramp=1e7, 
  
  prediction_NN = as.vector(predict(NN_model, newdata = as.h2o(testing_set[,-c(1,2,3,4:8,9)])))
  
  #free memory
  h2o.removeAll()
  
  #LSTM
  
  fwts_trainY_vector<- training_set$fwts
  fwts_trainY_array <- array(data = fwts_trainY_vector,dim = c(length(fwts_trainY_vector),1))
  
  
  
  lag_1_fwts_trainX_vector<- training_set$fwts_lag_1
  lag_2_fwts_trainX_vector<- training_set$fwts_lag_2
  
  
  temp_trainX_vector<- training_set$temp
  dew_trainX_vector<- training_set$dew
  hum_trainX_vector<- training_set$hum
  wspd_trainX_vector<- training_set$wspd
  vis_trainX_vector<- training_set$vis
  pres_trainX_vector<- training_set$pres
  mon_trainX_vector<- training_set$mon
  tue_trainX_vector<- training_set$tue
  wed_trainX_vector<- training_set$wed
  thu_trainX_vector<- training_set$thu
  fri_trainX_vector<- training_set$fri
  sat_trainX_vector<- training_set$sat
  sun_trainX_vector<- training_set$sun
  sint_trainX_vector<-training_set$sint
  cost_trainX_vector<-training_set$cost
  
  
  
  lag_1_fwts_trainX_array <- array(data = lag_1_fwts_trainX_vector,dim = c(length(lag_1_fwts_trainX_vector),1,1) )
  lag_2_fwts_trainX_array <- array(data = lag_2_fwts_trainX_vector,dim = c(length(lag_2_fwts_trainX_vector),1,1) )
  
  temp_trainX_array <- array(data = temp_trainX_vector,dim = c(length(temp_trainX_vector),1,1) )
  dew_trainX_array <- array(data = dew_trainX_vector,dim = c(length(dew_trainX_vector),1,1) )
  hum_trainX_array <- array(data = hum_trainX_vector,dim = c(length(hum_trainX_vector),1,1) )
  wspd_trainX_array <- array(data = wspd_trainX_vector,dim = c(length(wspd_trainX_vector),1,1) )
  vis_trainX_array <- array(data = vis_trainX_vector,dim = c(length(vis_trainX_vector),1,1) )
  pres_trainX_array <- array(data = pres_trainX_vector,dim = c(length(pres_trainX_vector),1,1) )
  mon_trainX_array <- array(data = mon_trainX_vector,dim = c(length(mon_trainX_vector),1,1) )
  tue_trainX_array <- array(data = tue_trainX_vector,dim = c(length(tue_trainX_vector),1,1) )
  wed_trainX_array <- array(data = wed_trainX_vector,dim = c(length(wed_trainX_vector),1,1) )
  thu_trainX_array <- array(data = thu_trainX_vector,dim = c(length(thu_trainX_vector),1,1) )
  fri_trainX_array <- array(data = fri_trainX_vector,dim = c(length(fri_trainX_vector),1,1) )
  sat_trainX_array <- array(data = sat_trainX_vector,dim = c(length(sat_trainX_vector),1,1) )
  sun_trainX_array <- array(data = sun_trainX_vector,dim = c(length(sun_trainX_vector),1,1) )
  sint_trainX_array <- array(data = sint_trainX_vector,dim = c(length(sint_trainX_vector),1,1) )
  cost_trainX_array <- array(data = cost_trainX_vector,dim = c(length(cost_trainX_vector),1,1) )
  
  
  
  input_list_fwts <- list(
    lag_1_fwts_trainX_array,lag_2_fwts_trainX_array,temp_trainX_array,dew_trainX_array,hum_trainX_array,wspd_trainX_array,vis_trainX_array,pres_trainX_array,mon_trainX_array,tue_trainX_array,wed_trainX_array,thu_trainX_array,fri_trainX_array,sat_trainX_array,sun_trainX_array,sint_trainX_array,cost_trainX_array
  )
  
  
  
  
  #model inputs
  
  batch_size = 1
  timesteps<-1
  n_epochs <- 15
  
  
  #model definition
  n_neurons = 5
  fwts_lstm_model_lag288 <- keras_model_sequential()
  
  fwts_lstm_model_lag288 %>%
    layer_lstm(units = n_neurons,input_shape = c(timesteps,1),batch_size = batch_size,return_sequences = TRUE,stateful = TRUE) %>%
    layer_dense(units=1) %>%
    compile(loss = 'mean_squared_error',
            optimizer = 'adam')
  
  fwts_lstm_model_lag288 %>% fit(input_list_fwts,fwts_trainY_array,batch_size = batch_size,epochs = n_epochs,verbose=0,shuffle=FALSE)
  
  testX_sint_vector<-testing_set$sint
  testX_sint_array <- array(data = testX_sint_vector,dim = c(length(testX_sint_vector),1,1))
  
  testX_cost_vector<-testing_set$cost
  testX_cost_array <- array(data = testX_cost_vector,dim = c(length(testX_cost_vector),1,1))
  
  testX_temp_vector<-testing_set$temp
  testX_temp_array <- array(data = testX_temp_vector,dim = c(length(testX_temp_vector),1,1))
  
  testX_hum_vector<-testing_set$hum
  testX_hum_array <- array(data = testX_hum_vector,dim = c(length(testX_hum_vector),1,1))
  
  testX_dew_vector<-testing_set$dew
  testX_dew_array <- array(data = testX_dew_vector,dim = c(length(testX_dew_vector),1,1))
  
  testX_wspd_vector<-testing_set$wspd
  testX_wspd_array <- array(data = testX_wspd_vector,dim = c(length(testX_wspd_vector),1,1))
  
  testX_vis_vector<-testing_set$vis
  testX_vis_array <- array(data = testX_vis_vector,dim = c(length(testX_vis_vector),1,1))
  
  testX_pres_vector<-testing_set$pres
  testX_pres_array <- array(data = testX_pres_vector,dim = c(length(testX_pres_vector),1,1))
  
  
  testX_mon_vector<-testing_set$mon
  testX_mon_array <- array(data = testX_mon_vector,dim = c(length(testX_mon_vector),1,1))
  
  testX_tue_vector<-testing_set$tue
  testX_tue_array <- array(data = testX_tue_vector,dim = c(length(testX_tue_vector),1,1))
  
  testX_wed_vector<-testing_set$wed
  testX_wed_array <- array(data = testX_wed_vector,dim = c(length(testX_wed_vector),1,1))
  
  testX_thu_vector<-testing_set$thu
  testX_thu_array <- array(data = testX_thu_vector,dim = c(length(testX_thu_vector),1,1))
  
  testX_fri_vector<-testing_set$fri
  testX_fri_array <- array(data = testX_fri_vector,dim = c(length(testX_fri_vector),1,1))
  
  testX_sat_vector<-testing_set$sat
  testX_sat_array <- array(data = testX_sat_vector,dim = c(length(testX_sat_vector),1,1))
  
  testX_sun_vector<-testing_set$sun
  testX_sun_array <- array(data = testX_sun_vector,dim = c(length(testX_sun_vector),1,1))
  
  
  testX_lag_1_fwts_vector<-testing_set$fwts_lag_1
  testX_fwts_lag_1_array <- array(data = testX_lag_1_fwts_vector,dim = c(length(testX_lag_1_fwts_vector),1,1))
  
  testX_lag_2_fwts_vector<-testing_set$fwts_lag_2
  testX_fwts_lag_2_array <- array(data = testX_lag_2_fwts_vector,dim = c(length(testX_lag_2_fwts_vector),1,1))
  
  fwts_testX_input_list <- list(
    testX_fwts_lag_1_array,testX_fwts_lag_2_array,testX_temp_array,testX_dew_array,testX_hum_array,testX_wspd_array,testX_vis_array,testX_pres_array,testX_mon_array,testX_tue_array,testX_wed_array,testX_thu_array,testX_fri_array,testX_sat_array,testX_sun_array,testX_sint_array,testX_cost_array
  )
  
  prediction_LSTM <-
    fwts_lstm_model_lag288 %>% predict(fwts_testX_input_list, batch_size = 1)
  
  
  if(location=="fwts"){ 
    prediction_cubist<-prediction_cubist*attr(scale_fwts,'scaled:scale')+attr(scale_fwts,'scaled:center')
    prediction_xgboost<-prediction_xgboost*attr(scale_fwts,'scaled:scale')+attr(scale_fwts,'scaled:center')
    prediction_RF<-prediction_RF*attr(scale_fwts,'scaled:scale')+attr(scale_fwts,'scaled:center')
    prediction_NN<-prediction_NN*attr(scale_fwts,'scaled:scale')+attr(scale_fwts,'scaled:center')
    prediction_LSTM<-prediction_LSTM*attr(scale_fwts,'scaled:scale')+attr(scale_fwts,'scaled:center')
    testing_set$fwts<-testing_set$fwts*attr(scale_fwts,'scaled:scale')+attr(scale_fwts,'scaled:center')
  }else if(location=="brts"){ 
    prediction_cubist<-prediction_cubist*attr(scale_brts,'scaled:scale')+attr(scale_brts,'scaled:center')
    prediction_xgboost<-prediction_xgboost*attr(scale_brts,'scaled:scale')+attr(scale_brts,'scaled:center')
    prediction_RF<-prediction_RF*attr(scale_brts,'scaled:scale')+attr(scale_brts,'scaled:center')
    prediction_NN<-prediction_NN*attr(scale_brts,'scaled:scale')+attr(scale_brts,'scaled:center')
    prediction_LSTM<-prediction_LSTM*attr(scale_brts,'scaled:scale')+attr(scale_brts,'scaled:center')
    testing_set$fwts<-testing_set$fwts*attr(scale_brts,'scaled:scale')+attr(scale_brts,'scaled:center')
  }else if(location=="pats"){ 
    prediction_cubist<-prediction_cubist*attr(scale_pats,'scaled:scale')+attr(scale_pats,'scaled:center')
    prediction_xgboost<-prediction_xgboost*attr(scale_pats,'scaled:scale')+attr(scale_pats,'scaled:center')
    prediction_RF<-prediction_RF*attr(scale_pats,'scaled:scale')+attr(scale_pats,'scaled:center')
    prediction_NN<-prediction_NN*attr(scale_pats,'scaled:scale')+attr(scale_pats,'scaled:center')
    prediction_LSTM<-prediction_LSTM*attr(scale_pats,'scaled:scale')+attr(scale_pats,'scaled:center')
    testing_set$fwts<-testing_set$fwts*attr(scale_pats,'scaled:scale')+attr(scale_pats,'scaled:center')
  }
  
 
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  datetimes <-seq(ymd_hm(paste(predictionDate, "00:00")),
                  ymd_hm(paste(predictionDate, "23:55")), 
                  by = "5 min")
  
  ##################################### Find peak values  ######################################
  
  
  #Cubist Predicted Daily Peak
  peak_start<-180
  ymax_cubist_pred = max(prediction_cubist[peak_start:288])
  xcoord_cubist_pred <-
    datetimes[which.max(prediction_cubist[peak_start:288]) + peak_start-1]
  
  #XGBoost Predicted Daily Peak
  ymax_xgboost_pred = max(prediction_xgboost[peak_start:288])
  xcoord_xgboost_pred <-
    datetimes[which.max(as.vector(prediction_xgboost[peak_start:288])) + peak_start-1]
  
  #Random Forest Predicted Daily Peak
  ymax_RF_pred = max(prediction_RF[peak_start:288])
  xcoord_RF_pred <-
    datetimes[which.max(prediction_RF[peak_start:288]) + peak_start-1]
  #NN Predicted Daily Peak
  ymax_NN_pred = max(prediction_NN[peak_start:288])
  xcoord_NN_pred <-
    datetimes[which.max(prediction_NN[peak_start:288]) + peak_start-1]
  
  #LSTM Predicted Daily Peak
  ymax_LSTM_pred = max(prediction_LSTM[peak_start:288])
  xcoord_LSTM_pred <-
    datetimes[which.max(prediction_LSTM[peak_start:288]) + peak_start-1]
  
  #Test data peak
  ymax_test_pred = max(testing_set$fwts[peak_start:288])
  xcoord_test_pred <-
    mean(datetimes[testing_set$fwts==ymax_test_pred])
  
  
  ####################################Change average here after add new algorithm###################################
  #Avg of all peak times
  prediction_avg = (prediction_xgboost + prediction_cubist  +
                      prediction_RF+prediction_NN+prediction_LSTM) / 5
  
  
  ymax_avg_pred = max(prediction_avg[peak_start:288])
  xcoord_avg_pred <-
    datetimes[which.max(prediction_avg[peak_start:288]) + peak_start-1]
  
  ###############################mean_s kick one out if too far from each other#########################
  
  mean_all<-mean(c(xcoord_cubist_pred,xcoord_xgboost_pred,xcoord_NN_pred,xcoord_RF_pred,xcoord_avg_pred,xcoord_LSTM_pred))
  differ_cubist<-abs(difftime(xcoord_cubist_pred,mean_all, units = "mins"))
  differ_xgboost<-abs(difftime(xcoord_xgboost_pred,mean_all, units = "mins"))
  differ_NN<-abs(difftime(xcoord_NN_pred,mean_all, units = "mins"))
  differ_RF<-abs(difftime(xcoord_RF_pred,mean_all, units = "mins"))
  differ_LSTM<-abs(difftime(xcoord_LSTM_pred,mean_all, units = "mins"))
  differ_AVG<-abs(difftime(xcoord_avg_pred,mean_all, units = "mins"))
  temp_list<-c(xcoord_cubist_pred,xcoord_xgboost_pred,xcoord_NN_pred,xcoord_RF_pred,xcoord_LSTM_pred,xcoord_avg_pred)
  differ_list<-c(differ_cubist,differ_xgboost,differ_NN,differ_RF,differ_LSTM,differ_AVG)
  mean_s<-mean_all
  if(max(differ_list)>60){
    cut<-which.max(differ_list)
    mean_s<-mean(temp_list[-cut])
  }
  
  ######################################################
  
  
  #lists
  xcoord_list<-list("test"=xcoord_test_pred, "cubist"=xcoord_cubist_pred, "xgboost"=xcoord_xgboost_pred, 
                    "RF"=xcoord_RF_pred,"NN"=xcoord_NN_pred,"LSTM"=xcoord_LSTM_pred,"AVG"=xcoord_avg_pred,
                    "mean"=mean_all,
                    "mean_s"=mean_s)
  
  ymax_list<-list("test"=ymax_test_pred, "cubist"=ymax_cubist_pred, "xgboost"=ymax_xgboost_pred,
                  "RF"=ymax_RF_pred,"NN"=ymax_NN_pred,"LSTM"=ymax_LSTM_pred,"AVG"=ymax_avg_pred)
  
  list_of_prediction<-list("hours"=datetimes,"test"=testing_set$fwts,"cubist"= prediction_cubist,
                           "xgboost"=prediction_xgboost,
                           "RF"=prediction_RF,"NN"=prediction_NN,"LSTM"=prediction_LSTM,"AVG"=prediction_avg,"xcoord_list"=xcoord_list,
                           "ymax_list"=ymax_list)
  
  results<-data.frame(as.character(date),rmse(list_of_prediction$test[156:288],list_of_prediction$cubist[156:288])/mean(list_of_prediction$test),
                      rmse(list_of_prediction$test[156:288],list_of_prediction$xgboost[156:288])/mean(list_of_prediction$test),
                      rmse(list_of_prediction$test[156:288],list_of_prediction$RF[156:288])/mean(list_of_prediction$test),
                      rmse(list_of_prediction$test[156:288],list_of_prediction$NN[156:288])/mean(list_of_prediction$test),
                      rmse(list_of_prediction$test[156:288],list_of_prediction$LSTM[156:288])/mean(list_of_prediction$test),
                      rmse(list_of_prediction$test[156:288],list_of_prediction$AVG[156:288])/mean(list_of_prediction$test),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$cubist, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$xgboost, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$RF, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$NN, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$LSTM, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$AVG, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$mean, units = "mins")),
                      (difftime(list_of_prediction$xcoord_list$test,list_of_prediction$xcoord_list$mean_s, units = "mins")))
  colnames(results)<- c("datetime","RMSE_cubist","RMSE_xgboost","RMSE_RF","RMSE_NN","RMSE_LSTM","RMSE_AVG","Peak_dif_cubist","Peak_dif_xgboost","Peak_dif_RF","Peak_dif_NN","Peak_dif_LSTM","Peak_dif_AVG","Peak_dif_mean","Peak_dif_mean_s")
  
  list_of_prediction<-list("hours"=datetimes,"test"=testing_set$fwts,"cubist"= prediction_cubist,
                           "xgboost"=prediction_xgboost,
                           "RF"=prediction_RF,"NN"=prediction_NN,"LSTM"=prediction_LSTM,"AVG"=prediction_avg,
                           "xcoord_list"=xcoord_list, "ymax_list"=ymax_list,"results"=results)
  
  
  #pl<-daily_plot(list_of_prediction)
  if(date==Sys.Date()-1){
    list_of_prediction$test[]<-NA
  
  }
  return(list_of_prediction)
}




########################################################################################################################
########################################################################################################################
########################################################################################################################
########################################################################################################################
########################################################################################################################
########################################################################################################################


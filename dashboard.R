
current_date<-as.character(Sys.Date())

ui <- dashboardPage(
  
  dashboardHeader(title = "Energy Mangement Tool", titleWidth = 225),
  
  dashboardSidebar(
    width = 225,
    menuItem("Dashboard", tabName = "dashboardTab", icon = icon("dashboard")),
    
    textInput("date_txt", "Enter date (YYYY-MM-DD)", "2021-01-01"),
    
    actionButton("run_btn","Start", icon = icon("play-circle")),
    actionButton("today_btn","Today"),
    actionButton("simButton","Simulation"),
    
    #verbatimTextOutput("remove_txt"),
    
    #checkboxInput("cubist_chk", "Cubist", TRUE),
    #checkboxInput("xgb_chk", "XGBoost", TRUE),
    #checkboxInput("dl_chk", "Deep Learning", TRUE),
    #checkboxInput("rf_chk", "Random Forest", TRUE),
    #checkboxInput("avg_chk", "Average", TRUE),
    #checkboxInput("test_chk", "Test Data", TRUE)
    
    verbatimTextOutput("mode_txt"),
    checkboxInput("forecast","Forecast(BETA)"),
    selectInput("location","Location",choices = list("FWTS"="fwts","BRTS"="brts","PATS"="pats")),
    radioButtons("Report_mode","Report Mode",choices=list("Simple"=1,"Detailed"=2),selected=1),
    radioButtons("Report_range","Report Range",choices=list("Daily"=1,"Weekly"=2,"Monthly"=3),selected=1),
    
    
    verbatimTextOutput("charging_txt"),
    
    sliderInput("charge",label = "Charging Time",min = as.POSIXct(paste(as.character(Sys.Date()),"00:00:00"),tz="EST"),
                max = as.POSIXct(paste(as.character(Sys.Date()),"23:59:59"),tz="EST"),
                value= c(as.POSIXct(paste(as.character(Sys.Date()),"00:00:00"),tz="EST"),
                         as.POSIXct(paste(as.character(Sys.Date()),"23:59:59"),tz="EST")),
                timeFormat='%H:%M',
                step=60),
    sliderInput("discharge",label = "Discharging Time",min = as.POSIXct(paste(as.character(Sys.Date()),"22:00:00"),tz="EST"),
                max = as.POSIXct(paste(as.character(Sys.Date()+1),"21:59:59"),tz="EST"),
                value= c(as.POSIXct(paste(as.character(Sys.Date()),"22:00:00"),tz="EST"),
                         as.POSIXct(paste(as.character(Sys.Date()+1),"21:59:59"),tz="EST")),
                timeFormat='%H:%M',
                step=60),
    actionButton("charge_btn","Update",icon = icon("battery-quarter")),
    
    
    verbatimTextOutput("Automode_txt"),

    checkboxInput("auto","Auto Mode"),
    
    
    
    
    
    actionButton('check',"Check Status"),
    actionButton('update',"Update"),
    shinyDirButton('folder', 'Selection Report Folder', 'Please select a folder', FALSE),
    actionButton('report',"Export Report")

  ),
  
  dashboardBody(
    
    #top boxes
    fluidRow(
      valueBoxOutput("pred_peak", width = 4),
      valueBoxOutput("real_peak", width = 4),
      valueBoxOutput("error", width = 4)
    ),
    
    tabItem(tabName = "first", h2("Daily Prediction")),
    fluidRow(box(plotlyOutput("plot"), width=12, height=500))
  ),
  
  #set up progress bar
  tags$head(
    tags$style(
      HTML(".shiny-notification {
           height: 100px;
           width: 800px;
           position:fixed;
           top: calc(50% - 50px);;
           left: calc(50% - 400px);;
           }
           "
      )
    )
  )
)


######################################### SERVER ######################################### 

server <- function(input, output,session) { 
  observeEvent(input$simButton, {
    #system(paste("python app.py",(as.Date(input$date_txt)),sep=' '))
    browseURL("http://127.0.0.1:420/")
    #system("python /Analysis tool/MARL discharging scheduling/Interface/app.py")
  })
  output$remove_txt <- renderText({
    paste("Remove curves from graph")
  })
  
  output$charging_txt <- renderText({
    paste("Control charging station")
  })
  output$mode_txt <- renderText({
    paste("Setting")
  })
  output$Automode_txt <- renderText({
    paste("AutoMode setting")
  })
  
  #charge button
  observeEvent(input$charge_btn, {
    charge_Control()
  })
  #file location choose and report export
  shinyDirChoose(input, 'folder', roots=c(wd='.'), filetypes=c('', 'txt'))
  
  observeEvent(ignoreNULL= TRUE, eventExpr={input$folder},{
    dirinfo<-parseDirPath(c(wd='.'),input$folder)
  })
  observeEvent(input$report, {rmarkdown::render('report_html.Rmd',
                                                    output_dir = paste("./report/",input$location,sep=""),
                                                    output_file = paste(format(as.Date(input$date_txt), "%Y-%B"),"_report.html",sep = ''),
                                                    params= list(report_month=input$date_txt,location=input$location)
  )})

#run predictions
  predictions_list<-reactive({
    
    #wait until Run button is clicked
    if(input$run_btn > 0)
    {
      if(input$Report_range ==1){
        if(input$forecast >0){
          isolate(
            make_prediction(input$date_txt,input$location)
          ) 
        }else{
          isolate(
            make_prediction_testing(input$date_txt,input$location)
          ) 
        }
      }else if(input$Report_range ==2){
        isolate(
          make_prediction_weekly(input$date_txt,input$location)
        )
      }
      else if(input$Report_range ==3){
        isolate(
          make_prediction_monthly(input$date_txt,input$location)
        )
      }
      
    }
  })
  #today button
  
  observeEvent(input$today_btn, {
    updateTextInput(session,"date_txt",value=as.character(Sys.Date()))
  })
  
  
  #Auto mode button
  observeEvent(input$check, {
    ls<-taskscheduler_ls()
    mode<-sum(ls$TaskName=="automode_forecasting")
    if(mode>0){
      output$Automode_txt <- renderText({
        paste("AutoMode setting: Status ON")
      })
      updateCheckboxInput(session,"auto",value=1)
    }else
    {
      output$Automode_txt <- renderText({
        paste("AutoMode setting: Status OFF")
      })
      updateCheckboxInput(session,"auto",value=0)
    }
    
  })
  
  observeEvent(input$update, {
    ls<-taskscheduler_ls()
    mode<-sum(ls$TaskName=="automode_forecasting")
    if(input$auto>0){
      if(mode==0){
        taskscheduler_create(
          taskname = "automode_forecasting",
          rscript = "D:/Hydro-prediction-System/ui/automode.bat",
          schedule = "DAILY",
          starttime = "01:00",
          startdate = format(Sys.Date(),"%Y/%m/%d"),
        )
        output$Automode_txt <- renderText({
          paste("AutoMode setting: Status ON")
        })
      }
    }else{
      if(mode>0){
        taskscheduler_delete("automode_forecasting")
        output$Automode_txt <- renderText({
          paste("AutoMode setting: Status OFF")
        })
      }
    }
  })
  
  
  #discharge button
  observeEvent(input$discharge_btn, {
    discharge_Control()
  })
  
  #keep track of checkboxes
  checkbox_list<-reactive({
    list("cubist_chk"=input$cubist_chk,
         "xgb_chk"= input$xgb_chk,
         "dl_chk"= input$dl_chk,
         "rf_chk"= input$rf_chk,
         "avg_chk"=input$avg_chk,
         "test_chk"=input$test_chk)
  })
  
  #get mean values
  mean_values<-reactive({
    mean_values<-get_mean_values(predictions_list(), checkbox_list(), input$date_txt)
  })
  
  
  #generate plot
  output$plot <- 
    renderPlotly({
      
      #progress bar
      withProgress(message = 'Calculation in progress.',
                   detail = ' This may take a while...', value = 0, {
                     
                     #wait until Start button is clicked once
                     if(input$run_btn > 0)
                     {
                       if(input$Report_mode == 2)
                         {
                            if(input$Report_range == 1){
                              daily_plot(predictions_list())  
                            }else if(input$Report_range ==2){
                              weekly_plot(predictions_list())
                            }else if(input$Report_range ==3){
                              monthly_plot(predictions_list())
                            }
                            
                       }
                       else if(input$Report_mode == 1)
                       {
                         if(input$Report_range == 1){
                           daily_plot_simple(predictions_list())  
                         }else if(input$Report_range ==2){
                           weekly_plot_simple(predictions_list())
                         }else if(input$Report_range ==3){
                           monthly_plot_simple(predictions_list())
                         }
                       }
                       
                     }
                   })
    })
  
  
  #pred_peak time box
  output$pred_peak <- renderValueBox({
    
    #wait until Run button is clicked
    if(input$run_btn > 0&& input$Report_range ==1)
    {
      #mean_values<-mean_values()
      list<-predictions_list()
      
      valueBox(
        formatC(strftime(as.character(list$xcoord_list$mean_s), format="%H:%M:%S"), format="s")
        ,paste('Predicted Peak Time')
        ,icon = icon("stats",lib='glyphicon')
        ,color = "light-blue")
    }else{
      valueBox(
        formatC("-", format="s")
        ,paste('Predicted Peak Time')
        ,icon = icon("stats",lib='glyphicon')
        ,color = "light-blue")
    }
  })
  
  
  #real_peak time box
  output$real_peak <- renderValueBox({
    
    #wait until Run button is clicked
    if(input$run_btn > 0&& input$Report_range ==1)
    {
      list<-predictions_list()
      
      valueBox(
        formatC(strftime(as.character(list$xcoord_list$test), format="%H:%M:%S"), format="s")
        ,paste('Real Peak Time')
        ,icon = icon("clock")
        ,color = 'red')
    }else{
      valueBox(
        formatC("-", format="s")
        ,paste('Real Peak Time')
        ,icon = icon("clock")
        ,color = 'red')
    }
  })
  
  #error box
  output$error <- renderValueBox({
    
    #wait until Run button is clicked
    if(input$run_btn > 0)
    {
      #mean_values<-mean_values()
      #peak_mean<-mean_values$mean_peak_time
    
      predictions_list<-predictions_list()
      #peak_test<- predictions_list$xcoord_list$test
      
      #error_in_mins<-difftime(mean_values$mean_peak_time, peak_test, units="mins" )
      error_in_mins<-predictions_list$results$Peak_dif_mean_s
      error_in_mins<-round(error_in_mins, digits=2)
      if(input$Report_range ==1){
        valueBox(
          formatC(paste(error_in_mins, " minutes"), format="s")
          ,paste('Peak difference')
          ,icon = icon("times")
          ,color = "black")
        
      }else{
        valueBox(
          formatC(paste(error_in_mins, " minutes"), format="s")
          ,paste('Average Peak difference')
          ,icon = icon("times")
          ,color = "black")
        
      }
      
    }else{
      valueBox(
        formatC("-", format="s")
        ,paste('Peak difference')
        ,icon = icon("times")
        ,color = "black")
    }
  })
  
}


shinyApp(ui, server)



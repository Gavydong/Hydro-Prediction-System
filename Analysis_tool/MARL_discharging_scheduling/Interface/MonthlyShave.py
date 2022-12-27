from datetime import date, timedelta, datetime
import pandas as pd
from datetime import datetime
import plotly.graph_objects as go
from plotly.graph_objs import *
import plotly.express as px

from datetime import timedelta
import numpy as np

def state_set(state_date,data):
    # read data
    day = (data['datetime'] >= state_date) & (data['datetime'] < (state_date + timedelta(days=1)))
    state = data.loc[day]
    return state

def genres(dateSelected,agents,dis_hour,cap):
    data = pd.read_csv("data/total_dataset.csv")
    data['datetime'] = pd.to_datetime(data['datetime'])
    # agent properties

    ##############
    # input date
    state_date = dateSelected

###################
    state_date = datetime.strptime(state_date, "%Y-%m-%d")
    state = state_set(state_date, data)
    state_time = state['datetime']
    state_time.reset_index(drop=True, inplace=True)
    state_value = state['fwts']
    state_value.reset_index(drop=True, inplace=True)
#############################################
    #input variables
    agent_number = agents
    max_agent_number = 30 # for the line chart
    #rate = 1 / 10 ** 8
    capacity = cap #w
    discharge_hour = dis_hour
################################
    discharging_list = [0] * agent_number
    peakshave_list = [0] * max_agent_number
    one_agent_benefit_list = [0] * max_agent_number

    Shaved_value = state_value.copy()
    for x in range(agent_number):
        discharging_time = Shaved_value.argmax()-discharge_hour*6
        discharging_list[x]= discharging_time
        try:
            Shaved_value[discharging_time:discharging_time + discharge_hour * 12] = Shaved_value[
                                                              discharging_time:discharging_time + discharge_hour * 12] - capacity / discharge_hour
        except:
            continue

    #Shaved_value is the daily curve after peak shave
    #state_value is the daily curve before
    x = []
    y = []
    for discharging_time in discharging_list:
        try:
            x.append(state_time[discharging_time])
            y.append(state_value[discharging_time])
        except:
            continue
    #discharging_time is a array contain all the discharging time in 5-min interval format (0-287)

    return Shaved_value,state_value,state_time

def genMonthlyshave(monthdate,agents,dhours,cap):
    sdate = date(2018,1,1)   # start date
    edate = date.today()   # end date
    dates = pd.date_range(sdate,edate-timedelta(days=1),freq='d').to_frame()

    listOfDates = dates.loc[monthdate]
    shaved = []
    cons = []
    tstamps = []
    for d in listOfDates[0]:
        print(d)
        s,c,t = genres(d.strftime('%Y-%m-%d'),agents,dhours,cap)
        shaved = [*shaved, *s]
        cons = [*cons,*c]
        tstamps = [*tstamps ,*t]



    layout = Layout(
    paper_bgcolor='rgba(0,0,0,0)',
    plot_bgcolor='rgba(0,0,0,0)'
    )

    fig = go.Figure(layout=layout,)

    fig.add_trace(go.Scatter(x=tstamps, y=shaved,
                             mode='lines',
                             name='Shaving',marker=dict(
                color='red',
                size=20,
                line=dict(
                    color='red',
                    width=10
                )
            )))
    fig.add_trace(go.Scatter(x=tstamps, y=cons,
                             mode='lines',
                             name='Consumption',marker=dict(
                color='Black',
                size=30,
                line=dict(
                    color='black',
                    width=30
                )
            )))

    fig.update_layout(xaxis=dict(showgrid=False),
                  yaxis=dict(showgrid=False))
    fig.update_xaxes(title_text="Time")
    fig.update_yaxes(title_text="Energy")

    df = pd.DataFrame(tstamps,columns=["timestamp"])
    df["timestamp"] = pd.to_datetime(df['timestamp'], unit='s')
    df.index = df["timestamp"]
    df = df.drop("timestamp",axis=1)
    df["Shaved"] = shaved
    print(str(df.idxmax()))
    tdf = pd.DataFrame([str(max(cons))+ " KW"],columns=["Acutal Peak"])
    tdf["Shaved Peak"] = [str(df.max()[0])+" KW"]
    tdf["Peak Shaving"] = [str(int(max(cons)-df.max()[0])) + "KW"]
    tdf["Saving"] = ["$"+str(int(max(cons)-df.max()[0])*0.052)]




    return fig,tdf

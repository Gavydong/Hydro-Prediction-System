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
def genres(input_date, max_agent, discharging_time, capacity):
    data = pd.read_csv("data/total_dataset.csv")
    data['datetime'] = pd.to_datetime(data['datetime'])
    state_date = input_date
    max_agent_number = int(max_agent)
    discharging_time = int(discharging_time)
    capacity = int(capacity)
    discharge_hour = discharging_time

    state_date = datetime.strptime(state_date, "%Y-%m-%d")
    state = state_set(state_date, data)
    state_time = state['datetime']
    state_time.reset_index(drop=True, inplace=True)
    state_value = state['fwts']
    state_value.reset_index(drop=True, inplace=True)

    peakshave_list = [0] * max_agent_number

    for i in range(max_agent_number):
        Shaved_value = state_value.copy()
        for x in range(i + 1):
            discharging_time = Shaved_value.argmax() - int(discharge_hour * 6)
            # discharging_list[x] = discharging_time
            if (discharging_time < 0):
                discharging_time = 0
            if (discharging_time > (288 - discharge_hour * 12)):
                discharging_time = int(288 - discharge_hour * 12)
            Shaved_value[discharging_time:discharging_time + int(discharge_hour * 12)] = Shaved_value[
                                                                                         discharging_time:discharging_time + int(
                                                                                             discharge_hour * 12)] - capacity / discharge_hour
        peak_shave = state_value.max() - Shaved_value.max()
        peakshave_list[i] = int(peak_shave)
    #dataframe = {"Number of EVs": range(1, max_agent_number + 1),"Peak Shaved": peakshave_list}
    #df = pd.DataFrame(dataframe)
    return peakshave_list

def monthlyAnalysis(monthdate,maxagents,dhours,cap):
    sdate = date(2018,1,1)   # start date
    edate = date.today()   # end date
    dates = pd.date_range(sdate,edate-timedelta(days=1),freq='d').to_frame()
    max_agent_number = int(maxagents)
    listOfDates = dates.loc[monthdate]
    dfs = []
    shaving = [0] * max_agent_number
    for d in listOfDates[0]:
        peak_shave_list = (genres(d.strftime('%Y-%m-%d'),max_agent_number,dhours,cap))
        shaving = [shaving[x] + peak_shave_list[x] for x in range(len(shaving))]
    ids = np.arange(1,max_agent_number+1,1)

    #for d in dfs:
    #    grouped = d.groupby("Number of EVs")
    ##    for i,j in zip(ids,np.arange(len(ids))):
     #       shaving[j] =  shaving[j] + grouped.get_group(i)["Peak Shaved"]

    fdf = pd.DataFrame(ids,columns=["Number of Agents"])
    fdf["Peak Shaved (kW)"] = shaving

    layout = Layout(
    paper_bgcolor='rgba(0,0,0,0)',
    plot_bgcolor='rgba(0,0,0,0)'
    )

    fig = go.Figure(layout=layout)
    fig.add_trace(go.Scatter(x=fdf["Number of Agents"], y=fdf["Peak Shaved (kW)"],
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
    fig.update_xaxes(title_text="Number of Agents")
    fig.update_yaxes(title_text="Peak Shaved (kW)")
    return fig,fdf

import plotly.express as px
import matplotlib.pyplot as plt
import pandas as pd
from datetime import datetime

import plotly.graph_objects as go
from sklearn.preprocessing import StandardScaler
from datetime import timedelta
import numpy as np
import statistics as s
import multiprocessing as mp
import random
from sklearn.preprocessing import MinMaxScaler

def state_set(state_date,data):
    # read data
    day = (data['datetime'] >= state_date) & (data['datetime'] < (state_date + timedelta(days=1)))
    state = data.loc[day]
    return state


def main():
    data = pd.read_csv("data/total_dataset.csv")
    data['datetime'] = pd.to_datetime(data['datetime'])
    # agent properties

    ##############
    # input date
    state_date = "2018-05-04"

###################
    state_date = datetime.strptime(state_date, "%Y-%m-%d")
    state = state_set(state_date, data)
    state_time = state['datetime']
    state_time.reset_index(drop=True, inplace=True)
    state_value = state['fwts']
    state_value.reset_index(drop=True, inplace=True)
#############################################
    #input variables
    agent_number = 20
    max_agent_number = 30 # for the line chart
    #rate = 1 / 10 ** 8
    capacity = 2000 #w
    discharge_hour = 1.5
################################
    discharging_list = [0] * agent_number
    peakshave_list = [0] * max_agent_number
    one_agent_benefit_list = [0] * max_agent_number

    Shaved_value = state_value.copy()
    for x in range(agent_number):

        discharging_time = Shaved_value.argmax()-int(discharge_hour*6)
        discharging_list[x]= discharging_time
        Shaved_value[discharging_time:discharging_time + int(discharge_hour * 12)] = Shaved_value[
                                                                      discharging_time:discharging_time + int(discharge_hour * 12)] - capacity / discharge_hour



    plt.plot(state_time, Shaved_value, 'b', label="Shaved Consumption")
    plt.plot(state_time, state_value, 'c', label="Acutal Consumption")
    dataframe_shave = {'Time':state_time,'Consumption':Shaved_value,'label':"Shaved Consumption"}
    df_shave = pd.DataFrame(dataframe_shave)
    dataframe_actual = {'Time':state_time,'Consumption':state_value,'label':"Acutal Consumption"}
    df_actual = pd.DataFrame(dataframe_actual)
    df = pd.concat([df_actual,df_shave])

    peak_shave = state_value.max() - Shaved_value.max()

    fig = px.line(df, x="Time", y="Consumption", color='label', title = "Peak Shaved: {0}W".format(peak_shave))

    #for discharging_time in discharging_list:
    #    discharge_start, = plt.plot(state_time[discharging_time], state_value[discharging_time], 'r*')
    dataframe_point = {"Time":state_time[discharging_list],"Consumption":state_value[discharging_list]}
    df_point = pd.DataFrame(dataframe_point)
    fig.add_traces(
        go.Scatter(
            x=df_point["Time"], y=df_point["Consumption"], mode="markers", name="Discharging start ", hoverinfo="skip", marker_color="black"
        )
    )

    fig.show()

if __name__ == "__main__":
    main()
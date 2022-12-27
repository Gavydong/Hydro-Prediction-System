from keras.models import load_model
import matplotlib

import matplotlib.pyplot as plt
import pandas as pd
from datetime import datetime
import plotly.graph_objects as go
from plotly.graph_objs import *
import plotly.express as px

from sklearn.preprocessing import StandardScaler
from datetime import timedelta
import numpy as np
import statistics as s
import multiprocessing as mp
import random
from sklearn.preprocessing import MinMaxScaler


def state_set(state_date, data):
    # read data
    day = (data['datetime'] >= state_date) & (data['datetime'] < (state_date + timedelta(days=1)))
    state = data.loc[day]
    return state


def graph_gen(dateSelected, agents, dis_hour, cap):
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
    # input variables
    agent_number = agents
    max_agent_number = 30  # for the line chart
    # rate = 1 / 10 ** 8
    capacity = cap  # w
    discharge_hour = dis_hour
    ################################
    discharging_list = [0] * agent_number
    peakshave_list = [0] * max_agent_number
    one_agent_benefit_list = [0] * max_agent_number

    Shaved_value = state_value.copy()
    for x in range(agent_number):
        discharging_time = Shaved_value.argmax() - discharge_hour * 6
        discharging_list[x] = discharging_time
        Shaved_value[discharging_time:discharging_time + discharge_hour * 12] = Shaved_value[
                                                                                discharging_time:discharging_time + discharge_hour * 12] - capacity / discharge_hour

    # Shaved_value is the daily curve after peak shave
    # state_value is the daily curve before
    x = []
    y = []
    for discharging_time in discharging_list:
        x.append(state_time[discharging_time])
        y.append(state_value[discharging_time])
    # discharging_time is a array contain all the discharging time in 5-min interval format (0-287)

    # plt.xlabel("Datetime")
    # plt.ylabel("Consumption(W)")
    # peak_shave = state_value.max() - Shaved_value.max()
    # plt.title("Peak Shaved: {0}W".format(peak_shave))

    layout = Layout(
        paper_bgcolor='rgba(0,0,0,0)',
        plot_bgcolor='rgba(0,0,0,0)'
    )

    fig = go.Figure(layout=layout, )

    fig.add_trace(go.Scatter(x=state_time, y=Shaved_value,
                             mode='lines',
                             name='Shaving', marker=dict(
            color='red',
            size=20,
            line=dict(
                color='red',
                width=10
            )
        )))
    fig.add_trace(go.Scatter(x=state_time, y=state_value,
                             mode='lines',
                             name='Consumption', marker=dict(
            color='Black',
            size=30,
            line=dict(
                color='black',
                width=30
            )
        )))

    fig.add_trace(go.Scatter(x=x, y=y,
                             mode='markers', name='Agent discharging time', marker=dict(
            color='yellow',
            size=15,
            line=dict(
                color='black',
                width=2
            )
        )))
    fig.update_layout(xaxis=dict(showgrid=False),
                      yaxis=dict(showgrid=False))
    fig.update_xaxes(title_text="Time")
    fig.update_yaxes(title_text="Energy")
    return fig, round(max(state_value), 2), round((max(state_value) - max(Shaved_value)), 2)


def update_graph_3(input_date, max_agent, discharging_time, capacity):
    data = pd.read_csv("data/total_dataset.csv")
    data['datetime'] = pd.to_datetime(data['datetime'])
    state_date = input_date
    max_agent_number = int(max_agent)
    discharging_time = int(discharging_time)
    capacity = int(capacity)
    discharge_hour = discharging_time
    one_agent_benefit_list = [0] * max_agent_number

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
        peakshave_list[i] = peak_shave
    for i in range(max_agent_number):
        if i == 0:
            one_agent_benefit_list[i] = peakshave_list[i] - 0
        else:
            one_agent_benefit_list[i] = peakshave_list[i] - peakshave_list[i - 1]

    dataframe = {"Number of Agents": range(1, max_agent_number + 1), "Peak Shaved": one_agent_benefit_list}
    df = pd.DataFrame(dataframe)
    # fig = px.line(df, x="Number of Agents", y="Peak Shaved", title="Expected Peak Shave increase for adding the agents")

    layout = Layout(
        paper_bgcolor='rgba(0,0,0,0)',
        plot_bgcolor='rgba(0,0,0,0)'
    )

    fig = go.Figure(layout=layout)
    fig.add_trace(go.Bar(x=df["Number of Agents"], y=df["Peak Shaved"],
                         mode='line',
                         name='Consumption', marker=dict(
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
    fig.update_yaxes(title_text="Peak Shaved")
    return fig


def update_graph_2(input_date, max_agent, discharging_time, capacity):
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
    dataframe = {"Number of Agents": range(1, max_agent_number + 1), "Peak Shaved (kW)": peakshave_list}
    df = pd.DataFrame(dataframe)
    layout = Layout(
        paper_bgcolor='rgba(0,0,0,0)',
        plot_bgcolor='rgba(0,0,0,0)'
    )

    fig = go.Figure(layout=layout)
    fig.add_trace(go.Scatter(x=df["Number of Agents"], y=df["Peak Shaved (kW)"],
                             mode='lines',
                             name='Consumption', marker=dict(
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

    one_agent_benefit_list = [0] * max_agent_number

    for i in range(max_agent_number):
        if i == 0:
            one_agent_benefit_list[i] = peakshave_list[i] - 0
        else:
            one_agent_benefit_list[i] = peakshave_list[i] - peakshave_list[i - 1]

    dataframe_2 = {"Number of Agents": range(1, max_agent_number + 1), "Peak Shaved (kW)": one_agent_benefit_list}
    df_2 = pd.DataFrame(dataframe_2)
    fig2 = go.Figure(layout=layout)
    fig2.update_layout(title_text='Expected Peak Shave increase for each adding Agent')
    fig2.add_trace(go.Scatter(x=df_2["Number of Agents"], y=df_2["Peak Shaved (kW)"],
                              mode='lines',
                              name='Consumption', marker=dict(
            color='Black',
            size=30,
            line=dict(
                color='black',
                width=30
            )
        )))

    fig2.update_layout(xaxis=dict(showgrid=False),
                       yaxis=dict(showgrid=False))
    fig2.update_xaxes(title_text="Number of Agents")
    fig2.update_yaxes(title_text="Peak Shaved (kW)")
    return fig, fig2, df


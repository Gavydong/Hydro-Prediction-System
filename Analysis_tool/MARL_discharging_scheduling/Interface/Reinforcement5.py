import base64
from datetime import date
import numpy as np
import pandas as pd
import dash
import base64
import statistics as s
from tensorflow.keras.models import load_model

from datetime import datetime
from datetime import timedelta
import numpy as np
import dash
import matplotlib.pyplot as plt
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from keras.models import load_model
from plotly.graph_objs import *
from sklearn.preprocessing import StandardScaler
import dash_bootstrap_components as dbc
from dash import dcc, html

def state_set(state_date, data):
    # read data
    day = (data['datetime'] >= state_date) & (data['datetime'] < (state_date + timedelta(days=1)))
    state = data.loc[day]
    return state

def act(model, state, action_size=144):
    options = model.predict(state)
    action = np.argmax(options[0])
    return action

def graph_gen(dateSelected,dishour,cap):



    #model_name_1 = "model_agent_1"
    #model_1 = load_model("models/" + model_name_1)
    #model_name_2 = "model_agent_2"
    #model_2 = load_model("models/" + model_name_2)
    #model_name_3 = "model_agent_3"
    #model_3 = load_model("models/" + model_name_3)
    #model_name_4 = "model_agent_4"
    #model_4 = load_model("models/" + model_name_4)
    #model_name_5 = "model_agent_5"
    #model_5 = load_model("models/" + model_name_5)
    # read data
    data = pd.read_csv("data/total_dataset.csv")
    data['datetime'] = pd.to_datetime(data['datetime'])
    # agent properties
    #rate = 1 / 10 ** 8
    capacity = cap  # 2000kwH
    discharge_hour = dishour
    # initialize state
    state_date = dateSelected # need to replace with arguement
    state_date = datetime.strptime(state_date, "%Y-%m-%d")
    state = state_set(state_date, data)
    state_time = state['datetime']
    state_time.reset_index(drop=True, inplace=True)
    state_value = state['fwts']
    state_value.reset_index(drop=True, inplace=True)


    scaler = StandardScaler()
    state_s = scaler.fit_transform(state[['fwts']])
    state = state_s.reshape(1, 288)
    state_date = state_date + timedelta(days=1)

    agent_number = 5
    ################################
    #action_1 = act(model_1, state)
    #action_2 = act(model_2, state)
    #action_3 = act(model_3, state)
    #action_4 = act(model_4, state)
    #action_5 = act(model_5, state)
    #discharge_1 = action_1 + 144
    #discharge_2 = action_2 + 144
    #discharge_3 = action_3 + 144
    #discharge_4 = action_4 + 144
    #discharge_5 = action_5 + 144

    #Shaved_value = state_value.copy()
    #Shaved_value[discharge_1:discharge_1 + discharge_hour * 12] = Shaved_value[
    #                                                              discharge_1:discharge_1 + discharge_hour * 12] - capacity / discharge_hour
    #Shaved_value[discharge_2:discharge_2 + discharge_hour * 12] = Shaved_value[
    #                                                              discharge_2:discharge_2 + discharge_hour * 12] - capacity / discharge_hour
    #Shaved_value[discharge_3:discharge_3 + discharge_hour * 12] = Shaved_value[
    #                                                              discharge_3:discharge_3 + discharge_hour * 12] - capacity / discharge_hour
    #Shaved_value[discharge_4:discharge_4 + discharge_hour * 12] = Shaved_value[
    #                                                              discharge_4:discharge_4 + discharge_hour * 12] - capacity / discharge_hour
    #Shaved_value[discharge_5:discharge_5 + discharge_hour * 12] = Shaved_value[
    #                                                              discharge_5:discharge_5 + discharge_hour * 12] - capacity / discharge_hour
    #reward = 0
    #reward += rate * capacity * (s.mean(Shaved_value[discharge_1:discharge_1 + 12]))
    #reward += rate * capacity * (s.mean(Shaved_value[discharge_2:discharge_2 + 12]))
    #reward += rate * capacity * (s.mean(Shaved_value[discharge_3:discharge_3 + 12]))
    #reward += rate * capacity * (s.mean(Shaved_value[discharge_4:discharge_4 + 12]))
    #reward += rate * capacity * (s.mean(Shaved_value[discharge_5:discharge_5 + 12]))

    #peak_shave = state_value.max() - Shaved_value.max()


    #trends = ['DERs - 5']

    # Create random data with numpy
    #import numpy as np
    discharging_list = [0] * agent_number
    charging_list = [0] * agent_number

    Shaved_value = state_value.copy()
    for x in range(agent_number):
        discharging_time = Shaved_value.argmax() - discharge_hour * 6
        discharging_list[x] = discharging_time
        Shaved_value[discharging_time:discharging_time + discharge_hour * 12] = Shaved_value[
                                                                                discharging_time:discharging_time + discharge_hour * 12] - capacity / discharge_hour
    #Charging
    for x in range(agent_number):
        charging_time = Shaved_value.argmin() - discharge_hour * 6
        charging_list[x] = charging_time
        Shaved_value[charging_time:charging_time + discharge_hour * 12] = Shaved_value[
                                                                                charging_time:charging_time + discharge_hour * 12] + capacity / discharge_hour

    #y = [state_value[discharge_1], state_value[discharge_2], state_value[discharge_3], state_value[discharge_4],
    #     state_value[discharge_5]]
    #x = [state_time[discharge_1], state_time[discharge_2], state_time[discharge_3], state_time[discharge_4],
    #     state_time[discharge_5]]
    x = []
    y = []
    for discharging_time in discharging_list:
        x.append(state_time[discharging_time])
        y.append(state_value[discharging_time])
    c_x = []
    c_y = []
    for charging_time in charging_list:
        c_x.append(state_time[charging_time])
        c_y.append(state_value[charging_time])
    #discharging_time is a array contain all the discharging time in 5-min interval format (0-287)

    layout = Layout(
        paper_bgcolor='rgba(0,0,0,0)',
        plot_bgcolor='rgba(0,0,0,0)'
    )
    fig = go.Figure(layout=layout)

    fig.add_trace(go.Scatter(x=state_time, y=Shaved_value,
                             mode='lines',
                             name='Shaving',marker=dict(
                color='red',
                size=20,
                line=dict(
                    color='red',
                    width=10
                )
            )))
    fig.add_trace(go.Scatter(x=state_time, y=state_value,
                             mode='lines',
                             name='Consumption',marker=dict(
                color='Black',
                size=30,
                line=dict(
                    color='black',
                    width=30
                )
            )))

    fig.add_trace(go.Scatter(x=x, y=y,
                             mode='markers',name='DER discharging time',marker=dict(
                color='yellow',
                size=15,
                line=dict(
                    color='black',
                    width=2
                ))))
    fig.add_trace(go.Scatter(x=c_x, y=c_y,
                             mode='markers', name='DER  charging time', marker=dict(
            color='blue',
            size=15,
            line=dict(
                color='black',
                width=2
            ))))
    fig.update_layout(xaxis=dict(showgrid=False),
                  yaxis=dict(showgrid=False))

    return fig,round(sum(state_value)/1000,2),round((sum(state_value)-sum(Shaved_value)))

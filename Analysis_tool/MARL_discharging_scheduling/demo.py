import dash
import dash_bootstrap_components as dbc
import dash_core_components as dcc
import dash_html_components as html
from dash.dependencies import Input, Output, State
from datetime import date
from keras.models import load_model
import matplotlib
import plotly.express as px

import matplotlib.pyplot as plt
import pandas as pd
from datetime import datetime
import plotly.express as px
import plotly.graph_objects as go
from sklearn.preprocessing import StandardScaler
from datetime import timedelta
import numpy as np
import statistics as s
import multiprocessing as mp
import random
from sklearn.preprocessing import MinMaxScaler
import plotly.express as px
def state_set(state_date,data):
    # read data
    day = (data['datetime'] >= state_date) & (data['datetime'] < (state_date + timedelta(days=1)))
    state = data.loc[day]
    return state
# the style arguments for the sidebar.
SIDEBAR_STYLE = {
    'position': 'fixed',
    'top': 0,
    'left': 0,
    'bottom': 0,
    'width': '20%',
    'padding': '20px 10px',
    'background-color': '#f8f9fa'
}

# the style arguments for the main content page.
CONTENT_STYLE = {
    'margin-left': '25%',
    'margin-right': '5%',
    'padding': '20px 10p'
}

TEXT_STYLE = {
    'textAlign': 'center',
    'color': '#191970'
}

CARD_TEXT_STYLE = {
    'textAlign': 'center',
    'color': '#0074D9'
}

controls = dbc.FormGroup(
    [
        html.P('Select Date', style={
            'textAlign': 'center'
        }),
        dcc.DatePickerSingle(
            id='input_date',
            date=date(2018, 5, 6)
        ),
        html.Br(),

        html.P('EV discharging time(hour)', style={
            'textAlign': 'center'
        }),
        dcc.Slider(
            id='discharging_time',
            min=0.5,
            max=5,
            step=0.5,
            value=1
        ),
        html.Br(),
        html.P('EV capacity(Wh)', style={
            'textAlign': 'center'
        }),
        dcc.Input(
            id='capacity',
            placeholder='Enter a value...',
            type='int',
            value='2000'
        ),
        html.Br(),
        html.P('The EV Discharging Rate:', style={
            'textAlign': 'center'
        }),
        html.Div(id='discharge_rate'),
        html.Br(),
        html.P('Number of Agents', style={
            'textAlign': 'center'
        }),
        dcc.Input(
            id='agent_number',
            placeholder='Enter a value...',
            type='int',
            value='10'
        ),
        html.Br(),
        html.P('Enter maximum Agents number', style={
            'textAlign': 'center'
        }),
        dcc.Input(
            id='max_agent',
            placeholder='Enter a value...',
            type='int',
            value='10'
        ),
    ]
)

sidebar = html.Div(
    [
        html.H2('Demo', style=TEXT_STYLE),
        html.Hr(),
        controls
    ],
    style=SIDEBAR_STYLE,
)

content_first_row = dbc.Row(
    [
        dbc.Col(
            dcc.Graph(id='graph_1'), md=12,
        )
    ]
)


content_second_row = dbc.Row(
    [
        dbc.Col(
            dcc.Graph(id='graph_2'), md=12,
        )
    ]
)
content_third_row = dbc.Row(
    [
        dbc.Col(
            dcc.Graph(id='graph_3'), md=12,
        )
    ]
)

content = html.Div(
    [
        html.H2('DEMO for analysis with EV number and Peak Shaving', style=TEXT_STYLE),
        html.Hr(),
        content_first_row,
        content_second_row,
        content_third_row
    ],
    style=CONTENT_STYLE
)

app = dash.Dash(external_stylesheets=[dbc.themes.BOOTSTRAP])
app.layout = html.Div([sidebar, content])

@app.callback(
    Output(component_id='discharge_rate', component_property='children'),
    Input('discharging_time', 'value'),
    Input('capacity', 'value')
)
def update_output_div(discharging_time,capacity):
    rate = float(capacity)/float(discharging_time)
    return f'{rate}W'


@app.callback(
    Output('graph_1', 'figure'),
    Input('input_date', 'date'),
    Input('agent_number', 'value'),
    Input('discharging_time', 'value'),
    Input('capacity', 'value'),
    )
def update_graph_1(input_date,agent_number, discharging_time, capacity):
    print(input_date)
    agent_number= int(agent_number)
    discharging_time = int(discharging_time)
    print(discharging_time)
    capacity = int(capacity)
    print(capacity)
    state_date = input_date
    ###################
    state_date = datetime.strptime(state_date, "%Y-%m-%d")
    state = state_set(state_date, data)
    state_time = state['datetime']
    state_time.reset_index(drop=True, inplace=True)
    state_value = state['fwts']
    state_value.reset_index(drop=True, inplace=True)
    #############################################
    discharge_hour = discharging_time
    discharging_list = [0] * agent_number
    Shaved_value = state_value.copy()
    for x in range(agent_number):
        discharging_time = Shaved_value.argmax() - int(discharge_hour * 6)
        discharging_list[x] = discharging_time
        Shaved_value[discharging_time:discharging_time + int(discharge_hour * 12)] = Shaved_value[
                                                                                     discharging_time:discharging_time + int(
                                                                                         discharge_hour * 12)] - capacity / discharge_hour


    # Shaved_value is the daily curve after peak shave
    # state_value is the daily curve before

    plt.plot(state_time, Shaved_value, 'b', label="Shaved Consumption")
    plt.plot(state_time, state_value, 'c', label="Acutal Consumption")
    dataframe_shave = {'Time': state_time, 'Consumption': Shaved_value, 'label': "Shaved Consumption"}
    df_shave = pd.DataFrame(dataframe_shave)
    dataframe_actual = {'Time': state_time, 'Consumption': state_value, 'label': "Acutal Consumption"}
    df_actual = pd.DataFrame(dataframe_actual)
    df = pd.concat([df_actual, df_shave])

    peak_shave = state_value.max() - Shaved_value.max()

    fig = px.line(df, x="Time", y="Consumption", color='label', title="Peak Shaved: {0}W".format(peak_shave))

    # for discharging_time in discharging_list:
    #    discharge_start, = plt.plot(state_time[discharging_time], state_value[discharging_time], 'r*')
    dataframe_point = {"Time": state_time[discharging_list], "Consumption": state_value[discharging_list]}
    df_point = pd.DataFrame(dataframe_point)
    fig.add_traces(
        go.Scatter(
            x=df_point["Time"], y=df_point["Consumption"], mode="markers", name="Discharging start ", hoverinfo="skip",
            marker_color="black"
        )
    )
    return fig


@app.callback(
    Output('graph_2', 'figure'),
    Input('input_date', 'date'),
    Input('max_agent', 'value'),
    Input('discharging_time', 'value'),
    Input('capacity', 'value')
)
def update_graph_2(input_date, max_agent, discharging_time, capacity):
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
        peakshave_list[i] = peak_shave
    dataframe = {"Number of Agents": range(1, max_agent_number + 1),"Peak Shaved": peakshave_list}
    df = pd.DataFrame(dataframe)
    fig = px.line(df, x="Number of Agents", y="Peak Shaved", title="Expected Peak Shaved for agent numbers")

    return fig


@app.callback(
    Output('graph_3', 'figure'),
    Input('input_date', 'date'),
    Input('max_agent', 'value'),
    Input('discharging_time', 'value'),
    Input('capacity', 'value')
)
def update_graph_3(input_date, max_agent, discharging_time, capacity):
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
            one_agent_benefit_list[i] = peakshave_list[i]-0
        else:
            one_agent_benefit_list[i] = peakshave_list[i]-peakshave_list[i -1]

    dataframe = {"Number of Agents": range(1, max_agent_number + 1),"Peak Shaved": one_agent_benefit_list}
    df = pd.DataFrame(dataframe)
    fig = px.line(df, x="Number of Agents", y="Peak Shaved", title="Expected Peak Shave increase for adding the agents")

    return fig


if __name__ == '__main__':
    data = pd.read_csv("data/total_dataset.csv")
    data['datetime'] = pd.to_datetime(data['datetime'])
    app.run_server(port='8085')
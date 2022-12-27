import base64
import statistics as s
import webbrowser
from datetime import datetime
from datetime import timedelta
import numpy as np

import dash
from dash import html
import dash_bootstrap_components as dbc
import matplotlib.pyplot as plt
import pandas as pd
import plotly.express as px
from dash import Input, Output, callback_context
from dash import dcc, html
from keras.models import load_model
from plotly.graph_objs import *
from sklearn.preprocessing import StandardScaler

#import sys

#print(sys.argv[1])

def state_set(state_date, data):
    # read data
    day = (data['datetime'] >= state_date) & (data['datetime'] < (state_date + timedelta(days=1)))
    state = data.loc[day]
    return state


def act(model, state, action_size=144):
    options = model.predict(state)
    action = np.argmax(options[0])
    return action

# read command line arguments

# def simulation():
reward_list = pd.read_csv("data/reward_save.csv")
# print(reward_list)
peak_shave_list = pd.read_csv("data/peak_shave.csv")
# print(peak_shave_list)
validation_peak_shave_list = pd.read_csv("data/validation_peak_shave.csv")
# reward_graph(reward_list)
# peak_shave_graph(peak_shave_list*3/4)
# peak_shave_graph(validation_peak_shave_list)

model_name_1 = "model_agent_1"
model_1 = load_model("models/" + model_name_1)
model_name_2 = "model_agent_2"
model_2 = load_model("models/" + model_name_2)
model_name_3 = "model_agent_3"
model_3 = load_model("models/" + model_name_3)
model_name_4 = "model_agent_4"
model_4 = load_model("models/" + model_name_4)
model_name_5 = "model_agent_5"
model_5 = load_model("models/" + model_name_5)
# read data
data = pd.read_csv("data/total_dataset.csv")
data['datetime'] = pd.to_datetime(data['datetime'])
# agent properties
rate = 1 / 10 ** 8
capacity = 2000  # 2000kwH
discharge_hour = 1
# initialize state
#state_date = sys.argv[1] # need to replace with arguement
state_date = "2018-05-01"
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

action_1 = act(model_1, state)
action_2 = act(model_2, state)
action_3 = act(model_3, state)
action_4 = act(model_4, state)
action_5 = act(model_5, state)
discharge_1 = action_1 + 144
discharge_2 = action_2 + 144
discharge_3 = action_3 + 144
discharge_4 = action_4 + 144
discharge_5 = action_5 + 144

Shaved_value = state_value.copy()
Shaved_value[discharge_1:discharge_1 + discharge_hour * 12] = Shaved_value[
                                                              discharge_1:discharge_1 + discharge_hour * 12] - capacity / discharge_hour
Shaved_value[discharge_2:discharge_2 + discharge_hour * 12] = Shaved_value[
                                                              discharge_2:discharge_2 + discharge_hour * 12] - capacity / discharge_hour
Shaved_value[discharge_3:discharge_3 + discharge_hour * 12] = Shaved_value[
                                                              discharge_3:discharge_3 + discharge_hour * 12] - capacity / discharge_hour
Shaved_value[discharge_4:discharge_4 + discharge_hour * 12] = Shaved_value[
                                                              discharge_4:discharge_4 + discharge_hour * 12] - capacity / discharge_hour
Shaved_value[discharge_5:discharge_5 + discharge_hour * 12] = Shaved_value[
                                                              discharge_5:discharge_5 + discharge_hour * 12] - capacity / discharge_hour
reward = 0
reward += rate * capacity * (s.mean(Shaved_value[discharge_1:discharge_1 + 12]))
reward += rate * capacity * (s.mean(Shaved_value[discharge_2:discharge_2 + 12]))
reward += rate * capacity * (s.mean(Shaved_value[discharge_3:discharge_3 + 12]))
reward += rate * capacity * (s.mean(Shaved_value[discharge_4:discharge_4 + 12]))
reward += rate * capacity * (s.mean(Shaved_value[discharge_5:discharge_5 + 12]))

peak_shave = state_value.max() - Shaved_value.max()

plt.plot(state_time, Shaved_value, 'b', label="Shaved Consumption")
plt.plot(state_time, state_value, 'c', label="Acutal Consumption")

plt.xlabel("Datetime")
plt.ylabel("Consumption(W)")
plt.title("Peak Shaved: {1}W".format(reward, int(2764)))
discharge_start_1, = plt.plot(state_time[discharge_1], state_value[discharge_1], 'r*')
discharge_start_2, = plt.plot(state_time[discharge_2], state_value[discharge_2], 'r*')
discharge_start_3, = plt.plot(state_time[discharge_3], state_value[discharge_3], 'r*')
discharge_start_4, = plt.plot(state_time[discharge_4], state_value[discharge_4], 'r*')
discharge_start_5, = plt.plot(state_time[discharge_5], state_value[discharge_5], 'r*')

# plt.legend([discharge_start_1,discharge_start_2,discharge_start_3,discharge_start_4,discharge_start_5],
#            ["discharge_start_1","discharge_start_2","discharge_start_3","discharge_start_4","discharge_start_5"])
# plt.show()

# app = dash.Dash(__name__, external_stylesheets=[dbc.themes.DARKLY],
#                 meta_tags=[{'name': 'viewport',
#                             'content': 'width=device-width, initial-scale=1.0'}]
#                 )

app = dash.Dash(external_stylesheets=[dbc.themes.LUX])

# the style arguments for the sidebar. We use position:fixed and a fixed width
SIDEBAR_STYLE = {
    "padding": "3rem 3rem",
    "background-color": "#eaecee",
}
trends = ['DERs - 5']
# add some padding.
CONTENT_STYLE = {
    "position": "fixed",
    "margin-left": "24rem",
    "margin-right": "2rem",
    "padding": "2rem 1rem",

}
df = pd.DataFrame({
    "Fruit": ["Apples", "Oranges", "Bananas", "Apples", "Oranges", "Bananas"],
    "Amount": [4, 1, 2, 2, 4, 5],
    "City": ["SF", "SF", "SF", "Montreal", "Montreal", "Montreal"]
})

fig = px.bar(df, x="Fruit", y="Amount", color="City", barmode="group", )

sidebar = html.Div(
    [
        html.H6("Multi Agent Coordinated Peak Shaving Simulation", className="display-4"),
        html.Hr(),
        html.P(
            "Simulation Characteristics : ", className="lead"
        ),

        html.Ul(id='my-list', children=[html.Li(html.H6(i)) for i in trends], ),
    ],
    style=SIDEBAR_STYLE,
)

import plotly.graph_objects as go

# Create random data with numpy
import numpy as np

y = [state_value[discharge_1], state_value[discharge_2], state_value[discharge_3], state_value[discharge_4],
     state_value[discharge_5]]
x = [state_time[discharge_1], state_time[discharge_2], state_time[discharge_3], state_time[discharge_4],
     state_time[discharge_5]]

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
                         mode='markers',name='Batteries',marker=dict(
            color='yellow',
            size=15,
            line=dict(
                color='black',
                width=2
            )
        )))
fig.update_layout(xaxis=dict(showgrid=False),
              yaxis=dict(showgrid=False)
)
content = html.Div([dcc.Graph(
    id='example-graph',
    figure=fig
)], style=CONTENT_STYLE)



table_header = [
    html.Thead(html.Tr([html.Th("DER ID"), html.Th("Time"),html.Th("kWh Discharged")]))
]

body = [html.Tr(children=[html.Td("DER"+str(i+1)),html.Td(str(x[i])),html.Td(str(y[i]/1000))]) for i in range(len(x))]

table_body = [html.Tbody(body)]

test_png = 'logo.png'
test_base64 = base64.b64encode(open(test_png, 'rb').read()).decode('ascii')
peakshaved = sum(np.subtract(state_value,Shaved_value))/1000
app.layout = html.Div([
    dbc.Row(dbc.Navbar([html.Center(html.Img(src='data:image/png;base64,{}'.format(test_base64),height="50%"))],style={"padding-left": "3rem"
})),
    dbc.Row([

        dbc.Col([
            html.H1("Multi Agent Coordinated Peak Shaving Simulation"),
            html.Br(),
            html.Br(),
            html.H4("DER's - 5"),
            html.Hr(),
            html.Br(),

            html.H4("Peak Shaved - "+str(peakshaved)+"kWh"),
            html.Hr(),
            html.Br(),

            html.H4("DER Discharging Time - "),
            # html.Ul(children=[html.Li(html.H6("DER"+str(i+1)+"\t\t"+str(x[i])+", "+str(y[i]/1000)+" kWh")) for i in range(len(x))]),
            # html.Button('Button 1', id='btn-nclicks-1', n_clicks=0),
            dbc.Table(table_header + table_body, bordered=False),
            html.Center(dbc.Button("Shutdown Simulation", color="danger", className="me-1",id='btn-nclicks-1')),
            html.Div(id='container-button-timestamp')


        ], width={'size': 3, 'order': 1},style= SIDEBAR_STYLE),

        dbc.Col([
            dcc.Graph(
                id='example-graph',
                figure=fig
            ,style={"height" : "90vh"})], width={'size': 9, 'order': 2}, )], justify='start'),  # Horizontal:start,center,end,between,around

],)

from flask import request

def shutdown_server():
    func = request.environ.get('werkzeug.server.shutdown')
    if func is None:
        raise RuntimeError('Not running with the Werkzeug Server')
    func()

@app.callback(
    Output('container-button-timestamp', 'children'),
    Input('btn-nclicks-1', 'n_clicks')
)
def displayClick(btn1):
    changed_id = [p['prop_id'] for p in callback_context.triggered][0]
    if 'btn-nclicks-1' in changed_id:
        shutdown_server()

if __name__ == '__main__':
    webbrowser.open_new("http://127.0.0.1:420/")
    app.run_server(debug=False, port=420)

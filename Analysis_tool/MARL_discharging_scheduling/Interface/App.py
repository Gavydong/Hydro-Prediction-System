import base64
import os
import statistics as s
import webbrowser
from datetime import datetime, date
from datetime import timedelta
import numpy as np
import dash
from flask import request
import dash_bootstrap_components as dbc
import matplotlib.pyplot as plt
import pandas as pd
import plotly.express as px
from dash import Input, Output, callback_context, dash_table
from dash import dcc, html
from keras.models import load_model
from plotly.graph_objs import *
from sklearn.preprocessing import StandardScaler
import sys

import MonthlyEffect
import MonthlyShave
import Reinforcement5
import BaseLayout
import GeneralModel

#Initialize Base Layout
app = BaseLayout.gen_layout()

#State Variables
initialized = False
currMonth = None
fig3 = None
df3 = None
#Place Holder Data
df = pd.DataFrame({
    "Fruit": ["Apples", "Oranges", "Bananas", "Apples", "Oranges", "Bananas"],
    "Amount": [4, 1, 2, 2, 4, 5],
    "City": ["SF", "SF", "SF", "Montreal", "Montreal", "Montreal"]
})
fig = px.bar(df, x="Fruit", y="Amount", color="City", barmode="group", )

#CallBacks
##Shutdown Callback
@app.callback(Output("serverstatus","children"),
              Input('shutdown', 'n_clicks')
              )
def shutdown(btn1):
    changed_id = [p['prop_id'] for p in callback_context.triggered][0]
    if 'shutdown' in changed_id:
        func = request.environ.get('werkzeug.server.shutdown')
        if func is None:
            raise RuntimeError('Not running with the Werkzeug Server')
        func()

##Date and Graph Update Based On Date Select
@app.callback(
    Output("datepicked","children"),
    Output("graph","figure"),
    Output("consumption","children"),
    Output("shaved","children"),
    Output("evs","children"),
    Input("slider","value"),
    Input('datepicker','date'),
    Input("capslider","value"),
    Input("hourslider","value")
)
def updateDisplay(agents,date_value,cap,hours):
    string_prefix = 'Date Selected: '
    date_object = date.fromisoformat(date_value)
    date_string = date_object.strftime('%B %d, %Y')
    # fig = Reinforcement5.graph_gen(str(date_value),5)
    if(int(agents)==5):
        fig,consumption,shaved = Reinforcement5.graph_gen(str(date_value),int(hours),int(cap))
        fig.update_layout(transition_duration=500)
    else:
        fig,consumption,shaved = GeneralModel.graph_gen(str(date_value),int(agents),int(hours),int(cap))
        fig.update_layout(transition_duration=500)
    return [html.H6(string_prefix + date_string)],fig,html.H5("Consumption for "+date_string+" \n"+str(consumption)+"kW"),html.H5("Peak Shaved using "+str(agents)+" Ev's \n"+str(shaved)+"kW"),"Number of Ev's Selected - "+str(agents)


@app.callback(
    Output("graph2","figure"),
    Output("graph3","figure"),
    Output("monthgraph","figure"),
    Output("TableDiv2","children"),
    Output("TableDiv3","children"),
    Input("slider","value"),
    Input('datepicker','date'),
    Input("capslider","value"),
    Input("hourslider","value")
)
def updateDisplay2(agents,date_value,cap,hours):
    string_prefix = 'Date Selected: '
    date_object = date.fromisoformat(date_value)
    date_string = date_object.strftime('%B %d, %Y')
    # fig = Reinforcement5.graph_gen(str(date_value),5)
    global fig3
    global df3
    global currMonth
    if(currMonth==None):
        currMonth = str(date_value).split("-")[1]
        print(currMonth)
        fig3, df3 = MonthlyEffect.monthlyAnalysis('-'.join(str(date_value).split("-")[0:2]), 30, int(hours), int(cap))
        fig3.update_layout(transition_duration=500)
        df3 = dbc.Table.from_dataframe(df3, striped=True, bordered=True, hover=True)
    elif (currMonth != str(date_value).split("-")[1]):
        currMonth = str(date_value).split("-")[1]
        # print("\n\nNew Date\n\n")
        fig3, df3 = MonthlyEffect.monthlyAnalysis('-'.join(str(date_value).split("-")[0:2]), 30, int(hours), int(cap))
        df3 = dbc.Table.from_dataframe(df3, striped=True, bordered=True, hover=True, )
        fig3.update_layout(transition_duration=500)

    fig2,fig2_2,df2 = GeneralModel.update_graph_2(str(date_value),int(agents),int(hours),int(cap))
    fig2.update_layout(transition_duration=500)
    df2 = dbc.Table.from_dataframe(df2, striped=True, bordered=True, hover=True,)


    return fig2,fig2_2,fig3,df2,df3


@app.callback(
    Output("monthlyshave","figure"),
    Output("TableDiv","children"),
    Input("slider","value"),
    Input('datepicker','date'),
    Input("capslider","value"),
    Input("hourslider","value")
)
def monthlyshavefunc(agents,date_value,cap,hours):
    # fig = Reinforcement5.graph_gen(str(date_value),5)
    fig4,df = MonthlyShave.genMonthlyshave('-'.join(str(date_value).split("-")[0:2]),int(agents),int(hours),int(cap))
    fig4.update_layout(transition_duration=500)

    # fig = dash_table.DataTable(df.to_dict('records'), [{"name": i, "id": i} for i in df.columns],style_data={'textAlign': 'center'},style_header={'textAlign': 'center'})
    # fig = df.to_html(classes=["table-bordered", "table-striped", "table-hover"])
    fig = dbc.Table.from_dataframe(df, striped=True, bordered=True, hover=True)
    return fig4,fig


if __name__ == '__main__':
    #webbrowser.open_new("http://127.0.0.1:420/")
    app.run_server(debug=True, port=420)

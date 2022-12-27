import base64
from datetime import date

import dash
import dash_bootstrap_components as dbc
from dash import dcc, html


def gen_layout():
    app = dash.Dash(external_stylesheets=[dbc.themes.LUX])

    #CSS
    SIDEBAR_STYLE = {
    'position': 'relative',
    'left': 0,
    'bottom': 0,
    'width': '100%',
    'height': '100%',
    'padding': '20px 10px',
    'background-color': '#f8f9fa'
    }
    CONTENT_STYLE = {
        "position": "static",

        "height": "100%"
    }




    #Logo
    test_png = 'logo.png'
    test_base64 = base64.b64encode(open(test_png, 'rb').read()).decode('ascii')

    #Components
    navbar = dbc.Navbar(id="Title Bar",
                        children = [html.Center(html.Img(src='data:image/png;base64,{}'.format(test_base64),height="10%"))],
                        style={"position":"static","padding-left": "1rem"})

    datepicker = dcc.DatePickerSingle(id='datepicker',
                        min_date_allowed=date(2018, 1, 1),
                        max_date_allowed=date(2020, 12, 31),
                        initial_visible_month=date(2018, 1, 1),
                        date=date(2018, 5, 6))


    slider = dcc.Slider(5, 30, 5,value=10,id='slider')
    capslider = dcc.Slider(2000, 5000, 1000,value=2000,id='capslider')
    hourslider = dcc.Slider(1, 5, 1,value=1,id='hourslider')


    shutdown = html.Center(dbc.Button("Shutdown Simulation", color="danger", className="me-1",id='shutdown'))

    sidebar = html.Div(id="sidebar",
                       children=[
                        html.H1("Multi Agent Coordinated Peak Shaving Simulation"),
                        html.Br(),
                        html.H6("Pick A Date - "),
                        datepicker,
                        html.Div(id='datepicked'),
                        html.Br(),
                        html.Hr(),
                        html.H6(id="evs",children="Number of EV'S Selected - 5"),
                        html.Div(id="sliderCon",children=[slider]),
                        html.Hr(),
                        html.Br(),
                        html.Div(children=[html.H6("EV discharging time(hour)"),hourslider]),
                        html.Hr(),
                        html.Br(),
                        html.Div(children=[html.H6("Battery Capacity"),capslider]),
                        html.Hr(),
                        html.Br(),
                        html.Div(id="consumption"),
                        html.Hr(),
                        html.Div(id="shaved"),
                        html.Hr(),
                        html.Br(),
                        html.Div(id="serverstatus"),
                        shutdown
                       ],style=SIDEBAR_STYLE)

    # graph = dcc.Graph(id='graph',style={"height" : "100%"})


    tabs = html.Div([
        dcc.Tabs([
            dcc.Tab(label='Single Day Peak Shaving Results', children=[
                html.Center(html.H5("Peak Shaving For the Day",style={"padding-top": "25px"})),
                dcc.Loading(
                    id="loading-1",
                    type="default",
                    children=dcc.Graph(id="graph",style={"height" : "100%"})
                ),
            ],),

            dcc.Tab(label='Single Month Peak Shaving Results', children=[
                html.Center(html.H5("Peak Shave Difference for the Entire Month",style={"padding-top": "25px"})),
                dcc.Loading(
                    id="loading-4",
                    type="default",
                    children=dcc.Graph(id="monthlyshave",style={"height" : "100%"})
                ),
                html.Div(id="TableDiv",style={'padding': '30px 30px',})
            ]),
            dcc.Tab(label='Accumulative Daily Peak Shaving Using Multiple EVs', children=[
                html.Center(html.H5("Expected Accumulative Daily Peak Shaving using Multiple EVs",style={"padding-top": "25px"})),
                dcc.Loading(
                    id="loading-2",
                    type="default",
                    children=dcc.Graph(id="graph2", style={"height": "100%"})
                ),
                dcc.Loading(
                    id="loading-2_2",
                    type="default",
                    children=dcc.Graph(id="graph3",style={"height" : "100%"})
                ),

                html.Div(id="TableDiv2",style={'padding': '30px 30px'})

            ]),
            dcc.Tab(label='Accumulative Monthly Peak Shaving Using Multiple Evs', children=[
                html.Center(html.H5("Accumulative Peak Shave Difference for the Entire Month Using Varying EVs",style={"padding-top": "25px"})),
                dcc.Loading(
                    id="loading-3",
                    type="default",
                    children=dcc.Graph(id="monthgraph",style={"height" : "100%"})
                ),
                html.Div(id="TableDiv3",style={'padding': '30px 30px'})

            ]),

        ])
    ])

    #App Layout
    app.layout = html.Div([
        navbar,
        dbc.Row([
            dbc.Col([
                sidebar
            ],width={'size': 3, 'order': 1}),

            dbc.Col([
                tabs
            ],width={'size': 9, 'order': 2})

        ],justify='start')
    ],style={"height":"100%"})

    return app


if __name__ == '__main__':
    gen_layout()

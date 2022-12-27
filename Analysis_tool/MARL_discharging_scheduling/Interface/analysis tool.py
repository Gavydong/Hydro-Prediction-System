from keras.models import load_model
import matplotlib

import matplotlib.pyplot as plt
import pandas as pd
from datetime import datetime

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
    discharge_hour = 1
################################
    discharging_list = [0] * agent_number
    peakshave_list = [0] * max_agent_number
    one_agent_benefit_list = [0] * max_agent_number

    Shaved_value = state_value.copy()
    for x in range(agent_number):

        discharging_time = Shaved_value.argmax()-discharge_hour*6
        discharging_list[x]= discharging_time
        Shaved_value[discharging_time:discharging_time + discharge_hour * 12] = Shaved_value[
                                                                      discharging_time:discharging_time + discharge_hour * 12] - capacity / discharge_hour

        print(discharging_time)

    plt.plot(state_time, Shaved_value, 'b', label="Shaved Consumption")
    plt.plot(state_time, state_value, 'c', label="Acutal Consumption")

    #Shaved_value is the daily curve after peak shave
    #state_value is the daily curve before

    for discharging_time in discharging_list:
        discharge_start, = plt.plot(state_time[discharging_time], state_value[discharging_time], 'r*')
    #discharging_time is a array contain all the discharging time in 5-min interval format (0-287)

    plt.xlabel("Datetime")
    plt.ylabel("Consumption(W)")
    peak_shave = state_value.max() - Shaved_value.max()
    plt.title("Peak Shaved: {0}W".format(peak_shave))

    plt.show()

    for i in range(max_agent_number):
        Shaved_value = state_value.copy()
        for x in range(i+1):
            discharging_time = Shaved_value.argmax() - discharge_hour * 6
            #discharging_list[x] = discharging_time
            Shaved_value[discharging_time:discharging_time + discharge_hour * 12] = Shaved_value[
                                                                                    discharging_time:discharging_time + discharge_hour * 12] - capacity / discharge_hour
        peak_shave = state_value.max() - Shaved_value.max()
        peakshave_list[i] = peak_shave

    plt.plot(range(1,max_agent_number+1), peakshave_list, 'b', label="Peak Shaved")
    plt.xlabel("Agent Number")
    plt.ylabel("Expected Peak Shaved(W)")
    plt.title("Expected Peak Shaved for agent numbers".format(peak_shave))
    plt.show()

    for i in range(max_agent_number):
        print(i)
        if i == 0:
            one_agent_benefit_list[i] = peakshave_list[i]-0
        else:
            one_agent_benefit_list[i] = peakshave_list[i]-peakshave_list[i -1]

    plt.plot(range(1,max_agent_number+1), one_agent_benefit_list, 'b', label="Peak Shaved")
    plt.xlabel("Agent Number")
    plt.ylabel("Expected Peak Shaved for the adding agent(W)")
    plt.title("Expected Peak Shave increase for adding the agents")
    plt.show()


if __name__ == "__main__":
    main()



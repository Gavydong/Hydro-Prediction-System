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
def reward_graph(reward_list):
    plt.plot(reward_list)
    plt.xlabel("Epochs")
    plt.ylabel("Total Reward")
    plt.title("Total Reward for each epoch")
    plt.show()

def peak_shave_graph(peak_shave_list):
    plt.plot(peak_shave_list)
    plt.xlabel("Epochs")
    plt.ylabel("Average Peak Shaved(W)")
    plt.title("Average Peak Shaved for each epoch")
    plt.show()

def state_set(state_date,data):
    # read data
    day = (data['datetime'] >= state_date) & (data['datetime'] < (state_date + timedelta(days=1)))
    state = data.loc[day]
    return state

def act(model,state,action_size=144):

    options = model.predict(state)
    action = np.argmax(options[0])
    return action
def main():
    reward_list = pd.read_csv("data/reward_save.csv")
    #print(reward_list)
    peak_shave_list = pd.read_csv("data/peak_shave.csv")
    #print(peak_shave_list)
    validation_peak_shave_list= pd.read_csv("data/validation_peak_shave.csv")
    #reward_graph(reward_list)
    peak_shave_graph(peak_shave_list*3/4)
    peak_shave_graph(validation_peak_shave_list)

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
    #read data
    data = pd.read_csv("data/total_dataset.csv")
    data['datetime'] = pd.to_datetime(data['datetime'])
    # agent properties
    rate = 1 / 10 ** 8
    capacity = 2000  # 2000kwH
    discharge_hour = 1
    # initialize state
    state_date = "2018-05-04"
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


    #options_1 = model_1.predict(state)  # ToDo: predict q-value of the current state
    #options_2 = model_2.predict(state)  # ToDo: predict q-value of the current state
    #options_3 = model_3.predict(state)  # ToDo: predict q-value of the current state

    # pick the action with highest probability
    #action_1 = np.argmax(options_1[0])  # ToDo: select the q-value with highest value
    #action_2 = np.argmax(options_2[0])  # ToDo: select the q-value with highest value
    #action_3 = np.argmax(options_3[0])  # ToDo: select the q-value with highest value
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

    plt.legend([discharge_start_1,discharge_start_2,discharge_start_3,discharge_start_4,discharge_start_5],
               ["discharge_start_1","discharge_start_2","discharge_start_3","discharge_start_4","discharge_start_5"])
    plt.show()
if __name__ == "__main__":
    main()
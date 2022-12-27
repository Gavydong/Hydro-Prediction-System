from keras.models import Sequential
from keras.models import load_model
from keras.layers import Dense
from keras.optimizers import Adam
import matplotlib.pyplot as plt
import csv
import numpy as np
import pandas as pd
import statistics as s
import numpy as np
import random
import time
from collections import deque
from datetime import datetime
from datetime import timedelta
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import MinMaxScaler
import os



def create_model(state_size,action_size):
    model = Sequential()
    model.add(Dense(units=512, input_dim=state_size, activation="relu"))
    model.add(Dense(units=256, activation="relu"))
    model.add(Dense(action_size, activation="linear"))
    model.compile(loss="mse", optimizer=Adam(learning_rate=0.001))

    return model
def state_set(state_date,data):
    # read data
    day = (data['datetime'] >= state_date) & (data['datetime'] < (state_date + timedelta(days=1)))
    state = data.loc[day]
    state_time = state['datetime']
    state_time.reset_index(drop=True, inplace=True)
    state_value = state['fwts']
    state_value.reset_index(drop=True, inplace=True)
    scaler = StandardScaler()
    state_s = scaler.fit_transform(state[['fwts']])
    state = state_s.reshape(1, 288)
    state_date = state_date + timedelta(days=1)
    return state,state_time,state_value

def act(model,state,epsilon,e,action_size=144):
    if np.random.rand() <= epsilon:
        # ToDo: select a random action
        #if e < 300:
        #    action = random.randrange(action_size)#absolute random
        #else:
            options = model.predict(state)
            scaler = MinMaxScaler()
            options = scaler.fit_transform(options[0].reshape(-1, 1))
            options = options.reshape(1, action_size)
            options = options / options.sum()
            options = (np.asarray(options[0]))
            action = random.choices(np.arange(action_size), options)#random based on nerual network
            action = int(action[0])
    else:
        # Predict what would be the possible action for a given state
        options = model.predict(state)  # ToDo: predict q-value of the current state

        # pick the action with highest probability
        action = np.argmax(options[0])  # ToDo: select the q-value with highest value
    return action

def validation_act(model,state,action_size=144):

    options = model.predict(state)
    action = np.argmax(options[0])
    return action
def model_fit(model,action,state,reward):
    predicted_target = model.predict(state)
    predicted_target[0][action] = reward
    model.fit(state, predicted_target, epochs=1, verbose=0)  # ToDo: train the model with new q_value
def main():
    #read data
    data = pd.read_csv("data/total_dataset.csv")
    data['datetime'] = pd.to_datetime(data['datetime'])
    #agent properties
    rate= 1/10**8
    capacity = 2000 #2000kwH
    discharge_hour=1
    #initialize state
    reward_list=[]
    peak_shave_list=[]
    validation_peak_shave_list=[]
    state_date = "2018-04-01"
    state_date = datetime.strptime(state_date,"%Y-%m-%d")
    #create model
    action_size = 144
    state_size=288
    model_1 = create_model(state_size=state_size,action_size= action_size)
    model_2 = create_model(state_size=state_size,action_size= action_size)
    model_3 = create_model(state_size=state_size,action_size= action_size)
    model_4 = create_model(state_size=state_size,action_size= action_size)
    model_5 = create_model(state_size=state_size,action_size= action_size)

    #action reward
    epsilon = 1.0
    epsilon_min = 0.01
    epsilon_decay = 0.996
    episode_count = 2000
    start_time = time.time()

    for e in range(episode_count + 1):
        total_reward=0
        total_peak_shave=0
        state_date = "2018-04-01"
        state_date = datetime.strptime(state_date, "%Y-%m-%d")
        while state_date<datetime.strptime("2018-05-01","%Y-%m-%d"):
            state,state_time,state_value = state_set(state_date, data)
            state_date=state_date+timedelta(days=1)

            action_1=act(model_1,state,epsilon,e)
            action_2=act(model_2,state,epsilon,e)
            action_3=act(model_3,state,epsilon,e)
            action_4=act(model_4,state,epsilon,e)
            action_5=act(model_5,state,epsilon,e)

            discharge_1 = action_1+144
            discharge_2 = action_2+144
            discharge_3 = action_3+144
            discharge_4 = action_4+144
            discharge_5 = action_5+144
            print("action_1:",state_time[discharge_1])
            print("action_2:",state_time[discharge_2])
            print("action_3:",state_time[discharge_3])
            print("action_4:",state_time[discharge_4])
            print("action_5:",state_time[discharge_5])
            Shaved_value = state_value.copy()
            Shaved_value[discharge_1:discharge_1 + discharge_hour*12] = Shaved_value[
                                                                    discharge_1:discharge_1 + discharge_hour*12] - capacity / discharge_hour
            Shaved_value[discharge_2:discharge_2 + discharge_hour * 12] = Shaved_value[
                                                                      discharge_2:discharge_2 + discharge_hour * 12] - capacity / discharge_hour
            Shaved_value[discharge_3:discharge_3 + discharge_hour * 12] = Shaved_value[
                                                                     discharge_3:discharge_3 + discharge_hour * 12] - capacity / discharge_hour
            Shaved_value[discharge_4:discharge_4 + discharge_hour * 12] = Shaved_value[
                                                                     discharge_4:discharge_4 + discharge_hour * 12] - capacity / discharge_hour
            Shaved_value[discharge_5:discharge_5 + discharge_hour * 12] = Shaved_value[
                                                                     discharge_5:discharge_5 + discharge_hour * 12] - capacity / discharge_hour
            reward=0
            temp_value = Shaved_value.copy()
            temp_value[discharge_1:discharge_1 + 12] =temp_value[discharge_1:discharge_1 + 12]+capacity / discharge_hour
            reward_1 = temp_value[action_size:].max()-Shaved_value[action_size:].max()
            temp_value = Shaved_value.copy()
            temp_value[discharge_2:discharge_2 + 12] =temp_value[discharge_2:discharge_2 + 12]+capacity / discharge_hour
            reward_2 = temp_value[action_size:].max()-Shaved_value[action_size:].max()
            temp_value = Shaved_value.copy()
            temp_value[discharge_3:discharge_3 + 12] =temp_value[discharge_3:discharge_3 + 12]+capacity / discharge_hour
            reward_3 = temp_value[action_size:].max()-Shaved_value[action_size:].max()
            temp_value[discharge_4:discharge_4 + 12] =temp_value[discharge_4:discharge_4 + 12]+capacity / discharge_hour
            reward_4 = temp_value[action_size:].max()-Shaved_value[action_size:].max()
            temp_value[discharge_5:discharge_5 + 12] =temp_value[discharge_5:discharge_5 + 12]+capacity / discharge_hour
            reward_5 = temp_value[action_size:].max()-Shaved_value[action_size:].max()
            reward=reward_1+reward_2+reward_3+reward_4+reward_5
            print("reward: ",reward)
            peak_shave = state_value.max() - Shaved_value.max()
            print("peak_shave: ", peak_shave)
            #fitting model
            model_fit(model_1, action_1, state, reward_1)
            model_fit(model_2, action_2, state, reward_2)
            model_fit(model_3, action_3, state, reward_3)
            model_fit(model_4, action_4, state, reward_4)
            model_fit(model_5, action_5, state, reward_5)
            total_reward += reward
            total_peak_shave += peak_shave

        if epsilon > epsilon_min:
            epsilon *= epsilon_decay
        reward_list.append(total_reward)
        peak_shave_list.append(total_peak_shave/30)

        validation_state = "2018-05-01"
        validation_state = datetime.strptime(validation_state, "%Y-%m-%d")
        validation_total_peak_shave=0
        while validation_state<datetime.strptime("2018-05-11","%Y-%m-%d"):
            state,state_time,state_value = state_set(validation_state, data)
            print(validation_state)
            action_1 = validation_act(model_1, state)
            action_2 = validation_act(model_2, state)
            action_3 = validation_act(model_3, state)
            action_4 = validation_act(model_4, state)
            action_5 = validation_act(model_5, state)
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
            validation_peak_shave = state_value.max() - Shaved_value.max()
            validation_total_peak_shave +=validation_peak_shave
            validation_state=validation_state+timedelta(days=1)
        validation_peak_shave_list.append(validation_total_peak_shave/10)

    end_time = time.time()
    training_time = round(end_time - start_time)
    print("Training took {0} seconds.".format(training_time))
    #print("reward list: ",reward_list)
    #print("peak_shave list: ", peak_shave_list)

    reward_save = pd.DataFrame(data={"reward": reward_list})
    reward_save.to_csv("data/reward_save.csv", sep=",", index=False)
    peak_shave_save = pd.DataFrame(data={"peak_shave": peak_shave_list})
    peak_shave_save.to_csv("data/peak_shave.csv", sep=",", index=False)
    validation_peak_shave_save = pd.DataFrame(data={"validation_peak_shave": validation_peak_shave_list})
    validation_peak_shave_save.to_csv("data/validation_peak_shave.csv", sep=",", index=False)
    if not os.path.exists("models"):
        os.mkdir("models")
    model_1.save("models/model_agent_1")
    model_2.save("models/model_agent_2")
    model_3.save("models/model_agent_3")
    model_4.save("models/model_agent_4")
    model_5.save("models/model_agent_5")
if __name__ == "__main__":
    main()
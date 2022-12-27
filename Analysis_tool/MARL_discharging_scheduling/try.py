import matplotlib.pyplot as plt
import csv
import numpy as np
import pandas as pd
import statistics as s

def main():
    data = pd.read_csv("data/total_dataset.csv")
    data['datetime']=  pd.to_datetime(data['datetime'])
    day = (data['date'] > '2018-04-01') & (data['date'] <= "2018-04-02")
    state = data.loc[day]
    state_time=state['datetime']
    state_time.reset_index(drop=True, inplace=True)
    state_value=state['fwts']
    state_value.reset_index(drop=True, inplace=True)
    max_value = state_value.max()
    max_index = state_value.idxmax()
    #Discharge action
    discharge_1=max_index+4
    discharge_2=max_index-3
    discharge_3=max_index-8
    #Shaved consumption calculation
    profit=0
    rate= 1/10**8
    capacity = 2000 #2000kwH
    discharge_hour=1

    Shaved_value = state_value.copy()
    Shaved_value[discharge_1:discharge_1+12] = Shaved_value[discharge_1:discharge_1+12]-capacity/discharge_hour
    Shaved_value[discharge_2:discharge_2+12] = Shaved_value[discharge_2:discharge_2+12]-capacity/discharge_hour
    Shaved_value[discharge_3:discharge_3+12] = Shaved_value[discharge_3:discharge_3+12]-capacity/discharge_hour

    #Profit calculation

    profit += rate*capacity*(s.mean(Shaved_value[discharge_1:discharge_1+12]))
    profit += rate*capacity*(s.mean(Shaved_value[discharge_2:discharge_2+12]))
    profit += rate*capacity*(s.mean(Shaved_value[discharge_3:discharge_3+12]))

    peak_shave = max_value - Shaved_value.max()
    #Plotting

    plt.plot(state_time, Shaved_value,'b',label="Shaved Consumption")
    plt.plot(state_time, state_value,'c',label="Acutal Consumption")

    plt.xlabel("Datetime")
    plt.ylabel("Consumption")
    plt.title("Total Profit: {0} , Peak Shaved: {1}kW".format(profit,int(peak_shave)))
    discharge_start_1, =plt.plot(state_time[discharge_1], state_value[discharge_1], 'r*')
    discharge_start_2, =plt.plot(state_time[discharge_2], state_value[discharge_2], 'r*')
    discharge_start_3, =plt.plot(state_time[discharge_3], state_value[discharge_3], 'r*')
    plt.legend([discharge_start_1,discharge_start_2,discharge_start_3], ["discharge_start_1","discharge_start_2","discharge_start_3"])
    plt.show()
if __name__ == "__main__":
        main()
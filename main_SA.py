# Copyright 2019-present Sejik Park

# Sejik Park
# July1, 2019
import os, argparse, glob, gc

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


def construct_param(parser):
    """
    # Subject: normal(M018-021), patient(Q003&5_all(1,4,8weeks))
    # Sensor position : 774A(Left ankle), 775F(Right ankle), 7756(Head), CC86(Left wrist), CC89(Right wrist), CD82(waist)
    # (LN, WR) * 9DOF_W (or Pitch, Roll, Yaw) - (gravity: need to check platform calculation)
    """

    # 1.5. Signal processing
    parser.add_argument('--sensor', default='9DOF_W_WR', type=str, help='which sensor to analyze')
    parser.add_arguemnt('--sectionN', default=9, type=int, help='how many sections in experience')
    # 1.6. Result
    parser.add_argument('--draw', default=1, type=int, help='plot 1 or not 0')
    parser.add_arugmnet('--result_name', default='wDiff.png', type=str, help='result picture name')

    args = parser.parse_args()

    # sensor list
    sensors = ['774A', '775F', '7756', 'CC86', 'CC89', 'CD82']
    args.sensors = sensors

    # experiment trigger order to skip(normal order 1~9)
    dic_remove_num = {
        'Q001_8': [8],
        'Q002_1': [6],  # 5 or 6 or 7
        'Q002_4': [3, 6, 10, 12],
        'Q003_1': [],
        'Q003_4': [],
        'Q004_1': [],
        'Q004_4': [],  # because repaired
        'Q005_1': [2],
        'Q005_4': [9, 10],
        'Q006_1': [3],
        'Q007_1': [3, 4, 6, 7, 9, 13],


        'M001': [2, 6],
        'M002': [7],
        'M003': [2, 11, 12, 13, 14],
        'M004': [2, 3, 5, 10, 11, 12, 13],
        'M005': [],

        'M007': [5],

        'M009': [5, 8],
        'M010': [],
        'M011': [8],
        'M012': [1, 10],
        'M013': [7, 10],
        'M014': [],
        'M015': [9],
        'M016': [1, 6],

        'M018': [],
        'M019': [],
        'M020': [],
        'M021': [],
    }
    args.dic_remove_num = dic_remove_num

    return args


def load_csv(args, filename):
    """
    load csv and data extraction
    ex.
    - Shimmer_[subject]_TimestampSync_Unix_CAL
    - Shimmer_[subject]_Quat_Madge_9DOF_WR
    - Shimmer_[subject]_Event_Marker_CAL
    """
    sep_char = ','
    skiprows = (0)
    with open(filename) as f:
        firstLine = f.readline()
        index = firstLine.find('sep=')
        if index != -1:
            sep_char = firstLine[index + 4]
            skiprows = (0,2)
        else:
            secondLine = f.readline()
            index = secondLine.find('ms')
            if index != -1:
                skiprows = (0, 1)
    df = pd.read_csv(filename, sep=sep_char, skiprows=skiprows, dtype=np.float64)

    # remove unnamed columns
    unname_columns = [col for col in df.columns if 'Unnamed:' in col]
    if 0 != len(unname_columns):
        df = df.drop(unname_columns, axis=1) # cdf[col_time]
    # col_time = [col for col in cdf.columns if 'TimestampSync_Unix_CAL' in col]
    col_sensor = [col for col in df.columns if args.sensor in col]  # future update: how to get sensor value
    col_EMName = [col for col in df.columns if 'Event_Marker' in col]
    df[col_EMName] = df[col_EMName].astype('int64')  # future update: int(marker) check
    return pd.concat([df[col_sensor], df[col_EMName]], axis=1) # cdf[col_time]

def getSplitIndexNPArray(df):
    """
    Split data with triggers
    """
    col_EMName = [col for col in df.columns if 'Event_Marker' in col]
    # series EVENT_MARKER
    sEM = df[col_EMName].iloc[:, 0]
    mask = 0b0100
    # replace
    sEM2 = sEM.where(sEM & mask != mask, mask)
    sEM2_diff = sEM2.diff()
    sEM_filtered = sEM2_diff[sEM2_diff != 0].dropna(how='all')
    isa = np.array(sEM_filtered.index).reshape((-1, 2))
    return isa


def plotResult(args, path_output, average_data, subject_name, exercise_num, sensor_name):
    """
    future update: need to pass sensor and subject information (or change the order and remake)
    x: subject
    y: value(F_W average(time domain)
    c: experiment
    """
    sensor_index = set(sensor_name)
    exercise_index = set(exercise_num)

    plt.rcParams["figure.figsize"] = (18, 12)
    fig = plt.figure()
    sensorNum = len(sensor_index)
    exerciseNum = len(exercise_index)
    for i, ax in enumerate(sensor_index):
        for j, ay in enumerate(exercise_index):
            nowP = fig.add_subplot(sensorNum, exerciseNum, exerciseNum*i+j+1)
            nowY = []
            nowX = []
            for w in range(len(sensor_name)):
                if (ax == sensor_name[w]) & (ay == exercise_num[w]):
                    nowY.append(average_data[w])
                    nowX.append(subject_name[w])
            nowP.bar(nowX, nowY)
    # plt.suptitle("row:sensor, column:experiment")
    # plt.xlabel("ankleL, R, head, wristL, R, waist")
    # plt.ylabel("normal, velocity, visionLR, UD, action1, 2, 3, 4, 5")
    plt.show()
    fig = plt.gcf()
    saveDir = path_output + args.result_name
    fig.savefig(saveDir)



if __name__ == '__main__':
    """
    1. Parameters
    2. Paths
    3. Load data
    4. Preprocessing
    5. Signal processing
    6. Result
    """

    ## 1. Parameters
    parser = argparse.ArgumentParser()
    args = construct_param(parser)

    ## 2. Paths
    path_h = '/Users/sejik/Documents/VR_Programming'
    path_input = os.path.join(path_h, '*', '*', '*.csv')
    path_output = os.path.join(path_h, 'Result')
    if not os.path.exists(path_output):
        os.mkdir(path_output)

    ds_option = 'w'
    average_data = []
    subject_name = []
    exercise_num = []
    sensor_name = []

    ## 3. Load data
    dataNum = 0
    for filename in glob.iglob(path_input, recursive=True):
        filename = filename.replace(os.sep, '/')
        if os.path.isfile(filename):
            print('processing for [{}]'.format(filename), end='')
            df = load_csv(args, filename)
            splitIndexArr = getSplitIndexNPArray(df)
            print('. has {} sections.'. format(len(splitIndexArr)), end='\n')

            dest_file_name = os.path.splitext(os.path.basename(filename))[0]

            # check unusable trigger
            index_shimmer = dest_file_name.find("Shimmer")
            if index_shimmer != -1:
                person_ID = dest_file_name[:index_shimmer - 1]
            else:
                person_ID = dest_file_name[:4]

            remove_nums = args.dic_remove_num.get(person_ID, [])

            if person_ID.find('Q0') > -1:
                person_ID = 'patient'
            else:
                person_ID = 'normal'

            currentSensor = ''
            for i, sensorCurrent in enumerate(args.sensorList):
                if dest_file_name.find(sensorCurrent) > -1:
                    currentSensor = sensorCurrent

            # check number of triggers
            if len(splitIndexArr) - len(remove_nums) != args.sectionN:
                print('{} has not {} exer!!'.format(filename, args.sectionN), end='\n')
                continue

            # subject data analysis
            exerNumCounter = 1
            for splitI in range(0, len(splitIndexArr)):
                if (splitI + 1) in remove_nums:
                    continue
                splitIndex = splitIndexArr[splitI]
                rdf = df.iloc[splitIndex[0]:splitIndex[1], :]
                rdf = np.abs(rdf)
                col_sensor = [col for col in df.columns if args.sensor in col]
                cur_mean = rdf[col_sensor].mean().values.tolist()
                average_data.append(cur_mean[0])
                subject_name.append(person_ID)
                exercise_num.append(exerNumCounter)
                sensor_name.append(currentSensor)

                exerNumCounter += 1
            del [[df]]  # divide section with trigger
            gc.collect()
            df = pd.DataFrame()
        dataNum += 1
        plotResult(average_data, subject_name, exercise_num, sensor_name)


    ## 4. Preprocessing

    ## 5. Signal processing

    ## 6. Result


# 1. BERT
# 1-1. Parameters
# 1-2. Seq-toSQL module parameters
# 1-3. Execution-guided decoding beam-size. It is used only in test.py

# Decide whether to use lower_case
# Seeds for random number generation

# 모델 구성을 어떻게 할 지
# 변수 설명을 어디서 얼만큼 할 것인가
# csv 파일을 어떻게 얻어올 것인지
# 변수를 get field로 구성하는 방법

# report 부분을 분리해서 진행
# shimmer 정보 분석해서 진행

# parameter 설정
# load_csv
# getSplitIndexNPArray
# plotResult


# -*- coding: utf-8 -*-
import glob
import os
import pandas as pd
import numpy as np
import gc
import matplotlib.pyplot as plt
import matplotlib as mpl
import seaborn as sns
import statsmodels.api as sm
import warnings; warnings.filterwarnings(action='once')

# 실험대상 : 정상인 M018-021, 환자 Q003_all(1,4,8주), Q005_all(1,4,8주)
# 센서기준 : 7756 (이후, 복합 관계 분석 예정)
# 센서기준 참조 : 774A(왼쪽 발목), 775F(오른쪽 발목), 7756(머리), CC86(왼쪽 손목), CC89(오른쪽 손목), CD82(허리)
# 센서 세부사항(분석 대상) : (LN, WR) * 9DOF_W (이후, Pitch, Roll, Yaw 분석 예정) - (중력 방향 가속도 제거 : 한재 형 확인 부탁)
# 기타 방안 : 움직임 겹쳐서 동영상 만들기, 전정 시뮬레이션

# 트리거 제거 기준 목록 (시작점 : 1)
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

# 파일위치, 결과생성위치, 분석센서
target_path = '/Users/sejik/Documents/VR_Programming/*/*/*.csv'
dest_root_dir = '/Users/sejik/Documents/VR_Programming/Segmented/'
sensor_choose = '9DOF_W_WR'
experimentCase = 9
sensorList = ['774A', '775F', '7756', 'CC86', 'CC89', 'CD82']
resultName = 'wDiff.png'


def load_csv(target_filepath):
    """
        csv에서 필요한 부분만 나누어 주는 function
        받아올 부분 : Shimmer_실험대상_TimestampSync_Unix_CAL, Shimmer_실험대상_Quat_Madge_9DOF_WR, Shimmer_실험대상_Event_Marker_CAL
        """
    sep_char = ','
    skiprows = (0)
    
    with open(target_filepath) as f:
        firstLine = f.readline()
        index = firstLine.find('sep=')
        
        if index != -1:
            sep_char = firstLine[index + 4]
            skiprows = (0, 2)
        else:
            secondLine = f.readline()
            index = secondLine.find('ms')
            
            if index != -1:
                skiprows = (0, 1)

df = pd.read_csv(target_filepath, sep=sep_char, skiprows=skiprows, dtype = np.float64)

# remove unnamed columns
unname_columns = [col for col in df.columns if 'Unnamed:' in col]
    if 0 != len(unname_columns):
        df = df.drop(unname_columns, axis=1)

# col_time = [col for col in cdf.columns if 'TimestampSync_Unix_CAL' in col]
col_sensor = [col for col in df.columns if sensor_choose in col]  # 센서값 입력 수정 예정
col_EMName = [col for col in df.columns if 'Event_Marker' in col]
df[col_EMName] = df[col_EMName].astype('int64')  # Marker 관련 int 수정

df_test = pd.concat([df[col_sensor], df[col_EMName]], axis=1) # cdf[col_time]
return df_test


def getSplitIndexNPArray(df):
    """
        트리거별로 데이터를 나누는 과정
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


def plotResult(average_data, subject_name, exercise_num, sensor_name):
    # 센서와 피험자별에 대한 부분을 전달할 필요가 있음 (아니면 순서를 정해서 다시만들어 주거나)
    # x: 피험자
    # y: 값(F_W의 평균(시간적인 평균))
    # c: 실험
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
    saveDir = dest_root_dir + resultName
    fig.savefig(saveDir)



if __name__ == '__main__':
    """
        1. CSV 읽어오기
        2. CSV 값에서 필요한 부분만 가져오기
        3. 실험에 따라 나누어주기
        4. 실험에 따라 나누어준 값에서 평균 구하기(또는 빈도를 그려주기)
        예상 그래프
        가로 : 실험별+피험자별+센서별 가로
        세로 : 9DOF_W(시간별 데이터, 크기 빈도별 색깔)
        5. 피험자에 따라 평균내기 (1~4번 반복을 어떻게 할 것인가?)
        """
    
    # 전체적인 정보를 저장할 공간 만들기
    
    # 결과 저장 공간 확인
    if not os.path.exists(dest_root_dir):
        os.mkdir(dest_root_dir)

    ds_option = 'w'

average_data = []
subject_name = []
exercise_num = []
sensor_name = []

# 파일위치에 따른 분석 진행 (센서별 + 피험자별)
dataNum = 0
    for a_path in glob.iglob(target_path, recursive=True):
        target_filepath = a_path.replace(os.sep, '/')
        
        if os.path.isfile(target_filepath):
            print('processing for [{}]'.format(target_filepath), end='')
            
            # 데이터 읽어오기
            df = load_csv(target_filepath)
            splitIndexArr = getSplitIndexNPArray(df)
            
            print('. has {} exer.'.format(len(splitIndexArr)), end='\n')
            
            
            
            
            
            dest_file_name = os.path.splitext(os.path.basename(target_filepath))[0]
            
            # 실험자별로 제거해야할 트리거 파악
            index_shimmer = dest_file_name.find("Shimmer")
            if index_shimmer != -1:
                person_ID = dest_file_name[:index_shimmer - 1]
            else:
                person_ID = dest_file_name[:4]
        
            remove_nums = dic_remove_num.get(person_ID, [])
            
            if person_ID.find('Q0') > -1:
                person_ID = 'patient'
    else:
        person_ID = 'normal'
            
            currentSensor = ''
            for i, sensorCurrent in enumerate(sensorList):
                if dest_file_name.find(sensorCurrent) > -1:
                    currentSensor = sensorCurrent
        
            # 트리거 갯수 파악
            if len(splitIndexArr) - len(remove_nums) != experimentCase:
                print('{} has not {} exer!!'.format(target_filepath, experimentCase), end='\n')
                continue


# 트리거 분별 실험자별 데이터 분석
exerNumCounter = 1
    for splitI in range(0, len(splitIndexArr)):
        if (splitI + 1) in remove_nums:
            continue
                splitIndex = splitIndexArr[splitI]
                rdf = df.iloc[splitIndex[0]:splitIndex[1], :]
                rdf = np.abs(rdf)
                col_sensor = [col for col in df.columns if sensor_choose in col]
                cur_mean = rdf[col_sensor].mean().values.tolist()
                average_data.append(cur_mean[0])
                subject_name.append(person_ID)
                exercise_num.append(exerNumCounter)
                sensor_name.append(currentSensor)
                
                exerNumCounter += 1
            del [[df]]  # trigger 에 따라 운동별로 분별
            gc.collect()
            df = pd.DataFrame()
        dataNum += 1
    plotResult(average_data, subject_name, exercise_num, sensor_name)

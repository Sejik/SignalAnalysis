from matplotlib import pyplot as plt
import numpy as py
# sklearn의 load_iris로 데이터를 로드한다.
from sklearn.datasets import load_iris
data = load_iris()
# load_iris는 몇 개의 필드를 가진 객체를 반환한다.
features = data.data
feature_names = data.feature_names
target = data.target
target_names = data.target_names
for t in range(3):
    if t==0:
        c='r'
        marker='>'
    elif t ==1:
        c='g'
        marker='o'
    elif t==2:
        c='b'
        marker='x'
    plt.scatter(features[target==t,0],
                features[target==t,1],
                marker=marker,
                c=c)
plt.show()
print()
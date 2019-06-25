This is nononchanging

git test

import scipy as sp
daya = sp.genfromtx("wev_traffic.tsv", delimiter="\t")
print(data[:10])
print(data.shape)

x = data[:,0]
y = data[:,1]

sp.sum(sp.isnan(y))

x = x[~sp.isnan(y)]
y = y[~sp.isnan(y)]

import matplotlib.pyploy as plt
plt.scatter(x, y, s=10)
plt.title("Web traffic over the last month")
plt.xlabel("Time")
plt.ylable("Hits/hour")
plt.xticks([w*7*24 for w in range(10)], ['week %i' % w for w in range(10)])
plt.autoscale(tight=True)
plt.grid(True, linestyle='-', color='0.75')
plt.show()

def error(f,x, y):
    return sp.sum((f(x)-y)**2)

fp1, residuals, rank, sv, rcond = sp.polyfit(x, y, 1, full=True)
print("Model parameters: %s" % fp1)
print(residuals)

f1 = sp.poly1d(fp1)
print(error(f1, x, y))

fx = sp.linspace(0, x[-1], 1000) # 도표를 위한 x 값을 생성하낟.
plt.plot(fx, f1(fx), linewidth=4)
plt.legend(["d=%i" % f1.order], loc="upper left")

f2p = sp.polyfit(x, y, 2)
print(f2p)
f2 = sp.poly1d(f2p)
print(error(f2, x, y))

inflection = 3.5*7*24
xa = x[:inflection]
ya = y[:inflection]
xb = x[inflection:]
yb = y[inflection:]

fa = sp.poly1d(sp.polyfit(xa, ya, 1))
fb = sp.poly1d(sp.polyfit(xb, yb, 1))
fa_error = error(fa, xa, ya)
fb_error = error(fb, xb, yb)
print("Error inflection=%f" % (fa_error + fb_error))

fbt2 = sp.poly1d(sp.polyfit(xb[train], yb[train], 2))
print("fbt2(x)= \n%s" % fbt2)
from scipy.optimize import fsolve
researched_max = fsolve(fbt2-100000, x0=800)/(7*24)
print("100,000 hits/hour expected at week %f" % reached_max[0])

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

# 문자열 배열을 얻기 위해 Numpy 인덱스를 사용한다
labels = target_names[target]

# 꽃잎 길이는 2번째에 있는 속성이다.
plength = feature[:,2]

# 불 배열을 만든다.
is_setosa = (labels == 'setosa')

# 이 부분이 중요한 단계

#!/opt/rh/python33/root/usr/bin/python
#-*- coding: utf-8 -*-

import os
import h5py
import numpy as np
import pandas as pd

from sklearn import svm
from sklearn.neighbors.nearest_centroid import NearestCentroid
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis as lda
from sklearn import tree


def getDataFiles(fileDir = './data/'):
	files = os.listdir(fileDir)
	yidx = np.arange(1,7)
	xtrs = []; ytrs=[]; xtes=[]; ytes=[];
	for _file in files:
		dsets = h5py.File(fileDir+_file,'r')
		xtr = np.array(dsets['fvTrTe/trainx'])
		ytr = np.array(dsets['fvTrTe/trainy'])
		xte = np.array(dsets['fvTrTe/testx'])
		yte = np.array(dsets['fvTrTe/testy'])
		#xtr = normalize(xtr,axis=0)
		#xte = normalize(xte,axis=0)

		ytr = np.sum(ytr * yidx, axis=1)
		yte = np.sum(yte * yidx, axis=1)

		xtrs.append(xtr)
		ytrs.append(ytr)
		xtes.append(xte)
		ytes.append(yte)

	return xtrs,ytrs,xtes,ytes, files


from sklearn.preprocessing import normalize
def exeML(mlmethod,xtr, ytr, xte,yte, islog = True,isfeatureselection = True):
	if islog:
		xtr = np.log(np.abs(xtr)).tolist()
		ytr = np.log(np.abs(ytr)).tolist()
		xte = np.log(np.abs(xte)).tolist()
		yte = np.log(np.abs(yte)).tolist()

	if isfeatureselection:
		estimator = SVR(kernel = "linear")
		selector = RFE(estimator, 100, step=1)
		selector = selector.fit(xtr,ytr)
		xtr = np.array(xtr)[:,selector.support_].tolist()
		xte = np.array(xte)[:,selector.support_].tolist()

	np.random.seed(1000)
	if mlmethod =="SVM":
		clf = svm.SVR(kernel = 'poly')
	elif mlmethod =="NeaNei":
		clf = NearestCentroid()
	elif mlmethod == "dtree":
		clf = tree.DecisionTreeClassifier()
	elif mlmethod == "lda":
		clf = lda(solver="svd")

	predval = []
	clf.fit(xtr,ytr)

	for i in range(len(xte)):
		predval.append(np.float(clf.predict(xte[i])))

	return predval


def analRes(yte, predval, islog=True):
	if islog:
		predval = np.round(np.exp(predval))
	else:
		predval = np.round(predval)
	correctcnt = len(yte) - np.count_nonzero(yte - predval)
	return correctcnt



def startML(files, mlmethods, xtes, xtrs, ytes, ytrs):

	for islog in [False]:
		for isfeatureselection in [False]:
			expres = []
			expsumres = []
			expreslog = []
			for i in range(len(files)):
				_file = files[i]
				xtr = xtrs[i]
				ytr = ytrs[i]
				xte = xtes[i]
				yte = ytes[i]
				#print(_file)
				mthdres = []
				for mlmethod in mlmethods:
					predval = exeML(mlmethod, xtr, ytr, xte, yte, islog, isfeatureselection)
					correctcnt = analRes(yte, predval, islog)
					# print(mlmethod +"'s correct counts:" + str(correctcnt))
					mthdres.append(correctcnt)
				if len(expres) != 0 and i % 4 == 0:
					expsumres.append(np.sum(expres,axis=0).tolist())
					expres = []
				expres.append(mthdres)
				expreslog.append(mthdres)
			expsumres.append(np.sum(expres,axis=0).tolist())
			dfres = pd.DataFrame(expsumres) / 240
			dflogres = pd.DataFrame(expreslog)
			dfres.columns = mlmethods
			print('isLog: ' + str(islog)+', isfeatureselection: ' + str(isfeatureselection))
			print(dfres)
			print(dflogres)
	return

def init():
	mlmethods = ["SVM","NeaNei","dtree","lda"]
	xtrs,ytrs,xtes,ytes,files = getDataFiles()
	startML(files, mlmethods, xtes, xtrs, ytes, ytrs)


init()

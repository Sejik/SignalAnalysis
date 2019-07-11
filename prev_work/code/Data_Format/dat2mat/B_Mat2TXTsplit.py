#!/opt/rh/python33/root/usr/bin/python
#-*- coding: euc-kr -*-

import os, sys, re
import h5py
import numpy as np
import pandas as pd

from sklearn import svm
from sklearn.neighbors.nearest_centroid import NearestCentroid
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis as lda
from sklearn import tree

StdOutWt	=	sys.stdout.write					# nmemonics
StdErrWt	=	sys.stderr.write					# nmemonics

def process_IN(fDir, fHead, nFold):
#def getDataSbj(fDir, fHead, nFold):
# sbj / cond 의 조합에 따라 fold 데이터들을 읽어서 하나로 합쳐 리턴

#	eEEG, eMRK, eCHN, eFS	=	([], [], [], [])
	eEEG		=	np.zeros(0).reshape(0,0,0)	# 3D array
	eMRK		=	np.zeros(0).reshape(0,0)	# 1D like 2D array
	eCHN		=	[]							# 1D list
	eFS			=	np.zeros(0).reshape(0,0)	# 1D like 2D array
#	print(eEEG.shape)

	for idx in range(1, nFold+1):
		fName	=	'%s_%1d.mat' % (fHead, idx)
		print('loading the dataset from %s' % fName)
		dsets	=	h5py.File(fDir + fName, 'r')

		eEEG_	=	np.array(dsets['eEEG'])

		sp1, sp2=	(eEEG.shape, eEEG_.shape)
		eEEGn	=	np.zeros((sp1[0]+sp2[0], sp2[1], sp2[2]))
		eEEGn[		:sp1[0],		:sp1[1],	:sp1[2]]	=	eEEG
		eEEGn[sp1[0]:sp1[0]+sp2[0],	:,			:]			=	eEEG_
		eEEG	=	eEEGn

		eMRK_	=	np.array(dsets['eMRK'])
		sp1, sp2=	(eMRK.shape, eMRK_.shape)
		eMRKn	=	np.zeros((sp1[0]+sp2[0], sp2[1]))
		eMRKn[		:sp1[0],		:sp1[1]]	=	eMRK
		eMRKn[sp1[0]:sp1[0]+sp2[0],	:]			=	eMRK_
		eMRK	=	eMRKn

		eCHN_	=	dsets['eCHN']
		eCHNn	= []
		for column in eCHN_:					# for HDF5 obj ref
			eCHNn.append(''.join(map(chr, dsets[column[0]][:])))
		eCHN.append(eCHNn)

		eFS_	=	np.array(dsets['eFS' ])
		sp1, sp2=	(eFS.shape, eFS_.shape)
		eFSn	=	np.zeros((sp1[0]+sp2[0], sp2[1]))
		eFSn[		:sp1[0],		:sp1[1]]	=	eFS
		eFSn[sp1[0]:sp1[0]+sp2[0],	:]			=	eFS_
		eFS		=	eFSn

#		print(eEEG.shape)
#		print(eMRK.shape)
#		print(len(eCHN))
#		print(eFS.shape)

	return eEEG, eMRK, eCHN, eFS

import concurrent
def getDataFiles(fDir = './data/', fHd = '', lSBJ=[1], sCond = [''], nFold = 1):
#	files	=	os.listdir(fDir)
#	files	=	filter(lambda x: x[-4:] == '.mat', files)

	eSBJs, eEEGs, eMRKs, eCHNs, eFSs	=	([], [], [], [], [])

	# callapsing 4 folding file to one file
	# subject * cond 별로 병렬화 수행한다.
#	print( list(files) )
	for sbj in lSBJ:
		for cond in sCond:
			fHead		=	re.sub('_$', '', '%s_su%04d_%s' % (fHd, sbj, cond))
			eSBJs.append(fHead)

	with concurrent.futures.ProcessPoolExecutor(max_workers=20) as exe:
		fs	=	{exe.submit(process_IN, fDir, HEAD, nFold) for HEAD in eSBJs}
		done, _	=	concurrent.futures.wait(fs)
		result	=	(f.result() for e in done)
		print(result)

		result = 0
		for i in exe.map(partial(process_IN, r=r), range(0, 2000000, r)):
			result += i
			print(result)
		print(result)


		'''
		eEEG, eMRK, eCHN, eFS	=	getDataSbj(fDir, fHead, nFold)
		eEEGs.append(eEEG)
		eMRKs.append(eMRK)
		eCHNs.append(eCHN)
		eFSs.append(eFS)
		'''

	return eSBJs, eEEGs, eMRKs, eCHNs, eFSs

def process_OUT(n, r=10000):
    print("processing: {} ..< {}".format(n, n+r), end="... ")
    s = sum((x for x in range(n, n+r) if is_prime(x) if x <= 2000000))
    print(s)
    return s

def putDataFiles(PATH, eSBJs, eEEGs, eMRKs, eCHNs, eFSs):

	for ix in range(len(eSBJs)):
		if not os.path.isdir(PATH + eSBJs[ix]):
			os.mkdir(PATH + eSBJs[ix])					# first, make directory

		eEEG			=	eEEGs[ix]					# np.array 3D
		eCHN			=	eCHNs[ix]					# list 2D
		eFS			=	eFSs[ix]					# np.array 2D
#		print(eEEG.shape)
#		print(len(eCHN))
#		print(eFS.shape)
		for epoch in range(eEEG.shape[0]):				# num of epoch
#			print('TXT file for %s : writing %03d\r' % (eSBJs[ix], epoch+1))
			StdOutWt('TXT file for %-30s : writing %03d\r'%(eSBJs[ix], epoch+1))
			txt			=	open('%s%s/%03d.txt'% (PATH,eSBJs[ix],epoch+1), 'wt')

			for tp		in range(eEEG.shape[2]):		# file col is tp(dp)
#				for ch	in range(eEEG.shape[1]):		# file row is ch
#					txt.write('%-4e ' % eEEG[epoch,ch,tp])	# write to each ep
				num		=	'  '.join(map(lambda x: '% .7e'%x, eEEG[epoch,:,tp]))
				txt.write('  %s\n' % num)
#				txt.write('\n')							# line feed

			txt.close()
		StdOutWt('\n')									# next line

if __name__ == '__main__':

#	PATH	= '/home/minlab/Projects/SSVEP_NEW/SSVEP_3/eEEG.Ch-(EOG,NULL).0~5000ms/'
	PATH	= '/home/minlab/Projects/PFC_64/PFC_3/eEEG/'

#	eSBJs, eEEGs, eMRKs, eCHNs, eFSs	=	getDataFiles(PATH, 'SSVEP_NEW',	\
#			list(range(1,20+1)), [ 'TopDown', 'Intermediate', 'BottomUp' ], 4)
#	eSBJs, eEEGs, eMRKs, eCHNs, eFSs	=	getDataFiles(PATH, 'PFC_64',	\
#			list(range(1,29))+[30], [ 'Left', 'Rght' ], 7)
	eSBJs, eEEGs, eMRKs, eCHNs, eFSs	=	getDataFiles(PATH, 'PFC_64',	\
			list(range(1,29))+[30], [ '' ], 7)

	putDataFiles(PATH, eSBJs, eEEGs, eMRKs, eCHNs, eFSs)


	''' 
	import concurrent.futures
	from functools import partial

	def is_prime(n):
		if n < 2:
			return False
		if n is 2 or n is 3:
			return True
		if n % 2 is 0 or n % 3 is 0:
			return False
		if n < 9:
			return True
		k, l = 5, n ** 0.5
		while k <= l:
			if n % k is 0 or n % (k+2) is 0:
				return False
			k += 6
		return True

	def process(n, r=10000):
		print("processing: {} ..< {}".format(n, n+r), end="... ")
		s = sum((x for x in range(n, n+r) if is_prime(x) if x <= 2000000))
		print(s)
		return s



	def main():
		r = 50000
		with concurrent.futures.ProcessPoolExecutor(max_workers=2) as exe:
			result = 0
			for i in exe.map(partial(process, r=r), range(0, 2000000, r)):
				result += i
				print(result)
			print(result)

	if __name__ == "__main__":
		main()

# exe.map() 메소드를 쓰지 않고 Futures의 기능을 이용하는 형태로 코드를 조금 고쳐보았다.

	def main():
		r = 50000
		with concurrent.futures.ProcessPoolExecutor(max_workers=2) as exe:
			fs = {exe.submit(process, n, r) for n in range(0, 2000000, r)}
			done, _ = concurrent.futures.wait(fs)
			result = sum((f.result() for f in done))
			print(result)
	'''

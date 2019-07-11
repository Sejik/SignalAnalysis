#!/bin/sh

subjdir=$1

numfib=`${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_0000/f*samples | wc -w | awk '{print $1}'`

fib=1
while [ $fib -le $numfib ]
do
    ${FSLDIR}/bin/fslmerge -z ${subjdir}.bedpostX/merged_th${fib}samples `${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_*/th${fib}samples`
    ${FSLDIR}/bin/fslmerge -z ${subjdir}.bedpostX/merged_ph${fib}samples `${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_*/ph${fib}samples`
    ${FSLDIR}/bin/fslmerge -z ${subjdir}.bedpostX/merged_f${fib}samples  `${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_*/f${fib}samples`
    ${FSLDIR}/bin/fslmaths ${subjdir}.bedpostX/merged_th${fib}samples -Tmean ${subjdir}.bedpostX/mean_th${fib}samples
    ${FSLDIR}/bin/fslmaths ${subjdir}.bedpostX/merged_ph${fib}samples -Tmean ${subjdir}.bedpostX/mean_ph${fib}samples
    ${FSLDIR}/bin/fslmaths ${subjdir}.bedpostX/merged_f${fib}samples -Tmean ${subjdir}.bedpostX/mean_f${fib}samples

    ${FSLDIR}/bin/make_dyadic_vectors ${subjdir}.bedpostX/merged_th${fib}samples ${subjdir}.bedpostX/merged_ph${fib}samples ${subjdir}.bedpostX/nodif_brain_mask ${subjdir}.bedpostX/dyads${fib}
    fib=$(($fib + 1))
done

echo Removing intermediate files

if [ `imtest ${subjdir}.bedpostX/merged_th1samples` -eq 1 ];then
  if [ `imtest ${subjdir}.bedpostX/merged_ph1samples` -eq 1 ];then
    if [ `imtest ${subjdir}.bedpostX/merged_f1samples` -eq 1 ];then
      rm -rf ${subjdir}.bedpostX/diff_slices
      rm -f ${subjdir}/data_slice_*
      rm -f ${subjdir}/nodif_brain_mask_slice_*
    fi
  fi
fi

echo Creating identity xfm

xfmdir=${subjdir}.bedpostX/xfms
echo 1 0 0 0 > ${xfmdir}/eye.mat
echo 0 1 0 0 >> ${xfmdir}/eye.mat
echo 0 0 1 0 >> ${xfmdir}/eye.mat
echo 0 0 0 1 >> ${xfmdir}/eye.mat

echo Done

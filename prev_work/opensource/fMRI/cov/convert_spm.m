motion_cov=load('rp_aAHN_JEONG_JA_20110228_HF101AR_501_fMRI_REST_CLEAR_fMRI_REST_001.txt');
wb_cov=load('ROITimeCourse_BrainMask_05_61x73x61.txt');
wm_cov=load('ROITimeCourse_WhiteMask_09_61x73x61.txt');
csf_cov=load('ROITimeCourse_CsfMask_07_61x73x61.txt');
cov=[motion_cov,wb_cov,wm_cov,csf_cov];
save('cov.txt','cov','-ASCII','-Double','-tabs');
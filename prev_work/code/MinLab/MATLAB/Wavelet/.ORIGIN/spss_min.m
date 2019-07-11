su11_1am=su11_1_a_m-mean(su11_1_a_m(1:250));
su15_1am=su15_1_a_m-mean(su15_1_a_m(1:250));
su16_1am=su16_1_a_m-mean(su16_1_a_m(1:250));
su18_1am=su18_1_a_m-mean(su18_1_a_m(1:250));
su20_1am=su20_1_a_m-mean(su20_1_a_m(1:250));
su28_1am=su28_1_a_m-mean(su28_1_a_m(1:250));
su30_1am=su30_1_a_m-mean(su30_1_a_m(1:250));
su31_1am=su31_1_a_m-mean(su31_1_a_m(1:250));
su34_1am=su34_1_a_m-mean(su34_1_a_m(1:250));
su35_1am=su35_1_a_m-mean(su35_1_a_m(1:250));
su39_1am=su39_1_a_m-mean(su39_1_a_m(1:250));
su40_1am=su40_1_a_m-mean(su40_1_a_m(1:250));
su41_1am=su41_1_a_m-mean(su41_1_a_m(1:250));

su11_1cm=su11_1_c_m-mean(su11_1_c_m(1:250));
su15_1cm=su15_1_c_m-mean(su15_1_c_m(1:250));
su16_1cm=su16_1_c_m-mean(su16_1_c_m(1:250));
su18_1cm=su18_1_c_m-mean(su18_1_c_m(1:250));
su20_1cm=su20_1_c_m-mean(su20_1_c_m(1:250));
su28_1cm=su28_1_c_m-mean(su28_1_c_m(1:250));
su30_1cm=su30_1_c_m-mean(su30_1_c_m(1:250));
su31_1cm=su31_1_c_m-mean(su31_1_c_m(1:250));
su34_1cm=su34_1_c_m-mean(su34_1_c_m(1:250));
su35_1cm=su35_1_c_m-mean(su35_1_c_m(1:250));
su39_1cm=su39_1_c_m-mean(su39_1_c_m(1:250));
su40_1cm=su40_1_c_m-mean(su40_1_c_m(1:250));
su41_1cm=su41_1_c_m-mean(su41_1_c_m(1:250));

avg_1am=(su11_1am+su15_1am+su16_1am+su18_1am+su20_1am+su28_1am+su30_1am+su31_1am+su34_1am+su35_1am+su39_1am+su40_1am+su41_1am)/13;
avg_1cm=(su11_1cm+su15_1cm+su16_1cm+su18_1cm+su20_1cm+su28_1cm+su30_1cm+su31_1cm+su34_1cm+su35_1cm+su39_1cm+su40_1cm+su41_1cm)/13;

figure;plot(avg_1am,'r');hold on;plot(avg_1cm,'b');

[M,I]=max(su41_1cm(323:343))
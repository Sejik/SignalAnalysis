function [statistic] = SJ_statistic(raw)
    statistic.mean = mean(raw, 3);
    statistic.std = std(raw, 0, 3);
    statistic.ttest = SJ_ttest(raw);
    statistic.anova = SJ_anova(raw);
    statistic.postHoc = SJ_postHoc(raw);
    statistic.twoWay = SJ_anova(raw);
end

function [ttestResult] = SJ_ttest(raw)
    [h(1), p(1)] = ttest2(raw(1,1,:), raw(1,2,:));
    [h(2), p(2)] = ttest2(raw(2,1,:), raw(2,2,:));
    [h(3), p(3)] = ttest2(raw(3,1,:), raw(3,2,:));
    ttestResult.p = p;
    ttestResult.h = h;
    maxGroup = {'group2', 'group2', 'group2'};
    maxGroup(mean(raw(:,1,:),3) >= mean(raw(:,2,:),3)) = 'group1';
    maxGroup(h == 0) = 'X';
    ttestResult.max = maxGroup;
end

function [anovaResult] = SJ_anova(raw)
    anovaMean = squeeze(mean(raw, 3));
    anovaP(1) = anova1([raw(1,1,:), raw(2,1,:), raw(3,1,:)]);
    anovaP(2) = anova1([raw(1,2,:), raw(2,2,:), raw(3,2,:)]);
    anovaResult.p = anovaP;
    [~, maxNum(1)] = max(anovaMean(1,:));
    [~, maxNum(2)] = max(anovaMean(2,:));
    [~, minNum(1)] = min(anovaMean(1,:));
    [~, minNum(2)] = min(anovaMean(2,:));
    maxGroup = {'group', 'group'};
    minGroup = {'group', 'group'};
    maxGroup(1) = strcat(maxGroup(1), num2str(maxNum(1)));
    maxGroup(2) = strcat(maxGroup(2), num2str(maxNum(2)));
    minGroup(1) = strcat(minGroup(1), num2str(minNum(1)));
    minGroup(2) = strcat(minGroup(2), num2str(minNum(2)));
    maxGroup(anovaP > 0.05) = 'X';
    minGroup(anovaP > 0.05) = 'X';
    anovaResult.max = maxGroup;
    anovaResult.min = minGroup;
end

function [postHocResult] = SJ_postHoc(raw)
    postHocMean = squeeze(mean(raw,3));
    [h(1,1), p(1,1)] = ttest2(raw(1,1,:), raw(2,1,:));
    [h(2,1), p(2,1)] = ttest2(raw(1,1,:), raw(3,1,:));
    [h(3,1), p(3,1)] = ttest2(raw(2,1,:), raw(3,1,:));
    [h(1,2), p(1,2)] = ttest2(raw(1,2,:), raw(2,2,:));
    [h(2,2), p(2,2)] = ttest2(raw(1,2,:), raw(3,2,:));
    [h(3,2), p(3,2)] = ttest2(raw(2,2,:), raw(3,2,:));
    p = p*3;
    h(p > 0.05) = 0;
    postHocResult.p = p;
    postHocResult.h = h;
    [~, maxNum(1,1)] = max(postHocMean(1,1), postHocMean(2,1));
    [~, maxNum(2,1)] = max(postHocMean(1,1), postHocMean(3,1));
    [~, maxNum(3,1)] = max(postHocMean(2,1), postHocMean(3,1));
    [~, maxNum(1,2)] = max(postHocMean(1,2), postHocMean(2,2));
    [~, maxNum(2,2)] = max(postHocMean(1,2), postHocMean(3,2));
    [~, maxNum(3,2)] = max(postHocMean(2,2), postHocMean(3,2));
    maxGroup = {'group', 'group', 'group'; 'group', 'group', 'group'};
    maxGroup = strcat(maxGroup, num2str(maxNum));
    postHocResult.max = maxGroup;
end
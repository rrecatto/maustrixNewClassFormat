function orLEDData = analyzeORLEDTrials(mouseID,data,filters,plotDetails,trialNumCutoff,daysPBS,daysCNO,daysIntact,daysLesion)

if islogical(plotDetails)
    plotDetails.plotOn = true;
    plotDetails.plotWhere = 'makeFigure';
end

try
    tsName = filters.tsName;
catch ex
    tsName = 'or_100VarCLED';
end

orled = filterBehaviorData(data,'tsName',tsName);%% orDUR_LowDur_Sweep,orDURSweep
orLEDData.trialNum = [orled.compiledTrialRecords.trialNumber];
orLEDData.correct = [orled.compiledTrialRecords.correct];
orLEDData.correction = [orled.compiledTrialRecords.correctionTrial];
orLEDData.responseTime = [orled.compiledTrialRecords.responseTime];
whichDetailFileNum = find(strcmp({orled.compiledDetails.className},'afcGratingsPDPhases'));
orLEDData.contrast = [orled.compiledDetails(whichDetailFileNum).records.contrasts];
orLEDData.maxDuration = [orled.compiledDetails(whichDetailFileNum).records.maxDuration] /60; % assume 60Hz! may not be true - capture the ifi hereon in
orLEDData.LED1 = orled.compiledDetails(whichDetailFileNum).records.LED(1,:);

orLEDData.time = [orled.compiledTrialRecords.date];
orLEDData.date = floor(orLEDData.time);
orLEDData.dates = unique(orLEDData.date);
orLEDData.contrasts = unique(orLEDData.contrast);
orLEDData.maxDurations = unique(orLEDData.maxDuration);
orLEDData.LED1s = unique(orLEDData.LED1);

% performance on a day by day basis
orLEDData.trialNumByDate = cell(1,length(orLEDData.dates));
orLEDData.numTrialsByDate = nan(1,length(orLEDData.dates));
orLEDData.performanceByDate = nan(3,length(orLEDData.dates));
orLEDData.colorByCondition = cell(1,length(orLEDData.dates));
orLEDData.conditionNum = nan(1,length(orLEDData.dates));
orLEDData.dayMetCutOffCriterion = nan(1,length(orLEDData.dates));

%performance by condition
orLEDData.trialNumsByCondition = cell(length(orLEDData.maxDurations),length(orLEDData.contrasts),length(orLEDData.LED1s));
orLEDData.numTrialsByCondition = zeros(length(orLEDData.maxDurations),length(orLEDData.contrasts),length(orLEDData.LED1s));
orLEDData.correctByCondition = zeros(length(orLEDData.maxDurations),length(orLEDData.contrasts),length(orLEDData.LED1s));
orLEDData.performanceByCondition = nan(length(orLEDData.maxDurations),length(orLEDData.contrasts),3,length(orLEDData.LED1s));
orLEDData.responseTimesByCondition = cell(length(orLEDData.maxDurations),length(orLEDData.contrasts),length(orLEDData.LED1s));
orLEDData.responseTimesForCorrectByCondition = cell(length(orLEDData.maxDurations),length(orLEDData.contrasts),length(orLEDData.LED1s));

%performance by condition with trial number cutoff
orLEDData.trialNumsByConditionWCO = cell(length(orLEDData.maxDurations),length(orLEDData.contrasts),length(orLEDData.LED1s));
orLEDData.numTrialsByConditionWCO = zeros(length(orLEDData.maxDurations),length(orLEDData.contrasts),length(orLEDData.LED1s));
orLEDData.correctByConditionWCO = zeros(length(orLEDData.maxDurations),length(orLEDData.contrasts),length(orLEDData.LED1s));
orLEDData.performanceByConditionWCO = nan(length(orLEDData.maxDurations),length(orLEDData.contrasts),3,length(orLEDData.LED1s));
orLEDData.responseTimesByConditionWCO = cell(length(orLEDData.maxDurations),length(orLEDData.contrasts),length(orLEDData.LED1s));
orLEDData.responseTimesForCorrectByConditionWCO = cell(length(orLEDData.maxDurations),length(orLEDData.contrasts),length(orLEDData.LED1s));

for i = 1:length(orLEDData.dates)
    if ismember(orLEDData.dates(i),filters.orLED)
        dateFilter = orLEDData.date==orLEDData.dates(i);
        correctThatDate = orLEDData.correct(dateFilter);
        correctionThatDate = orLEDData.correction(dateFilter);
        contrastThatDate = orLEDData.contrast(dateFilter);
        durationThatDate = orLEDData.maxDuration(dateFilter);
        responseTimeThatDate = orLEDData.responseTime(dateFilter);
        LED1ThatDate = orLEDData.LED1(dateFilter);
        
        % filter out the nans
        whichGood = ~isnan(correctThatDate) & ~correctionThatDate & responseTimeThatDate<5;
        correctThatDate = correctThatDate(whichGood);
        contrastThatDate = contrastThatDate(whichGood);
        durationThatDate = durationThatDate(whichGood);
        responseTimeThatDate = responseTimeThatDate(whichGood);
        LED1ThatDate = LED1ThatDate(whichGood);
        
        orLEDData.trialNumByDate{i} = orLEDData.trialNum(dateFilter);
        orLEDData.trialNumByDate{i} = orLEDData.trialNumByDate{i}(whichGood);
        orLEDData.numTrialsByDate(i) = length(orLEDData.trialNumByDate{i});

        x = sum(correctThatDate);
        n = length(correctThatDate);
        orLEDData.dayMetCutOffCriterion(i) = n>=trialNumCutoff;
        [phat,pci] = binofit(x,n);
        orLEDData.performanceByDate(1,i) = phat;
        orLEDData.performanceByDate(2,i) = pci(1);
        orLEDData.performanceByDate(3,i) = pci(2);
        
        for k = 1:length(orLEDData.maxDurations)
            for j = 1:length(orLEDData.contrasts)
                for l = 1:length(orLEDData.LED1s)
                    whichCurrDurationContrastAndLED = contrastThatDate==orLEDData.contrasts(j) &...
                        durationThatDate==orLEDData.maxDurations(k) &...
                        LED1ThatDate==orLEDData.LED1s(l);
                    currDurCtrLEDCorrect = correctThatDate(whichCurrDurationContrastAndLED);
                    currResponseTimes = responseTimeThatDate(whichCurrDurationContrastAndLED);
                    currCorrectResponseTimes = currResponseTimes(logical(currDurCtrLEDCorrect));
                    x1 = sum(currDurCtrLEDCorrect);
                    n1 = length(currDurCtrLEDCorrect);
                    orLEDData.trialNumsByCondition{k,j,l} = [orLEDData.trialNumsByCondition{k,j,l} makerow(orLEDData.trialNumByDate{i}(whichCurrDurationContrastAndLED))];
                    orLEDData.numTrialsByCondition(k,j,l) = orLEDData.numTrialsByCondition(k,j,l)+n1;
                    orLEDData.correctByCondition(k,j,l) = orLEDData.correctByCondition(k,j,l)+x1;
                    orLEDData.responseTimesByCondition{k,j,l} = [orLEDData.responseTimesByCondition{k,j,l} makerow(currResponseTimes)];
                    orLEDData.responseTimesForCorrectByCondition{k,j,l} = [orLEDData.responseTimesForCorrectByCondition{k,j,l} makerow(currCorrectResponseTimes)];
                    
                    if orLEDData.dayMetCutOffCriterion(i)
                        orLEDData.trialNumsByConditionWCO{k,j,l} = [orLEDData.trialNumsByConditionWCO{k,j,l} makerow(orLEDData.trialNumByDate{i}(whichCurrDurationContrastAndLED))];
                        orLEDData.numTrialsByConditionWCO(k,j,l) = orLEDData.numTrialsByConditionWCO(k,j,l)+n1;
                        orLEDData.correctByConditionWCO(k,j,l) = orLEDData.correctByConditionWCO(k,j,l)+x1;
                        orLEDData.responseTimesByConditionWCO{k,j,l} = [orLEDData.responseTimesByConditionWCO{k,j,l} makerow(currResponseTimes)];
                        orLEDData.responseTimesForCorrectByConditionWCO{k,j,l} = [orLEDData.responseTimesForCorrectByConditionWCO{k,j,l} makerow(currCorrectResponseTimes)];
                    end
                end
            end
        end
        
    end
end

for k = 1:length(orLEDData.maxDurations)
    for j = 1:length(orLEDData.contrasts)
        for l = 1:length(orLEDData.LED1s)
            [phat,pci] = binofit(orLEDData.correctByCondition(k,j,l),orLEDData.numTrialsByCondition(k,j,l));
            orLEDData.performanceByCondition(k,j,1,l) = phat;
            orLEDData.performanceByCondition(k,j,2:3,l) = pci';
            
            [phat,pci] = binofit([orLEDData.correctByConditionWCO(k,j,l)],[orLEDData.numTrialsByConditionWCO(k,j,l)]);
            orLEDData.performanceByConditionWCO(k,j,1,l) = phat;
            orLEDData.performanceByConditionWCO(k,j,2:3,l) = pci';
        end
    end
end


if plotDetails.plotOn
    switch plotDetails.plotWhere
        case 'givenAxes'
            axes(plotDetails.axHan); hold on;
            title(sprintf('%s::CONTRAST',mouseID));
            switch plotDetails.requestedPlot
                case 'trialsByDay'
                    bar(orLEDData.dates-min(orLEDData.dates)+1,orLEDData.numTrialsByDate);
                    xlabel('num days','FontName','Times New Roman','FontSize',12);
                    ylabel('num trials','FontName','Times New Roman','FontSize',12);
                    
                case 'performanceByCondition'
                    conditionColor = {'k','b'}; % black is for 0 and blue is for 255 (chR)
                    % now performance is a 4D vector (durationsXcontrastsX[phat pcilow pcihi]Xcondition)
                    % separate by condition
                    for i = 1:size(orLEDData.performanceByConditionWCO,4)
                        % now separate by duration
                        for k = 1:size(orLEDData.performanceByConditionWCO,1)
                            if isfield(plotDetails,'plotMeansOnly') && plotDetails.plotMeansOnly
                                means = orLEDData.performanceByConditionWCO(k,:,1,i);
                                which = ~isnan(orLEDData.performanceByConditionWCO(k,:,1,i));
                                
                                if ~isempty(orLEDData.maxDurations(which))
                                    h = plot(log10(orLEDData.maxDurations(which)),means(which),'color',conditionColor{i},'linewidth',3*orLEDData.contrasts(k)+0.88);
                                    try
                                        brightVal = log10(orLEDData.contrasts(k)/0.5);
                                        brightVal = min(brightVal,0.99);
                                        brightVal = max(brightVal,-0.99);
                                        brighten(gca,brightVal)
                                    catch
                                        brighten(h,-0.99); % for when contrast is 0
                                    end
                                    
                                end
                                
                            else
                                for j = 1:size(orLEDData.performanceByConditionWCO,2)
                                    if ~isnan(orLEDData.performanceByConditionWCO(k,j,1,i))
                                        h1 = plot(orLEDData.contrasts(j),orLEDData.performanceByConditionWCO(k,j,1,i),'Marker','d','MarkerSize',10,'MarkerFaceColor',conditionColor{i},'MarkerEdgeColor','none');
                                        h2 = plot([orLEDData.contrasts(j) orLEDData.contrasts(j)],[orLEDData.performanceByConditionWCO(k,j,2,i) orLEDData.performanceByConditionWCO(k,j,3,i)],'color',conditionColor{i},'linewidth',5);
                                        try
                                            brightVal = log(orLEDData.contrasts(k)/0.5);
                                            brightVal = min(brightVal,0.99);
                                            brightVal = max(brightVal,-0.99);
                                            brighten(h1,brightVal);
                                            brighten(h2,brightVal)
                                        catch
                                            brighten(h1,-0.99); % for when contrast is 0
                                            brighten(h2,-0.99);
                                        end
                                        %                                         keyboard
                                    end
                                end
                            end
                        end
                    end
                    
                    set(gca,'ylim',[0.2 1.1],...
                        'xlim',[0 1.1],...
                        'xtick',[0.15 1],...
                        'ytick',[0.2 0.5 1],...
                        'FontName','Times New Roman',...
                        'FontSize',12);
                    plot([0 1],[0.5 0.5],'k-');
                    xlabel('contrasts','FontName','Times New Roman','FontSize',12);
                    ylabel('performance','FontName','Times New Roman','FontSize',12);
                    
                case 'performanceByLED'
                    conditionColor = {'k','b'}; % black is for 0 and blue is for 255 (chR)
                    % now performance is a 4D vector (durationsXcontrastsX[phat pcilow pcihi]Xcondition)
                    % now separate by contrast
                    for k = 1:size(orLEDData.performanceByConditionWCO,2)
                        if isfield(plotDetails,'plotMeansOnly') && plotDetails.plotMeansOnly
                            means = orLEDData.performanceByConditionWCO(1,k,1,:);
                            which = ~isnan(orLEDData.performanceByConditionWCO(1,k,1,:));
                            
                            if ~isempty(orLEDData.LED1s(which))
                                h = plot(orLEDData.LED1s(which),squeeze(means(which)),'color',(-5/9*orLEDData.contrasts(k)+5/9)*[1 1 1],'linewidth',3);
                            end
                            
                        else
                            keyboard
                            for j = 1:size(orLEDData.performanceByConditionWCO,1)
                                if ~isnan(orLEDData.performanceByConditionWCO(j,k,1,i))
                                    h1 = plot(orLEDData.contrasts(k),orLEDData.performanceByConditionWCO(j,k,1,i),'Marker','d','MarkerSize',10,'MarkerFaceColor',conditionColor{i},'MarkerEdgeColor','none');
                                    h2 = plot([orLEDData.contrasts(j) orLEDData.contrasts(j)],[orLEDData.performanceByConditionWCO(k,j,2,i) orLEDData.performanceByConditionWCO(k,j,3,i)],'color',conditionColor{i},'linewidth',5);
                                    try
                                        brightVal = log(orLEDData.contrasts(k)/0.5);
                                        brightVal = min(brightVal,0.99);
                                        brightVal = max(brightVal,-0.99);
                                        brighten(h1,brightVal);
                                        brighten(h2,brightVal)
                                    catch
                                        brighten(h1,-0.99); % for when contrast is 0
                                        brighten(h2,-0.99);
                                    end
                                    %                                         keyboard
                                end
                            end
                        end
                    end
                    
                    set(gca,'ylim',[0.2 1.1],...
                        'xlim',[0 256],...
                        'xtick',[0 64 128 192 256],...
                        'ytick',[0.2 0.5 1],...
                        'FontName','Times New Roman',...
                        'FontSize',12);
                    plot([0 1],[0.5 0.5],'k-');
                    xlabel('LED Level','FontName','Times New Roman','FontSize',12);
                    ylabel('performance','FontName','Times New Roman','FontSize',12);
                    
                case 'performanceByDay'
                    plot([0 max(orLEDData.dates)-min(orLEDData.dates)+1],[0.5 0.5],'k');
                    plot([0 max(orLEDData.dates)-min(orLEDData.dates)+1],[0.7 0.7],'k--');
                    for i = 1:length(orLEDData.dates)
                        if ~isnan(orLEDData.dayMetCutOffCriterion(i))
                            if orLEDData.dayMetCutOffCriterion(i)
                                xloc = orLEDData.dates(i)-min(orLEDData.dates)+1;
                                plot(xloc,orLEDData.performanceByDate(1,i),'Marker','d','MarkerEdgeColor','k','MarkerFaceColor','k');
                                plot([xloc xloc],orLEDData.performanceByDate(2:3,i),'color','k','LineWidth',2);
                            else
                                xloc = orLEDData.dates(i)-min(orLEDData.dates)+1;
                                plot(xloc,orLEDData.performanceByDate(1,i),'Marker','d','MarkerEdgeColor',0.75*[1 1 1],'MarkerFaceColor',0.75*[1 1 1]);
                                plot([xloc xloc],orLEDData.performanceByDate(2:3,i),'color',0.75*[1 1 1],'LineWidth',2);
                            end
                        else
                            xloc = orLEDData.dates(i)-min(orLEDData.dates)+1;
                            plot(xloc,0.5,'Marker','x','color','k');
                        end
                    end
                    set(gca,'ylim',[0.2 1]);
                    xlabel('day num','FontName','Times New Roman','FontSize',12);
                    ylabel('performance','FontName','Times New Roman','FontSize',12);
                case 'responseTime'
                    keyboard
                otherwise
                    error('wtf!');
            end
            
            
        case {'givenFigure','makeFigure'}
            figName = sprintf('%s::OPTIMAL',mouseID);
            if strcmp(plotDetails.plotWhere,'makeFigure')
                f = figure('name',figName);
            else
                figure(plotDetails.figHan)
            end
            
            % trials by day
            ax1 = subplot(3,2,1); hold on;
            bar(orLEDData.dates-min(orLEDData.dates)+1,orLEDData.numTrialsByDate);
            xlabel('num days','FontName','Times New Roman','FontSize',12);
            ylabel('num trials','FontName','Times New Roman','FontSize',12);
            
            % performance by day
            ax2 = subplot(3,2,2); hold on;
            plot([0 max(orLEDData.dates)-min(orLEDData.dates)+1],[0.5 0.5],'k');
            plot([0 max(orLEDData.dates)-min(orLEDData.dates)+1],[0.7 0.7],'k--');
            for i = 1:length(orLEDData.dates)
                if ~isnan(orLEDData.dayMetCutOffCriterion(i))
                    if orLEDData.dayMetCutOffCriterion(i)
                        xloc = orLEDData.dates(i)-min(orLEDData.dates)+1;
                        plot(xloc,orLEDData.performanceByDate(1,i),'Marker','d','MarkerEdgeColor','k','MarkerFaceColor','k');
                        plot([xloc xloc],orLEDData.performanceByDate(2:3,i),'color','k','LineWidth',2);
                    else
                        xloc = orLEDData.dates(i)-min(orLEDData.dates)+1;
                        plot(xloc,orLEDData.performanceByDate(1,i),'Marker','d','MarkerEdgeColor',0.75*[1 1 1],'MarkerFaceColor',0.75*[1 1 1]);
                        plot([xloc xloc],orLEDData.performanceByDate(2:3,i),'color',0.75*[1 1 1],'LineWidth',2);
                    end
                else
                    xloc = orLEDData.dates(i)-min(orLEDData.dates)+1;
                    plot(xloc,0.5,'Marker','x','color','k');
                end
            end
            set(ax2,'ylim',[0.2 1]);
            xlabel('day num','FontName','Times New Roman','FontSize',12);
            ylabel('performance','FontName','Times New Roman','FontSize',12);
            
            % performance by condition
            ax3 = subplot(3,2,3:4); hold on;
            conditionColor = {'b','r','b','r','k'};
            for i = 1:size(orLEDData.performanceByConditionWCO,3)
                for j = 1:size(orLEDData.performanceByConditionWCO,1)
                    if ~isnan(orLEDData.performanceByConditionWCO(j,1,i))
                        plot(orLEDData.contrasts(j),orLEDData.performanceByConditionWCO(j,1,i),'Marker','d','MarkerSize',10,'MarkerFaceColor',conditionColor{i},'MarkerEdgeColor','none');
                        plot([orLEDData.contrasts(j) orLEDData.contrasts(j)],[orLEDData.performanceByConditionWCO(j,2,i) orLEDData.performanceByConditionWCO(j,3,i)],'color',conditionColor{i},'linewidth',5);
                    end
                end
            end
            set(ax3,'ylim',[0.2 1.1],'xlim',[-0.05 1.05],'xtick',[0 0.25 0.5 0.75 1],'ytick',[0.2 0.5 1],'FontName','Times New Roman','FontSize',12);plot([0 1],[0.5 0.5],'k-');plot([0 1],[0.7 0.7],'k--');
            xlabel('contrast','FontName','Times New Roman','FontSize',12);
            ylabel('performance','FontName','Times New Roman','FontSize',12);
                        
            % response times
            ax4 = subplot(3,2,5); hold on;
            conditionColor = {'b','r','b','r','k'};
            for i = 1:size(orLEDData.responseTimesByConditionWCO,2)
                for j = 1:size(orLEDData.responseTimesByConditionWCO,1)
                    if ~(isempty(orLEDData.responseTimesByConditionWCO{j,i}))
                        m = mean(orLEDData.responseTimesByConditionWCO{j,i});
                        sem = std(orLEDData.responseTimesByConditionWCO{j,i})/sqrt(length(orLEDData.responseTimesByConditionWCO{j,i}));
                        plot(orLEDData.contrasts(j),m,'Marker','d','MarkerSize',10,'MarkerFaceColor',conditionColor{i},'MarkerEdgeColor','none');
                        plot([orLEDData.contrasts(j) orLEDData.contrasts(j)],[m-sem m+sem],'color',conditionColor{i},'linewidth',5);
                    end
                end
            end
            set(ax4,'ylim',[0 3],'xlim',[-0.05 1.05],'xtick',[0 0.25 0.5 0.75 1],'ytick',[0 1 2 3],'FontName','Times New Roman','FontSize',12);plot([0 1],[0.5 0.5],'k-');plot([0 1],[0.7 0.7],'k--');
            xlabel('contrast','FontName','Times New Roman','FontSize',12);
            ylabel('responseTime','FontName','Times New Roman','FontSize',12);
            
            % response times for correct
            ax5 = subplot(3,2,6); hold on;
            conditionColor = {'b','r','b','r','k'};
            for i = 1:size(orLEDData.responseTimesForCorrectByConditionWCO,2)
                for j = 1:size(orLEDData.responseTimesForCorrectByConditionWCO,1)
                    if ~(isempty(orLEDData.responseTimesForCorrectByConditionWCO{j,i}))
                        m = mean(orLEDData.responseTimesForCorrectByConditionWCO{j,i});
                        sem = std(orLEDData.responseTimesForCorrectByConditionWCO{j,i})/sqrt(length(orLEDData.responseTimesForCorrectByConditionWCO{j,i}));
                        plot(orLEDData.contrasts(j),m,'Marker','d','MarkerSize',10,'MarkerFaceColor',conditionColor{i},'MarkerEdgeColor','none');
                        plot([orLEDData.contrasts(j) orLEDData.contrasts(j)],[m-sem m+sem],'color',conditionColor{i},'linewidth',5);
                    end
                end
            end
            set(ax5,'ylim',[0 3],'xlim',[-0.05 1.05],'xtick',[0 0.25 0.5 0.75 1],'ytick',[0 1 2 3],'FontName','Times New Roman','FontSize',12);plot([0 1],[0.5 0.5],'k-');plot([0 1],[0.7 0.7],'k--');
            xlabel('contrast','FontName','Times New Roman','FontSize',12);
            ylabel('responseTimeForCorrect','FontName','Times New Roman','FontSize',12);
    end
end
function COSYNE2011_plotLFP
if false
    %% LFP
    done = false;
    while ~done
        % check if all analyses are anesth or un anesth
        i = randint(1,1,31)+1;
        awake = true(size(db.data{i}.analyses));
        for j = 1:length(db.data{i}.analyses)
            awake(j) = awake(j)&&(db.data{i}.analyses{j}.getAnesthesia==0);
        end
        
        if all(awake==true) || all(awake==false)
            special = false;
        else
            special = true;
        end
        if ~special
            f = figure;
            ax1 = subplot(2,1,1);
            ax2 = subplot(2,1,2);
            j = randint(1,1,length(db.data{i}.analyses))+1;
            
            LFPRec = getCompleteLFPRecordsForAnalysis(db.data{i}.analyses{j});
            if db.data{i}.analyses{j}.getAnesthesia==0
                plot(ax1,LFPRec.LFPDataTimes,LFPRec.LFPData,'b');
            else
                plot(ax1,LFPRec.LFPDataTimes,LFPRec.LFPData,'r');
            end
            axis([minmax(LFPRec.LFPDataTimes),1.1*minmax(LFPRec.LFPData)])
            f = [0:1:40];
            [spec F T] = spectrogram(LFPRec.LFPData,100,[],f,500);
            axes(ax2);
            imagesc(LFPRec.LFPDataTimes(1)+T,flipud(F),abs(spec));
            set(gca,'YTickLabel',flipud(get(gca,'YTickLabel')));
            pause
            
        end
    end
end
%% strategy: get 100 chunks of 20 seconds of LFP. from each type
if false
    done = false;
    n = 1;
    tim2Sample = 20; %seconds
    LFPSamplingHz = 500;
    f = figure;
    while ~done
        % check if all analyses are anesth or un anesth
        i = randi(db.numNeurons);
        j = randi(length(db.data{i}.analyses));
        if ~ismember(db.data{i}.analysisType{j},'gaussianFullField')
            continue
        end
        awake = db.data{i}.analyses{j}.getAnesthesia==0;
        LFPRec = getCompleteLFPRecordsForAnalysis(db.data{i}.analyses{j});
        numSamplesReqMin = tim2Sample*LFPSamplingHz;
        if length(LFPRec.LFPData)<numSamplesReqMin
            % continue
        else
            %         startInd = randi(length(LFPRec.LFPData)-numSamplesReq+1);
            currLFP = LFPRec.LFPData; %(startInd:startInd+numSamplesReq-1)
            params.tapers = [3 5];
            params.pad = 0;
            params.Fs = LFPSamplingHz;
            params.err = [2 0.05];
            [S f Serr] = mtspectrumc(currLFP,params);
            
            if awake
                subplot(5,5,n);hold on;
                semilogx(f,S,'b');
                %             semilogx(f,Serr(1,:),'b--');
                %             semilogx(f,Serr(2,:),'b--');
                axis([0 40 minmax(S(:))])
            else
                subplot(5,5,n);hold on;
                semilogx(f,S,'r');
                %             semilogx(f,Serr(1,:),'r--');
                %             semilogx(f,Serr(2,:),'r--');
                axis([0 40 minmax(S(:))])
            end
            titleStr = sprintf('n:%d a:%d',i,j);
            title(titleStr);
            n = n+1;
        end
        if n>25
            done = true;
        end
    end
end
%% i know which ones i want to look at
if false
    awkNID = 37; awkSubaID = 3;
    anesNID = 58; anesSubaID = 2;
    
    LFPAwk = getCompleteLFPRecordsForAnalysis(db.data{awkNID}.analyses{awkSubaID});
    LFPAnes= getCompleteLFPRecordsForAnalysis(db.data{anesNID}.analyses{anesSubaID});
    
    f = figure;
%     tCourseAwk = subplot(2,2,5);
    Awktimes = linspace(0,length(LFPAwk.LFPData)/500,length(LFPAwk.LFPData));
%     plot(Awktimes,LFPAwk.LFPData,'b');
    
    fAwk = [0:40];
    [specAwk FAwk TAwk] = spectrogram(LFPAwk.LFPData,100,[],fAwk,500);
    
    specGramAwk = subplot(2,2,3);
    imagesc(Awktimes(1)+TAwk,flipud(FAwk),abs(specAwk));
    set(gca,'YTickLabel',flipud(get(gca,'YTickLabel')));
    
%     tCourseAnesth = subplot(3,2,6);
    Anestimes = linspace(0,length(LFPAnes.LFPData)/500,length(LFPAnes.LFPData));
%     plot(Anestimes,LFPAnes.LFPData,'r');

    fAnes = [0:40];
    [specAnes FAnes TAnes] = spectrogram(LFPAnes.LFPData,100,[],fAnes,500);
    
    specGramAnesth = subplot(2,2,4);
    imagesc(Anestimes(1)+TAnes,flipud(FAnes),abs(specAnes));
    set(gca,'YTickLabel',flipud(get(gca,'YTickLabel')));
    
    rangeLFPs = minmax([LFPAwk.LFPData LFPAnes.LFPData]);
    % axes(tCourseAwk);
%     axis(tCourseAwk,[0 max(Awktimes) rangeLFPs]);
%     set(tCourseAwk,'XTick',[0 max(Awktimes)],'XTickLabel',{'0',sprintf('%2.0f',max(Awktimes))},...
%         'YTick',[rangeLFPs(1) 0 rangeLFPs(2)],'YTickLabel',{sprintf('%2.1f',rangeLFPs(1)),'0',sprintf('%2.1f',rangeLFPs(2))});
    % axes(tCourseAnesth);
%     axis(tCourseAnesth,[0 max(Anestimes) rangeLFPs]);
%     set(tCourseAnesth,'XTick',[0 max(Anestimes)],'XTickLabel',{'0',sprintf('%2.0f',max(Anestimes))},...
%         'YTick',[rangeLFPs(1) 0 rangeLFPs(2)],'YTickLabel',{});
    
    set(specGramAwk,'XTick',[minmax(TAwk)],'XTickLabel',{'0',sprintf('%2.0fs',max(Awktimes))},...
        'YTick',[0 40-8 max(FAwk)],'YTickLabel',{sprintf('%2.0fHz',max(FAwk)),'8','0'});
    ylabel(specGramAwk,'frequency(Hz)')
    title(specGramAwk,'Awake LFP')
    
    set(specGramAnesth,'XTick',[minmax(TAnes)],'XTickLabel',{'0',sprintf('%2.0fs',max(Anestimes))},...
        'YTick',[0 max(FAnes)],'YTickLabel',{});
    title(specGramAnesth,'Anesth LFP')
    
    params.Fs = 500;
    params.err = [2,0.5];
    params.tapers = [3 5];
    params.fpass = [0 30];
    specAnesth = subplot(2,2,2);
    [SAnes,fAnes,SerrAnes] = mtspectrumc(LFPAnes.LFPData,params);
    plot(fAnes,SAnes,'r');
    set(specAnesth,'XTick',[0  fAnes(SAnes==max(SAnes)) 30],...
        'XTickLabel',{'',sprintf('%2.1f',fAnes(SAnes==max(SAnes))),'30Hz'},...
        'YTick',[]);
    axis([0 30 0 max(SAnes)])
    
    
    specAwake = subplot(2,2,1);
    [SAwk,fAwk,SerrAwk] = mtspectrumc(LFPAwk.LFPData,params);
    plot(fAwk,SAwk/sum(SAwk),'b');
    axis tight
    set(specAwake,'XTick',[0  fAwk(SAwk==max(SAwk)) 30],...
        'XTickLabel',{'',sprintf('%2.1f',fAwk(SAwk==max(SAwk))),'30Hz'},...
        'YTick',[]);
    axis([0 30 0 max(SAwk)])
    ylabel('NormalizedPower')
    
    
end
if true
    awkNID = 37; awkSubaID = 3;
    anesNID = 58; anesSubaID = 2;
    
    LFPAwk = getCompleteLFPRecordsForAnalysis(db.data{awkNID}.analyses{awkSubaID});
    LFPAnes= getCompleteLFPRecordsForAnalysis(db.data{anesNID}.analyses{anesSubaID});
    
    f = figure;
%     tCourseAwk = subplot(2,2,5);
    Awktimes = linspace(0,length(LFPAwk.LFPData)/500,length(LFPAwk.LFPData));
%     plot(Awktimes,LFPAwk.LFPData,'b');
    
    fAwk = [0:40];
    [specAwk FAwk TAwk] = spectrogram(LFPAwk.LFPData,100,[],fAwk,500);
    
    specGramAwk = subplot(2,3,2:3);
    imagesc(Awktimes(1)+TAwk,flipud(FAwk),abs(specAwk));
    set(gca,'YTickLabel',flipud(get(gca,'YTickLabel')));
    
%     tCourseAnesth = subplot(3,2,6);
    Anestimes = linspace(0,length(LFPAnes.LFPData)/500,length(LFPAnes.LFPData));
%     plot(Anestimes,LFPAnes.LFPData,'r');

    fAnes = [0:40];
    [specAnes FAnes TAnes] = spectrogram(LFPAnes.LFPData,100,[],fAnes,500);
    
    specGramAnesth = subplot(2,3,5:6);
    imagesc(Anestimes(1)+TAnes,flipud(FAnes),abs(specAnes));
    set(gca,'YTickLabel',flipud(get(gca,'YTickLabel')));
    
    rangeLFPs = minmax([LFPAwk.LFPData LFPAnes.LFPData]);
    % axes(tCourseAwk);
%     axis(tCourseAwk,[0 max(Awktimes) rangeLFPs]);
%     set(tCourseAwk,'XTick',[0 max(Awktimes)],'XTickLabel',{'0',sprintf('%2.0f',max(Awktimes))},...
%         'YTick',[rangeLFPs(1) 0 rangeLFPs(2)],'YTickLabel',{sprintf('%2.1f',rangeLFPs(1)),'0',sprintf('%2.1f',rangeLFPs(2))});
    % axes(tCourseAnesth);
%     axis(tCourseAnesth,[0 max(Anestimes) rangeLFPs]);
%     set(tCourseAnesth,'XTick',[0 max(Anestimes)],'XTickLabel',{'0',sprintf('%2.0f',max(Anestimes))},...
%         'YTick',[rangeLFPs(1) 0 rangeLFPs(2)],'YTickLabel',{});
    
    set(specGramAwk,'XTick',[minmax(TAwk)],'XTickLabel',{'0',sprintf('%2.0fs',max(Awktimes))},...
        'YTick',[0 40-8.4 max(FAwk)],'YTickLabel',{'','8.4',''});
    title(specGramAwk,'Awake LFP')
    
    set(specGramAnesth,'XTick',[minmax(TAnes)],'XTickLabel',{'0',sprintf('%2.0fs',max(Anestimes))},...
        'YTick',[0 40-0.9 max(FAnes)],'YTickLabel',{'','0.91',''});
    title(specGramAnesth,'Anesth LFP')
    
    params.Fs = 500;
    params.err = [2,0.5];
    params.tapers = [3 5];
    params.fpass = [0 40];
    specAnesth = subplot(2,3,4);
    [SAnes,fAnes,SerrAnes] = mtspectrumc(LFPAnes.LFPData,params);
    plot(SAnes/sum(SAnes),fAnes,'r');
    set(specAnesth,'YTick',[0  fAnes(SAnes==max(SAnes)) 40],...
        'YTickLabel',{'',sprintf('%2.1f',fAnes(SAnes==max(SAnes))),'40Hz'},...
        'XTick',[]);
    axis([0 max(SAnes) 0 40])
    
    
    specAwake = subplot(2,3,1);
    [SAwk,fAwk,SerrAwk] = mtspectrumc(LFPAwk.LFPData,params);
    plot(SAwk/sum(SAwk),fAwk,'b');
    axis tight
    set(specAwake,'YTick',[0  fAwk(SAwk==max(SAwk)) 40],...
        'YTickLabel',{'',sprintf('%2.1f',fAwk(SAwk==max(SAwk))),'40Hz'},...
        'XTick',[]);
    axis([0 max(SAwk) 0 40])
    xlabel('NormalizedPower');
    ylabel('frequency(Hz)')
    
end
end


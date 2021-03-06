function COSYNE_plotWnByAnesth
%% find the analyses
% db.plotByAnalysis({'gaussianFullField','Temporal'})
if ~exist('db','var')
    db = neuronDB('cosyne2011');
end
params.excludeNIDs = [2 12 14 15 17 18 19 27 30 34 37 46 48 49];
[ainds nids subainds] = db.selectIndexTool('gaussianFullField',params);

whichRepeat = false(size(nids));
uniqNIDs = unique(nids);
for i = uniqNIDs
    currReps = find(nids==i);
    currReps(1) = [];
    whichRepeat(currReps)=true;
end
nids = nids(~whichRepeat);
ainds = ainds(~whichRepeat);
subainds = subainds(~whichRepeat);


anesth = nan(size(ainds));
% get anesthesia
for i = 1:length(ainds)
    anesth(i) = db.data{nids(i)}.analyses{subainds(i)}.getAnesthesia;
end
anesth(isnan(anesth)) = 2.0;

whichAwake = anesth==0;
whichAnesth = ~whichAwake;


% choose 9e
whichAwake =find(whichAwake);
whichAnesth=find(whichAnesth);
whichAwake(3) = [];

%% awake
f = figure;
for i = 1:6
    [row col] = ind2sub([3,7],i);
    corrind = sub2ind([7 3],col,row);
    ax = subplot(3,7,corrind);hold on;
    
    t = db.data{nids(whichAwake(i))}.analyses{subainds(whichAwake(i))}.getTimeWindow;
    [m , ~, sem] = db.data{nids(whichAwake(i))}.analyses{subainds(whichAwake(i))}.getTemporal;
    t = linspace(-t(1),t(2),length(m));
    plot(minmax(t),[127.5 127.5],'color',brighten([0.1 0.1 0.1],0.8))
    plot([0 0],[0 255],'color',brighten([0.1 0.1 0.1],0.8))
    fill([t fliplr(t)]',[m+sem;flipud(m-sem)],brighten([0.1 0.1 0.8],0.7))
    plot(t,m,'b','LineWidth',3);
    axis([minmax(t) 0 255]);
    if corrind~=15
        set(ax,'XTick',[],'YTick',[]);
    else
        set(ax,'XTick',[-200 50],'XTickLabel',{'-200','50ms'},'YTick',[0 255],'YTickLabel',{'black','white'});
        set(ax,'FontSize',13)
    end

end


%% aneths
for i = 1:15
    [row col] = ind2sub([3,7],i+6);
    corrind = sub2ind([7 3],col,row);
    ax = subplot(3,7,corrind);hold on;
    t = db.data{nids(whichAnesth(i))}.analyses{subainds(whichAnesth(i))}.getTimeWindow;
    [m , ~, sem] = db.data{nids(whichAnesth(i))}.analyses{subainds(whichAnesth(i))}.getTemporal;
    t = linspace(-t(1),t(2),length(m));
    plot(minmax(t),[127.5 127.5],'color',brighten([0.1 0.1 0.1],0.8))
    plot([0 0],[0 255],'color',brighten([0.1 0.1 0.1],0.8))
    fill([t fliplr(t)]',[m+sem;flipud(m-sem)],brighten([0.8 0.1 0.1],0.7))
    plot(t,m,'r','LineWidth',3);
    axis([minmax(t) 0 255]);
%     if i~=4
        set(ax,'XTick',[],'YTick',[]);
%     else
%         set(ax,'XTick',[-200 0 50],'XTickLabel',{'-200','0','50ms'},'YTick',[0 255],'YTickLabel',{'black','white'});
%         set(ax,'FontSize',16)
%     end

end
    
    

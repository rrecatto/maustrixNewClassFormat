function out = modelPopulation
tTotal = 250;
tPre = 50;
tStim = 16;

gwin = gausswin(20);
gwin = gwin/sum(gwin);

t1 = [];
t2 = [];

f1 = [];
f2 = [];

for neuronNum = 1:1
    contrastModel.c = 1;
    contrastModel.n = 4;
    Cs = [0.1:0.1:1];
    x = randperm(10);
    contrastModel.a = Cs(x(1));
    
    trials = 400;
    fBkgd = 0.5/1000;
    fDriven = 0.5/1000;
    latency = 45;
    
    out1 = modelResponses(tTotal,tPre,tStim,contrastModel,trials,fBkgd,fDriven,latency);

    meanResp = conv(mean(out1.raster), gwin, 'same');
    spPertrial = sum(out1.raster,2);
    f1(end+1) = sum(spPertrial==0);
    t1(end+1) = find(meanResp==max(meanResp),1,'first');
    out.r1 = out1.raster;
    out.s1 = out1.stim;
    
    contrastModel.c = 0.1;
    contrastModel.n = 4;
    contrastModel.a = Cs(x(1));
    
    trials = 400;
    fBkgd = 0.5/1000;
    fDriven = 30/1000;
    latency = 52;
    
    out2 = modelResponses(tTotal,tPre,tStim,contrastModel,trials,fBkgd,fDriven,latency);
    meanResp = conv(mean(out2.raster), gwin, 'same');
    spPertrial = sum(out2.raster,2);
    f2(end+1) = sum(spPertrial==0);
    t2(end+1) = find(meanResp==max(meanResp),1,'first');
    out.r2 = out2.raster;
    out.s3 = out2.stim;
end
out.f1 = f1;
out.t1 = t1;
out.f2 = f2;
out.t2 = t2;
plotOn = false
if plotOn
    plot(1:tTotal,trials+1+out.stim(1:tTotal))
    
    set(gca,'xlim',[0 tTotal],'ylim',[1 trials+2])
    
    plot(t1-tPre,t2-tPre,'k.'); hold on;
    set(gca,'xlim',[0 250],'ylim',[0 250]);
    plot([0 250],[0 250],'k')
end
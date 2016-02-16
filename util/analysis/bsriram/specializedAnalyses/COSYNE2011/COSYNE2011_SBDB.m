ID=1; % neuronID
subj='389'; thrV=[-Inf 0.5 2]; included=true;channels = 1;
db=db.addSingleUnit(subj,ID,'',{...
    [7:11]   ,channels, NaN,included,thrV,'TRF';...
    [13:16]  ,channels, NaN,included,thrV,'clean spatial';...
    [17:18] ,channels, NaN,included,thrV,'still visible';...
    });

ID=ID+1;
subj='389'; thrV=[-Inf 0.2 2]; included=true;channels = 1;
db=db.addSingleUnit(subj,ID,'',{...
    [21]   ,channels, NaN,included,thrV,'TRF';...
    [23:25]  ,channels, NaN,included,thrV,'spatial at bottom';...
    [17:18] ,channels, NaN,included,thrV,'still visible';...
    });
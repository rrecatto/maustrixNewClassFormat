function db=initPMM(db)
            %manually built here, can't we automate this?
            %contains: 231

            ID=1; % neuronID
            subj='231'; thrV=[-Inf 0.1 2]; included=1;channels = 1; anesth =2.0;
            %thrV=[-0.05 Inf 2]; was okay;  [-0.15 Inf 2]; was not okay
            db=db.addSingleUnit(subj,ID,channels,'first cell tested',{...
                [4]      ,4,included,thrV,anesth,'TRF - great!';...
                [46 47 48 50 51 58 62 63]  ,4,included,thrV,anesth,'ffgwn';...
                [103:114],4,included,thrV,1.0,'fff contr drive it weakly. (step 40)'})
            % [93:110] ,NaN,included,thrV,anesth,'6x8 bin DUPPED';...
            
            ID=2;
            subj='231'; thrV=[-Inf 0.5 2]; included=1;channels = 1; anesth =2; %thrV=[-0.05 Inf 2]; lots of seperable noise
            db=db.addSingleUnit(subj,ID,channels,'tested at -0.05; -0.2 is great SNR cuttoff w/ no noise',{...
                [152:154],5,included,thrV,anesth,'ffgwn';...
                [158],5,included,thrV,anesth,'trf! - may be good but skipped';...
                [168]    ,5,included,thrV,anesth,'fff'}) %[169 172] error
             %[134]    ,NaN,included,thrV,anesth,'trf';...  %bad trial...no frames?
             
            %db.save; keyboard; % stop now.  a small database is good enough for tests
            
            ID=3;
            subj='231'; thrV=[-Inf 0.1 2]; included=1;channels = 1; 
            %thrV=[-Inf 0.05 2]; gets lots of noise, 0.1 only 1 noisesamp and all spikes
            db=db.addSingleUnit(subj,ID,channels,'',{...
                [269]    ,3,included,thrV,anesth,'trf';...
                [272]    ,3,included,thrV,anesth,'fffc'})
            
            ID=4;
            subj='231'; thrV=[-0.08 Inf 0.4]; included=1;channels = 1; anesth =1.5;
            db=db.addSingleUnit(subj,ID,channels,'',{...
                [356]    ,3,included,thrV,anesth,'trf';...
                [361 368],3,included,thrV,anesth,'fffc';...
                [370]    ,3,included,thrV,anesth,'sf'})
           
            ID=5;
            subj='231'; thrV=[-0.05 Inf 2]; included=1;channels = 1;
            db=db.addSingleUnit(subj,ID,channels,'this is MUA, removed 463',{...
                [456]    ,2,included,thrV,1.5,'radii';...
                [458]    ,2,included,thrV,1.5,'annuli';...
                [499:502],2,included,thrV,1.5,'ffgwn- iso high';...
                [511:519],2,included,thrV,0.75,'ffgwn- iso 0.75; till 506?';...
                [528:540],2,included,thrV,0.25,'ffgwn- iso 0.25; lost cell?'})
            %removed 463 bipartite for XY b/c error:  no frames found on chunk 5 which is not the last one! (trial 463 has 8 chunks)     
             % [508]    ,2,included,thrV,0.75,'SHOULD BE fc- iso 0.75 ... yet found ffgwn';...
                                
            ID=6;
            subj='231'; thrV=[-0.2 Inf 2]; included=1;channels = 1; q=4; anesth= 1.0;
            % thrV=[-0.2 Inf 2]; results in some no spikes found... maybe
            % try more inclusive?
            db=db.addSingleUnit(subj,ID,channels,'sorting handled by thresh',{...
                [615:628],q,included,thrV,anesth,'ffgwn- anesth moved from 1.5 to 1.0 on trial 624';...
                [629:634],q,included,thrV,anesth,'tf';...
                [635 636 638:642],q,included,thrV,anesth,'6x8bin';...
                [646    ],q,included,thrV,anesth,'fff- anesth';...
                [651:666],q,included,thrV,anesth,'fffc- anesth,  cell was more excitable on trial 663';...
                [671:678],q,included,thrV,anesth,'nat gratings';...
                [681:682],q,included,thrV,anesth,'trf';...
                [736:737],q,included,thrV,anesth,'sparse confirm location';...
                [748:752],q,included,thrV,anesth,'f contrast, cicular hack - 1 rep b/c memory';...
                [764:768],q,included,thrV,anesth,'fffc - iso at 1%';...
                [780:792],q,included,thrV,anesth,'fffc - still no whisking, but stable and light';...
                [793:797],q,included,thrV,anesth,'fffc - poking the rat, and trying to get him to wake'})
            
            %JULY 3rd, 2010
            ID=7;
            subj='231'; thrV=[-Inf 0.2 2]; included=1; channels = 1; q=4; anesth= 1.25;
            %thrV=[-Inf 0.25 2] was sparse.. did it miss some?
            db=db.addSingleUnit(subj,ID,channels,'spatial sta broken... not worth rescuing',{...
                [806:830], q,included,thrV,anesth,'gwn';...
                [831:832], q,included,thrV,anesth,'NAT GRATING';...
                [834:836], q,included,thrV,anesth,'fffc';...
                [853]    , q,included,thrV,anesth,'sf  - WORTH ANALYZING'});
                %[838:844], q,included,thrV,anesth,'sparse brighter 6x8; some hbars and vbars follow';...
                %[866:871], q,included,thrV,anesth,'bin6x8'})
            
            ID=8;
            subj='231'; thrV=[-0.15 Inf 2]; included=1;channels = 1; q=3; anesth= 1.25;
            db=db.addSingleUnit(subj,ID,channels,'',{...
                [878:887], q,included,thrV,anesth,'gwn';...
                [889:906], q,included,thrV,anesth,'fffc - frames drop in begining, fewer drops later  (897 has noise)';...
                [909:913], q,included,thrV,anesth,'NAT GRATING';...
                [915 937], q,included,thrV,anesth,'bin 6x8; nothing obvious spatial first run';...
                [941], q,included,thrV,anesth,'sf'})
            
            ID=9;
            subj='231'; thrV=[-Inf .2 2]; included=1;channels = 1;  q=2; anesth= 1.25;
            db=db.addSingleUnit(subj,ID,channels,'',{...
                [956:960], q,included,thrV,anesth,'gwn';...
                [965], q,included,thrV,anesth,'sf, some drops';...
                [967], q,included,thrV,anesth,'or, some drops';...
                [969:983], q,included,thrV,anesth,'bin 6x8, some drops';...
                [995:1009], q,included,thrV,anesth,'fffc, background firing rate modulation - java mem. NEED TO TURN OFF SOME PLOTS TO SEE IT';...
                [1011:1012], q,included,thrV,anesth,'nat gratings';...
                [1022:1027], q,included,thrV,anesth,'bin6x8 - eyes prob stable';...
                [1053:1063], q,included,thrV,anesth,'bin12x16'})
            db.data{db.numNeurons}=db.data{db.numNeurons}.addComment('drifting on trials: 1056,1062 (prob others too, but def those)');
            db.data{db.numNeurons}=db.data{db.numNeurons}.addComment('SNR decreases after trial 1074 making it challenging to detect and sort spikes');
            % [1028:1046], q,included,thrV,anesth,'bin6x8 - eye moves, drifts';... %this gets bound to the good eyes... removing it
            

            ID=10;
            subj='231'; thrV=[-0.08 Inf 2]; included=1;channels = 1;  anesth= 1.0;
            db=db.addSingleUnit(subj,ID,channels,'at 1270 goes on iso. but cell keeps changing size and would be tricky to sort, so not going to do it',{...
                [1163:1173], 4,included,thrV,anesth,'gwn';...
                [1197:1209], 4,included,thrV,anesth,'fffc, random seed set to 1, 6 reps ... confirmed visually that the OFF high contrast spiked most... didn''t trust the contrast at the time of recording, prob b/c the analysis was broken'})
            
            
            %THIS IS ACTUALLY THE SAME CELLL... should merge it back after
            %analysing both
            ID=11;
            subj='231'; thrV=[-0.08 Inf 2]; included=1;channels = 1;  anesth= 1.0;
            db=db.addSingleUnit(subj,ID,channels,'SAME CELL at 1270 goes on iso. but cell keeps changing size and would be tricky to sort, so not going to do it',{...
                [1235:1269], 4,included,thrV,anesth,'fffc, randomized to clock once per trial, 4 reps'})

            
            
            ID=12;
            subj = '364'; thrV=[-0.1 Inf 2]; included=1; channels = 1; anesth=1.0;
            db=db.addSingleUnit(subj,ID,channels,'',{...
                [26:32],5,included,thrV, anesth,' %ffgwn';...
                [43:62],5,included,thrV, anesth,' %ffc, at top of screen, but cell is more active';...
                [147:160],5,included,thrV,anesth,'ffc, after center on screen'}) %[-0.08 Inf 0.3]
            

            ID=13;
            subj = '262'; thrV=[-0.2 Inf 2]; included=1;channels = 1; anesth=1.0;
            db=db.addSingleUnit(subj,ID,channels,'',{...
                [34:41],3,included,thrV, anesth,'ffgwn - has temporal STA';...
                [120:123],3,included,thrV, anesth,'spatial binary'})
            %%[70],NaN,included,thrV, anesth,'gratingsSF';...  %drop frames questuionable
            %[118:123],NaN,included,thrV, anesth,'spatial binary'}) could use but, memory during analysis >1GB
            
            
            ID=14;
            subj = '261'; thrV=[-0.05 Inf 2]; included=1;channels = 1; anesth=1.5;
            db=db.addSingleUnit(subj,ID,channels,'',{...
                [118:121],4,included,thrV, anesth,'ffgwn'})
            %%[117],NaN,included,thrV, anesth,'grating'})  % 2 features vary
            
            ID=15;
            subj = '261'; thrV=[-0.05 Inf 2]; included=1;channels = 1; anesth=1.5;
            db=db.addSingleUnit(subj,ID,channels,'',{...
                [244 252 271:272],5,included,thrV, anesth,'ffgwn'})

            
            ID=16;
            subj = '261'; thrV=[-0.05 Inf 2]; included=1;channels = 1; anesth=1.5;
            db=db.addSingleUnit(subj,ID,channels,'',{...
                [288:293],3,included,thrV, anesth,'ffgwn';...
                [294],3,included,thrV, anesth,'sf';...
                [324:332],3,included,thrV, anesth,'bin grid, 3x4';...
                [341:346 351:359],3,included,thrV, anesth,'bin grid, 6x8'});
            db.data{db.numNeurons}=db.data{db.numNeurons}.addComment('347 has issues sorting');
            
            ID=17;
            subj = '249'; thrV=[-0.05 Inf .3]; included=1;channels = 1; anesth=1.5;
            db=db.addSingleUnit(subj,ID,channels,'',{...
                [523:554],4,included,thrV, anesth,'ffgwn'})
            
            ID=18;
            subj = '249'; thrV=[-0.1 Inf 2]; included=1;channels = 1; anesth=1.5;
            db=db.addSingleUnit(subj,ID,channels,' not pursuing some more cells on this rat, with horix & vert noise bars, slow gratings at 423 plus',{...
                [187],2,included,thrV, anesth,'sf gratings';...
                [188:190],2,included,thrV, anesth,'or gratings';...
                [196:225],2,included,thrV, anesth,'wn'})
            %    [160:185],NaN,included,thrV, anesth,'varaious bars mixed';...
            
            ID=19;
            subj = '230'; thrV=[-0.05 Inf 2]; included=1;channels = 1; anesth=1.25;
            db=db.addSingleUnit(subj,ID,channels,'',{...
                [137:140],4,included,thrV, anesth,'whiteNoise';...
                [142 ],4,included,thrV, anesth,'flanker FF contrast'})

            
            ID=20;
            subj = '230'; thrV=[-0.2 Inf 2]; included=1;channels = 1; anesth=1.25;
            db=db.addSingleUnit(subj,ID,channels,'some shifts in state for this cell',{...
                [144:155],3,included,thrV, anesth,'ffgwn';...
                [157:162 200:208],3,included,thrV, anesth,'flanker FF contrast, no stationary state (.05 Hz osillation in state).. merged with 200-208'})
            %[],3,included,thrV, anesth,'fffc,  the bursting in the background is not stim entrained and the LFP gets crazier'})
            %tr 228 too much chatter, too poor of a sort.  cant drive with gratings,cantmoving on. statefullness has been well documented' 
            
            ID=21;
            subj = '230'; thrV=[-0.05 Inf 2]; included=1;channels = 1; anesth=1.25;
            db=db.addSingleUnit(subj,ID,channels,'',{...
                [260:272],3,included,thrV, anesth,'fffc, ppc=180';...
                [274:289],3,included,thrV, anesth,'fffc, ppc=32, distance = 24cm ... uh oh, 276+ may need to be rescued'})
            % [229:236],NaN,included,thrV, anesth,'ffgwn? maybe?';...

            ID=22;
            subj = '230'; thrV=[-0.2 Inf 2]; included=1;channels = 1; anesth=1.25;
            db=db.addSingleUnit(subj,ID,channels,'some shifts in state for this cell',{...
                 [165 166 167 169],3,included,thrV, anesth,'%gratings, down state'})
            
              db=db.flushAnalysisData; 
            db.save;
                   
            %db=addMorePmmNeurons(db,db.numNeurons);
            
            %db=db.includeAll;
            %db=db.includeQualityAtLeast(4);
        end
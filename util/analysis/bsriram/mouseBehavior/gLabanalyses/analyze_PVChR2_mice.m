function analyze_PVChR2_mice

Subjects = {'247','249','227','246'};




%% plot VarDur

analysisFor.analyzeOpt = false;
analysisFor.analyzeImages = false;
analysisFor.analyzeRevOpt = false;
analysisFor.analyzeContrast = false;
analysisFor.analyzeRevContrast = false;
analysisFor.analyzeSpatFreq = false;
analysisFor.analyzeRevSpatFreq = false;
analysisFor.analyzeOrientation = false;
analysisFor.analyzeRevOrientation = false;
analysisFor.analyzeTempFreq = false;
analysisFor.analyzeRevTempFreq = false;
analysisFor.analyzeCtrSensitivity = false;
analysisFor.analyzeQuatRadContrast = false;
analysisFor.analyzeImagesContrast = false;
analysisFor.analyzeVariedDurations = false;
analysisFor.analyzeORLED = true;
analysisFor.tsName = 'or_VarCAndLEDPDPhases';

filters = 736105:736109; %'Jun-17-2013':today
trialNumCutoff = 25;

splits.daysPBS = [];
splits.daysCNO = [];
splits.daysIntact = [];
splits.daysLesion = [];

f = figure('name','PERFORMANCE BY VARIED DURATION');
plotDetails.plotOn = true;
plotDetails.plotWhere = 'givenAxes';
plotDetails.requestedPlot = 'performanceByLED';% performanceByCondition,performanceByLED
plotDetails.plotMeansOnly = true;

% plotDetails.axHan = subplot(1,1,1);
compiledFilesDir = '\\ghosh-nas.ucsd.edu\ghosh\Behavior\VarDur2\Compiled';
% compiledFilesDir = {compiledFilesDir,compiledFilesDir,compiledFilesDir,compiledFilesDir,compiledFilesDir,compiledFilesDir};
% for i = 1:6
% c1 = analyzeMouse('246',filters,plotDetails,trialNumCutoff,analysisFor,splits,compiledFilesDir);
plotDetails.axHan = subplot(1,3,1);
c2 = analyzeMouse('247',filters,plotDetails,trialNumCutoff,analysisFor,splits,compiledFilesDir);
plotDetails.axHan = subplot(1,3,2);
c3 = analyzeMouse('249',filters,plotDetails,trialNumCutoff,analysisFor,splits,compiledFilesDir);
plotDetails.axHan = subplot(1,3,3);
c4 = analyzeMouse('252',filters,plotDetails,trialNumCutoff,analysisFor,splits,compiledFilesDir);
% end


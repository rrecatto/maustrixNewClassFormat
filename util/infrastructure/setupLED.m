function [details, stim] = setupLED(details, stim, LEDParams,arduinoCONN)
if ~LEDParams.active
    details.LEDON = false;
    details.chosenMode = [];
    details.whichLED = [];
    details.LEDIntensity = [0 0];
    
    
    chosenParam.LED1ON = false;
    chosenParam.LED2ON = false;
    stim.LEDParam = chosenParam;
    return
end

% lets find the information to send across

% choose a random number and figure out where it leas on
% cumulativeFractions
whichRND = rand;
whichMode = find((LEDParams.cumulativeFraction<whichRND==1),1,'last');

details.LEDON = true;
details.chosenMode = whichMode;
details.whichLED = LEDParams.IlluminationModes{whichMode}.whichLED;

if ismember(details.whichLED,1)
    chosenParam.LED1ON = true;
    LED1Intensity = uint8(LEDParams.IlluminationModes{whichMode}.intensity(LEDParams.IlluminationModes{whichMode}.whichLED==1)*255);
    if LED1Intensity==0
        chosenParam.LED1ON = false;
    end
else
    chosenParam.LED1ON = false;
    LED1Intensity = 0;
end

if ismember(details.whichLED,2)
    chosenParam.LED2ON = true;
    LED2Intensity = uint8(LEDParams.IlluminationModes{whichMode}.intensity(LEDParams.IlluminationModes{whichMode}.whichLED==2)*255);
    if LED2Intensity==0
        chosenParam.LED2ON = false;
    end
else
    chosenParam.LED2ON = false;
    LED2Intensity = 0;
end
details.whichLED = [1,2];
details.LEDIntensity = [LED1Intensity,LED2Intensity];

% % now write these numbers to the Arduino

fwrite(arduinoCONN,LED1Intensity);

stim.LEDParam = chosenParam;

end


classdef mouse < murine
    properties
        species = 'mouse';
        geneticBackground = '';
        backgroundInformation = {};
    end
    
    methods
        function m = mouse(id,strain,gender,birthDate,receivedDate,litterID,supplier,geneticBackground, backgroundInformation)
            m = m@murine(id,strain,gender,birthDate,receivedDate,litterID,supplier);
            m.geneticBackground = geneticBackground;
            if exists('backgroundInformation','var') && ~isempty(backgroundInformation)
                m.backgroundInformation = backgroundInformation;
            end
        end
        
        function display(s,str)
            if (~exist('str','var')||isempty(str)), str = ''; end
            dispStr = sprintf('species:\t\t%s\t%s',s.species,str);
            display@subject(s,dispStr);
        end
        
    end
end
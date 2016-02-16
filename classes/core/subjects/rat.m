classdef rat < murine
    properties
        species = 'rat';
    end
    
    methods
        function r = rat(id,strain,gender,birthDate,receivedDate,litterID,supplier)
            r = r@murine(id,strain,gender,birthDate,receivedDate,litterID,supplier);
        end
        
        function display(s,str)
            if (~exist('str','var')||isempty(str)), str = ''; end
            dispStr = sprintf('species:\t\t%s\t%s',s.species,str);
            display@subject(s,dispStr);
        end
        
    end
    
end
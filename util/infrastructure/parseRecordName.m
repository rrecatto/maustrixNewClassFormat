function out = parseRecordName(in)
out.recordType = '';
out.trialNumberBegin = [];
out.trialNumberEnd = [];

out.timestampBegin = '';
out.timestampEnd = '';

[path, name,ext] = fileparts(in)
if strfind(name,'trialRecords')
    out.recordType = 'trialRecords';
end
switch out.recordType
    case 'trialRecords'
        [matches, tokens] = regexpi(name, sprintf('%s_(\\d+)-(\\d+)_(\\w*)-(\\w*)',out.recordType), 'match', 'tokens');
        if isempty(matches)
            warning('match not found. why?');
        else
            out.trialNumberBegin = str2num(tokens{1}{1});
            out.trialNumberEnd = str2num(tokens{1}{2});
            
            out.timestampBegin = tokens{1}{3};
            out.timestampEnd = tokens{1}{4};
        end
    otherwise
        error('unknown record type')
end

end
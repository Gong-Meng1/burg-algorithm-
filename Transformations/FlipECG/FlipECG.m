function [EEG, options] = FlipECG(input,opts)
%% Check for the EEG dataset input:
if (nargin < 1)
    ME = MException('Alakazam:FlipECG','Problem in IBIExport: No Data Supplied');
    throw(ME);
end
options = [];
if ~isfield(input, 'data')
    return
else
    EEG = input;
    ecgData = input.data;
end

if (size(ecgData,1) > 1 )
    ecgid = contains({input.chanlocs.labels},'ECG');
    if sum(ecgid)>0
        %% there is an ECG trace: flip it
        ecgData = ecgData(ecgid,:);
        necgData = -(ecgData - median(ecgData)) + median(ecgData);
        EEG.data(ecgid,:) = necgData;
    else
        throw(MException('Alakazam:FlipECG','Problem in FlipECG: No ECG trace Found/Supplied'));    
    end
end

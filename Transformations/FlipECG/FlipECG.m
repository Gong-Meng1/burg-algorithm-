function [EEG, options] = FlipECG(input,opts)
%% Flip the EGC trace if it is upside down....

%% Check for the EEG dataset input:
if (nargin < 1)
    throw(MException('Alakazam:FlipECG','Problem in FlipECG: No Data Supplied'));
end

options = [];

if ~isfield(input, 'data')
    throw(MException('Alakazam:FlipECG','Problem in FlipECG: No Correct Data Supplied'));
else
    EEG = input;
    ecgData = input.data;
end

if (size(ecgData,1) > 1 )
    ecgid = startsWith({input.chanlocs.labels},{'ECG', 'Polar'}, 'IgnoreCase', true);
    if sum(ecgid)>0
        %% there is an ECG trace: flip it
        ecgData = ecgData(ecgid,:);
        necgData = -(ecgData - median(ecgData,2)) + median(ecgData,2);
        EEG.data(ecgid,:) = necgData;
    else
        throw(MException('Alakazam:FlipECG','Problem in FlipECG: No ECG trace Found/Supplied'));    
    end
end

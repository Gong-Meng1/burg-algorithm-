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
    ecgid = startsWith({input.chanlocs.labels},{'ECG', 'Polar', 'Unknown'}, 'IgnoreCase', true);
else
    ecgid=1;
end

if sum(ecgid) > 0
    %% there is an ECG trace: flip it
    for c = 1:input.nbchan
        if ecgid(c) 
            channel_ecgData = ecgData(c,:);
            necgData = -(channel_ecgData - median(channel_ecgData,2)) + median(channel_ecgData,2);
            EEG.data(c,:) = necgData;
        end
    end
else
    throw(MException('Alakazam:FlipECG','Problem in FlipECG: No ECG trace Found/Supplied'));
end
end

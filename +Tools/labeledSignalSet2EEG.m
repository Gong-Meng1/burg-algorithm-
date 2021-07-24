function EEG = labeledSignalSet2EEG(EEG)
%% labeledSignalSet2EEG convert labeledSignalSet to similar eeglab EEG structure
% SIGNALSET AS PART OF THE EEG DATASTRUCTURE!
% (ur)Events are replaced by the labels in th elss structure.

% Part of Alakazam
% Mark Span 2021 (m.m.span@rug.nl)
%% -------------------------------------------------------------------------------------------
if isempty(EEG) || isempty(EEG.lss)
    return
end
codes = getLabelNames(EEG.lss);
vals = getLabelValues(EEG.lss);


urevent = [];
bvindex = 1;
for e = 1:length(codes)
    for i = 1:height(vals.(codes(e)){:,:})
        val = vals.(codes(e)){1}.ROILimits(i,1:2)*EEG.srate;
        urevent(end+1).latency = round((val(1))+1); %#ok<AGROW>
        urevent(end).duration = round(val(2)-val(1)); %this is weird....
        urevent(end).channel = 0;
        urevent(end).bvtime = 0;
        urevent(end).bvmknum = bvindex; bvindex = bvindex + 1;
        urevent(end).type = vals.(codes(e)){1,1}.Value(i);
        urevent(end).code = codes(e);
    end
end
EEG.urevent = urevent;
end

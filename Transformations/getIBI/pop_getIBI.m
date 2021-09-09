function [EEGstruct, par] = pop_getIBI(EEGstruct,varargin)
%(ecgData, ecgTimestamps, varargin)
%  GETIBI Detects the IBI values from a ECG trace. Using interpolation to get ms. precision
% 
% Algorithm developed by A.M. van Roon for PRECAR (CARSPAN preprocessing).
% 
% Matlab version M.M.Span (2021)
par = [];
ecgData = EEGstruct.data;
if (size(EEGstruct.data,1) >1 )
    try
        ecgid = contains({EEGstruct.chanlocs.labels},'ECG');
    catch ME %#ok<NASGU>
        return
    end
    if sum(ecgid)>0
        ecgData = ecgData(ecgid,:);
    else
        return
    end
    %EEGstruct.times = EEGstruct.times / 1000;
end
ecgTimestamps = EEGstruct.times;

%%  default values:
fSample = EEGstruct.srate;
MinPeakHeight = median(ecgData)+(2*std(ecgData));
par.MinPeakDistance = .50; %seconds!

%% Parse the name - value pairs found in varargin
%------------------------------------------------------------------------------------------
if (~isempty(varargin))
    par = varargin{1};
end
%% ------------------------------------------------------------------------------------------
% if no sampleRate is given, calculate it from the samples and the
% timestamps

%duration = ecgTimestamps(end)-ecgTimestamps(1);
%par.fSample = round(1.0/(duration / length(ecgTimestamps)));

%% convert MinPeakDistance from ms to samples
MinPeakDistance = par.MinPeakDistance*fSample;


%% Then, first find the (approximate) peaks
[~,locs] = findpeaks(ecgData,'MinPeakHeight',MinPeakHeight,...
    'MinPeakDistance',MinPeakDistance);
vals = ecgData(locs);
disp(['*found '  int2str(length(vals))  ' r-tops'])
%% Now the algorithm can start.
%------------------------------------------------------------------------------------------
rc = max(abs(vals - ecgData(locs - 1)), abs(ecgData(locs + 1) - vals));
try
    correction =  (ecgData(locs + 1) - ecgData(locs - 1)) / fSample / 2 ./ abs(rc);
catch ME
    causeException = MException('MATLAB:getIBI:divisionbyzero', 'rc is zero at some point in the data');
    ME = addCause(ME,causeException);
    rethrow(ME);
end

%% TODO add them to the urevent field of the EEG struct

% then this can go
EEGstruct.RTopTime = ecgTimestamps(locs) + correction;
EEGstruct.RTopVal = ecgData(locs);
EEGstruct.ibis = round(diff(EEGstruct.RTopTime),3);

end

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
        ecgid = strcmpi({EEGstruct.chanlocs.labels},'ECG');
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
par.MinPeakDistance = .33; %seconds!

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

%% Because the eventtimes for the r-top are interpolated they do not fit 
%% the event structure. We keep them separated

EEGstruct.IBIevent.RTopTime = ecgTimestamps(locs) + correction;
EEGstruct.IBIevent.RTopVal = ecgData(locs);
EEGstruct.IBIevent.ibis = round(diff(EEGstruct.IBIevent.RTopTime),3);

end

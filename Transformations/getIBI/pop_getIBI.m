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
par.MinPeakDistance = .250; %seconds!
par.deTrend = false;
par.Plot = false;

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
%% ------------------------------------------------------------------------------------------
% are we asked to detrend the data? Detrend algorithm in this file (below).
oData = ecgData;
if (par.deTrend)
   ecgData = deTrend(ecgData);
end


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

EEGstruct.RTopTime = ecgTimestamps(locs) + correction;
EEGstruct.RTopVal = ecgData(locs);
EEGstruct.ibis = round(diff(EEGstruct.RTopTime),3);

if (par.Plot) % Plot algorithm in this file (below)
    figure
    plot(ecgTimestamps,oData)
    PlotECGWithIBIS(ecgTimestamps,ecgData,locs,EEGstruct.RTopTime)
end
end
%%
function ecgData = deTrend(ecgData)
    [p,~,mu] = polyfit((1:numel(ecgData))',ecgData,6);
    f_y = polyval(p,(1:numel(ecgData))',[],mu);
    ecgData = ecgData - f_y;        % Detrend data
end
%%
function PlotECGWithIBIS(ecgTimestamps,ecgData,locs,rtops)
    %% Plot the ECG trace data
  
    ibis = round(diff(rtops/1000),3);
    hold on
    plot(ecgTimestamps,ecgData)
    xlim([ecgTimestamps(1) min(ecgTimestamps(1)+10000,ecgTimestamps(end))]);
    grid on
    title('(Detrended) ECG Signal (mV)')
    xlabel('time (sec)')
    ylabel('Voltage(mV)')
    
    %%  PLOT the Triggered R-tops
    hold on
    plot(rtops,ecgData(locs),'ro')
    
    %% also plot thim at the top of ther plot:
    ml = max(ylim);
    nd = (ecgData(locs)*0) + ml;
    plot(rtops,nd,'rv','MarkerFaceColor','r')
    
    %% Plot the IBI value labels in between the top r-top markers:
    text( double(rtops(1:end-1) + rtops(2:end))/2, ...
        double(nd(1:end-1))-50,...
        int2str(ibis(:)*1000),...
        'FontSize', 8, 'HorizontalAlignment', 'center');
    hold off
    legend('Detrended ECG Signal', 'R-Top')    
end
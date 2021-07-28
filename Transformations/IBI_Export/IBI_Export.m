function [EEG, options] = IBI_Export(input,opts)
%% Example Transformation simply calling EEGLAB function
% Calls the SignalLabeler App from the signal processing toolkit
% First copies the current ECG file to a labeledSignalSet to be used by the
% SignalLabeler. When finished, copies the areas to the event section of
% the EEG struct.

%% Check for the EEG dataset input:
if (nargin < 1)
    ME = MException('Alakazam:Export','Problem in Export: No Data Supplied');
    throw(ME);
end
[p,n,~] = fileparts(input.File);
if exist('opts', 'var')
    options = opts;
else    
    options = Tools.settingsdlg(...
        'Description', 'Set the parameters for ''export'' ibi',...
        'title' , 'IBIExport options',...
        'separator' , 'File Parameters:',...
        {'Filename' ;'fname' }, [n '.csv'],...
        {'Calculate subsequent differences'; 'cdif'}, {'yes','no'},...
        {'Resample' ; 'rsamp'},  {'yes','no'});       
end

csvwrite(fullfile(p,options.fname), input.ibis')

EEG=input;
if (strcmp(options.cdif, 'yes'))
    EEG.data = double([input.ibis' [0 diff(input.ibis)]']);
    EEG.nbchan = 2;
else
    EEG.data = double(input.ibis');
    EEG.nbchan = 1;
end

if (strcmp(options.rsamp, 'yes'))
    [EEG.data, EEG.times] = resample(EEG.data, double(EEG.RTopTime(1:end-1)), EEG.srate);
else
    EEG.times = double(EEG.RTopTime(1:end-1));
    EEG.srate = 0;
end    
EEG.YLabel = 'IBI in ms.'
EEG.data = EEG.data';
EEG = rmfield(EEG, 'ibis');

EEG.chanlocs(1).labels = 'IBI';
EEG.chanlocs(2).labels = 'IBIdif';
EEG.chanlocs = EEG.chanlocs (1:2);




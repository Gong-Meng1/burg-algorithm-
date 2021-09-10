function [EEG, options] = IBI_Export(input,opts)
%% Example Transformation 
% 

%% Check for the EEG dataset input:
if (nargin < 1)
    ME = MException('Alakazam:IBIExport','Problem in IBIExport: No Data Supplied');
    throw(ME);
end
if ~isfield(input, 'IBIevent')
    ME = MException('Alakazam:IBIExport','Problem in IBIExport: No IBIS availeable (yet)');
    throw(ME);
end
    
[p,n,~] = fileparts(input.File);
if exist('opts', 'var')
    options = opts;
else    
    options = uiextras.settingsdlg(...
        'Description', 'Set the parameters for ''export'' ibi',...
        'title' , 'IBIExport options',...
        'separator' , 'File Parameters:',...
        {'Filename' ;'fname' }, [n '.csv'],...
        {'Calculate subsequent differences'; 'cdif'}, {'yes','no'},...
        {'Resample' ; 'rsamp'},  {'yes','no'});       
end

csvwrite(fullfile(p,options.fname), input.IBIevent.ibis')

EEG=input;
if (strcmp(options.cdif, 'yes'))
    EEG.data = double([input.IBIevent.ibis' [NaN diff(input.IBIevent.ibis)]']);
    EEG.nbchan = 2;
else
    EEG.data = double(input.IBIevent.ibis');
    EEG.nbchan = 1;
end

if (strcmp(options.rsamp, 'yes'))
    [EEG.data, EEG.times] = resample(EEG.data, double(EEG.IBIevent.RTopTime(1:end-1)), EEG.srate);
else
    EEG.times = double(EEG.IBIevent.RTopTime(1:end-1));
    EEG.srate = 0;
end    
EEG.YLabel = 'IBI in ms.'
EEG.data = EEG.data';
EEG = rmfield(EEG, 'IBIevent');

EEG.chanlocs(1).labels = 'IBI';
EEG.chanlocs(2).labels = 'IBIdif';
EEG.chanlocs = EEG.chanlocs (1:2);




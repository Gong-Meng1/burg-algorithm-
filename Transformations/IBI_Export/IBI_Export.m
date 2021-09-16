function [EEG, options] = IBI_Export(input,opts)
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
        {'By Label' ;'bylabel' }, {'yes', 'no'},...
        'separator' , 'New branch:',...
        {'Calculate subsequent differences'; 'cdif'}, {'yes','no'},...
        {'Resample' ; 'rsamp'},  {'yes','no'});       
end
RTop = squeeze(input.IBIevent.RTopTime(1:end-1))';
IBI = squeeze(input.IBIevent.ibis)';
out = table(RTop,IBI);

if (~isfield(input,'lss'))
    input.lss=Tools.EEG2labeledSignalSet(input);
end

if isempty(input.lss.Labels)
    options.bylabel = 'no';
end

if strcmpi(options.bylabel, 'yes')  
    srate = input.srate;
    % Create the variables in the table
    for label = unique({input.urevent.code})
        types = {input.urevent.type};
        labels = {input.urevent.code};
        typeinlabels = types(strcmp(label, labels));
        for value = unique(typeinlabels)
            out = [out table(zeros(length(IBI),1))]; %#ok<AGROW>
            out.Properties.VariableNames(end) = matlab.lang.makeValidName(label + "_" + value);
        end
    end
    % and fill them with the correct values
    for ev = [input.urevent]
        label = ev.code;
        value = ev.type;
        
        % ev.latency; ev.duration
        t = out.RTop;
        d = out.(matlab.lang.makeValidName(label + "_" + value));
        tstart = ev.latency / srate;
        tend   = (ev.latency + ev.duration) / srate;
        d((t>tstart) & (t<tend)) = true;
        out.(matlab.lang.makeValidName(label + "_" + value)) = d;
    end
end

writetable(out, fullfile(p,options.fname))

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




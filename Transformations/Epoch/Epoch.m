function [EEG, options] = Epoch(input,opts)
%% Create Epochs from events
% given event codes create extra labels, and give them a duration.
% duration can be based on stop code, or given duration.

%#ok<*AGROW> 

%% Check for the EEG dataset input:
if (nargin < 1)
    ME = MException('Alakazam:Epoch','Problem in Epoch: No Data Supplied');
    throw(ME);
end
%% Called with options?
if (nargin == 1)
    options = 'Init';
else
    options = opts;
end
%% copy input to output.
EEG = input;

%% What events are availeable in the dataset:
if isfield(input, 'event') ...
        && isfield(input.event, 'code') ...
        && ~isempty({input.event.code}) ...
        && isfield(input.event, 'type') ...
        && ~isempty({input.event.type})
    % evc = unique({input.event.code});
    evt = unique({input.event.type});
end

%% simplest option....
if strcmp(options, 'Init')
    options = uiextras.settingsdlg(...
        'Description', 'Set the parameters for Epoch creation',...
        'title' , 'Epoch options',...
        'separator' , 'Events:',...
        {'Start'; 'StartLabel'}, evt, ...
        {'Use endlabel or duration';'uselab'}, {'label', 'durations'}, ...
        'separator' , 'Use Endlabels:',...
        {'Label for end'; 'EndLabel'}, evt, ...
        'separator' , 'Use Durations:',...
        {'Preduration (ms)', 'pre'}, -100, ...
        {'Postduration (ms)', 'post'}, 900, ...
        'separator', 'originals', ...
        {'Remove Originals', 'remove'}, {'yes', 'no'} );
end

presamp = floor(abs((options.pre/1000.0) * input.srate));
postsamp = ceil((options.post/1000.0)* input.srate);

% presamp  = options.pre;
% postsamp = options.post;

events = input.event;
selev = strcmpi({events.type}, options.StartLabel);

for i = 1:length(selev)
    if selev(i)
        EEG.event(i).latency = max(EEG.event(i).latency + presamp,1);
        EEG.event(i).duration = (-presamp)+postsamp;
        EEG.event(i).unit = 'samples';
        EEG.event(i).preevent = presamp;
    end
end


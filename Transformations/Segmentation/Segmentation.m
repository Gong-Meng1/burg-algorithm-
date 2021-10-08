function [EEG,options] = Segmentation(input,opts)
% Segment data given a label
%   Detailed explanation goes here
EEG=input;
%% Called with options?
if (nargin == 1)
    options = 'Init';
else
    options = opts;
end
%% Check for the EEG dataset input:
if (nargin < 1)
    ME = MException('Alakazam:Segmentation','Problem in Segmentation: No Data Supplied');
    throw(ME);
end
%% What events are availeable in the dataset:
if isfield(input, 'event') ...
        && isfield(input.event, 'code') ...
        && ~isempty({input.event.code}) ...
        && isfield(input.event, 'type') ...
        && ~isempty({input.event.type}) ...
        && isfield(input.event, 'duration') ...
        && ~isempty({input.event.duration}) 
        
    % evc = unique([{input.event.code}]);
    evt = unique({input.event.type});
    durationsavaileable = mean([input.event.duration]);
    if (durationsavaileable < 3)
        ME = MException('Alakazam:Segmentation','Problem in Segmentation: No events with duration. Try Epoch');
        throw(ME);    
    end
else
    ME = MException('Alakazam:Segmentation','Problem in Segmentation: No events Supplied');
    throw(ME);    
end

end
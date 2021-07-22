function [EEG, options] = Export(input,opts)
%% Example Transformation simply calling EEGLAB function
% Transformations should return the transformed data in the EEG structure, 
% and an options variable ("options") it can understand. In this case, as
% we use the EEGLAB function, the commandline history is returned.
% Input must (in principle) contain a data structure (EEG), and optionally 
% the options variable obtained from a previous call. If this second
% variable is availeable, no user interaction takes place, but the
% Transformation is performed based op the given options. This second form
% occurs when the transformation is dragged in th tree upto another
% dataset. Simplest form.

%% Check for the EEG dataset input:
if (nargin < 1)
    ME = MException('Alakazam:Export','Problem in Export: No Data Supplied');
    throw(ME);
end
options = 15;
EEG=input;
lss = Tools.EEG2labeledSignalSet(input);
assignin('base', 'lss', lss);
existingvars = evalin('base', 'who');

signalLabeler;
uiwait(msgbox({'Operation Completed'; 'Close this box when finished labeling'}));

allvars =  evalin('base', 'who');

if length(existingvars) ~= length(allvars)
    newvar = setdiff(allvars,existingvars);
else
    newvar = 'ls2';
end
EEG.lss = evalin('base', newvar);
EEG=Tools.labeledSignalSet2EEG(EEG);


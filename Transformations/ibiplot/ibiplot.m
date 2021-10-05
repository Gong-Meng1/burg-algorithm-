function [pfigure, options] = ibiplot(input,opts)
%% Example Transformation simply calling EEGLAB function
% Create a #Dhistogram for the IBI series
% If the 'bylabel' option is used, the plot has different partitions for 
% each value the label takes on.

%% Check for the EEG dataset input:
if (nargin < 1)
    ME = MException('Alakazam:ibi plot','Problem in ibi plot: No Data Supplied');
    throw(ME);
end
if ~isfield(input, 'IBIevent')
    ME = MException('Alakazam:ibi plot','Problem in IBIExport: No IBIS availeable (yet)');
    throw(ME);
end

%% Was this a call from the menu?
if (nargin == 1)
    options = 'Init';
else
    options = opts;
end

pfigure = figure('NumberTitle', 'off', 'Name', 'ibi plot','Tag', input.File, ...
    'Renderer', 'painters' , ...
    'Color' ,[.98 .98 .98], ...
    'PaperOrientation','landscape', ...
    'PaperPosition',[.05 .05 .9 .9], ...
    'PaperPositionMode', 'auto',...
    'PaperType', 'A0', ...
    'Units', 'normalized', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none',...
    'DockControls','on', ...
    'Visible','off' ...
    );

%% need this *before* settingsdlg:
ev = [];
if isfield(input, 'urevent') && isfield(input.urevent, 'code') && ~isempty({input.urevent.code})
    ev = unique({input.urevent.code});
end

%% simplest option....
if strcmp(options, 'Init')
options = uiextras.settingsdlg(...
    'Description', 'Set the parameters for ibi plot Plot',...
    'title' , 'ibi plot options',...
    'separator' , 'Use Labels:',...
    {'By Label' ;'bylabel' }, {'no', 'yes'}, ...
    {'Use:'; 'label'}, ev);
end

pax = axes(pfigure);
if strcmp(options.bylabel, 'no')
    hi
else
     
end


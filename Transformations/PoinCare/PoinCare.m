function [pfigure, options] = PoinCare(input,opts)
%% Example Transformation simply calling EEGLAB function
% Create a poincare plot for the IBI series

%% Check for the EEG dataset input:
if (nargin < 1)
    ME = MException('Alakazam:PoinCare','Problem in PoinCare: No Data Supplied');
    throw(ME);
end
if ~isfield(input, 'IBIevent')
    ME = MException('Alakazam:PoinCare','Problem in IBIExport: No IBIS availeable (yet)');
    throw(ME);
end

%% Was this a call from the menu?
if (nargin == 1)
    options = 'Init';
else
    options = opts;
end

pfigure = figure('NumberTitle', 'off', 'Name', 'PoinCare','Tag', input.File, ...
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

ev = 'There are None';
if isfield(input, 'urevent') && isfield(input.urevent, 'code') && ~isempty({input.urevent.code})
    ev = unique({input.urevent.code});
end
%% simplest option....
options = uiextras.settingsdlg(...
    'Description', 'Set the parameters for PoinCare Plot',...
    'title' , 'PoinCare options',...
    'separator' , 'Plot Parameters:',...
    {'Delta' ;'delta' }, 1,...
    'separator' , 'Use Labels:',...
    {'By Label' ;'bylabel' }, {'yes', 'no'}, ...
    {'Use:'; 'label'}, ev);

if strcmp(options.bylabel, 'no')
    pax = axes(pfigure);

    ibix = input.IBIevent.ibis(1:end-options.delta);
    ibiy = input.IBIevent.ibis(1+options.delta:end);
    
    sd1 = round((sqrt(2)/2.0) * std(ibix-ibiy),3);
    sd2 = round( sqrt(2*std(ibix)^2) - (.5*std(ibix-ibiy)^2),3);
    
    plot(pax, ibix, ibiy);
    hold on
    plot (xlim, ylim, ':r', 'LineWidth', 2);
    axis square;
    title(input.id);
    text(min(xlim)+.01*diff(xlim), .99*max(ylim), ['SD1 = ' num2str(sd1) ' s']);
    text(min(xlim)+.01*diff(xlim), .98*max(ylim), ['SD2 = ' num2str(sd2) ' s']);
    
else
    
end
%% could make some sliders here that show part of the poincare.


function [pfigure, options] = PoinCare(input,opts)
%% Example Transformation simply calling EEGLAB function
% Create a poincare plot for the IBI series
% The ibis are plotted agains a time-delayed version of the same values. If
% the 'bylabel' option is used, the plot has different partitions for each
% value the label takes on.

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

ev = [];

if isfield(input, 'urevent') && isfield(input.urevent, 'code') && ~isempty({input.urevent.code})
    ev = unique({input.urevent.code});
end

%% simplest option....
if strcmp(options, 'Init')
options = uiextras.settingsdlg(...
    'Description', 'Set the parameters for PoinCare Plot',...
    'title' , 'PoinCare options',...
    'separator' , 'Plot Parameters:',...
    {'Delta' ;'delta' }, 1,...
    {'Origin included'; 'origin'}, {'yes', 'no'},...
    'separator' , 'Use Labels:',...
    {'By Label' ;'bylabel' }, {'no', 'yes'}, ...
    {'Use:'; 'label'}, ev);
end

pax = axes(pfigure);

if strcmp(options.bylabel, 'no')

    ibix = input.IBIevent.ibis(1:end-options.delta);
    ibiy = input.IBIevent.ibis(1+options.delta:end);
    
    sd1 = round((sqrt(2)/2.0) * std(ibix-ibiy),3);
    sd2 = round( sqrt(2*std(ibix)^2) - (.5*std(ibix-ibiy)^2),3);
    
    plot(pax, ibix, ibiy, '.r');
    if strcmp(options.origin, 'yes')
        a=xlim;
        xlim([0 a(2)])
        ylim([0 a(2)])
    end
    hold on
    plot (xlim, ylim, ':b', 'LineWidth', 2);
    axis square;
    title(input.id);
    
    sd1text = text(min(xlim)+.01*diff(xlim), .99*max(ylim), ['SD1 = ' num2str(sd1) ' s'], 'Units', 'data');
    sd2text = text(min(xlim)+.01*diff(xlim), .97*max(ylim), ['SD2 = ' num2str(sd2) ' s'], 'Units', 'data');
    
    s1 = get(sd1text, 'Extent');
    s2 = get(sd2text, 'Extent');
    
    text(max(s1(1)+s1(3),s2(1)+s2(3)), .98*max(ylim), ['SD2/SD1 = ' num2str(sd2/sd1)], 'Units', 'data');
    
else
    
    ibix = input.IBIevent.ibis(1:end-options.delta);
    ibiy = input.IBIevent.ibis(1+options.delta:end);
    ibit = input.IBIevent.RTopTime(1:end-1-options.delta);
    
    events = input.urevent;
    idx = strcmp({events(:).code}, options.label);
    events = events(idx);
    types = unique({events.type}) 
    
    colors = zeros(length(ibix));
    
    
    sd1 = round((sqrt(2)/2.0) * std(ibix-ibiy),3);
    sd2 = round( sqrt(2*std(ibix)^2) - (.5*std(ibix-ibiy)^2),3);
    
    plot(pax, ibix, ibiy);
    hold on
    plot (xlim, ylim, ':r', 'LineWidth', 2);
    axis square;
    title(input.id);
    
    sd1text = text(min(xlim)+.01*diff(xlim), .99*max(ylim), ['SD1 = ' num2str(sd1) ' s'], 'Units', 'data');
    sd2text = text(min(xlim)+.01*diff(xlim), .98*max(ylim), ['SD2 = ' num2str(sd2) ' s'], 'Units', 'data');
    
    s1 = get(sd1text, 'Extent');
    s2 = get(sd2text, 'Extent');
    
    text(max(s1(1)+s1(3),s2(1)+s2(3)), .985*max(ylim), ['SD2/SD1 = ' num2str(sd2/sd1)], 'Units', 'data');
    
end
%% could make some sliders/buttons here (to the side?) that interact with the poincare.


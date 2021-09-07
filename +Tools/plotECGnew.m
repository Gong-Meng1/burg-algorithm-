function [ varargout ] = plotECG( varargin )
%% Parse Inputs

args = varargin;

iSig = 1; 
SIG = struct;

defaultXLabel = 'Time in s';
mm_default = 0.001;

if length(args)>=2 && isnumeric(args{1}) && isstruct(args{2}) && isfield(args{2}, 'data')
    % plotECG(X,Y)   
    SIG.X0 = double(args{1});
    SIG.Y0 = double(args{2}.data);
    args = args(3:end);
elseif length(args)>=1 && isnumeric(args{1})
    % plotECG(Y)
    defaultXLabel = '';
    SIG.Y0 = args{1};
    SIG.X0 = 1;
    args = args(2:end);
    mm_default = 0.001;
end

% Check X and Y and change to column-oriented data
if numel(SIG.X0)==1 % X = sample rate
    validateattributes(SIG.X0,{'double'},{'nonempty','real','finite','scalar','positive'     }, 'plotECG','scalar X',1)
else % X = timestamps
    validateattributes(SIG.X0,{'double'},{'nonempty','real','finite','vector','nondecreasing'}, 'plotECG','vector X',1)
end
    validateattributes(SIG.Y0,{'double'},{'nonempty','real','2d'}, 'plotECG','Y')

if size(SIG.X0,1)==1, SIG.X0=SIG.X0'; end % change to column vector 
if isrow(SIG.Y0) || ~isscalar(SIG.X0) && size(SIG.Y0,1)~=size(SIG.X0,1)
    SIG.Y0=SIG.Y0';  % each column must be one signal
end

assert(isscalar(SIG.X0) || size(SIG.Y0,1)==size(SIG.X0,1),'Y must have dimensions such that one of its dimensions equals length(X) if X is not a scalar')
assert(size(SIG.Y0,1)>1, 'Signal must have at least two samples')
assert(nnz(~isfinite(SIG.Y0))<numel(SIG.Y0),'Y completely consists of infinite values')
if nnz(~isfinite(SIG.Y0))>.5*numel(SIG.Y0), warning('Y contains %.2f %% infinite values\n',nnz(~isfinite(SIG.Y0))/numel(SIG.Y0)*100); end
assert(nargout<=2,'Maximum 2 (instead of %u) output arguments are possible',nargout)


if isscalar(SIG.X0)
    period = 1/SIG.X0;
else
    period = median(diff(SIG.X0),'omitnan');
end
assert(period>0,'The sampling period must be > 0')
if isscalar(SIG.X0)
    timeBoundary = [0, period*(size(SIG.Y0,1)-1)];
else
    xFinite = isfinite(SIG.X0);
    timeBoundary = [SIG.X0(find(xFinite,1,'first')),SIG.X0(find(xFinite,1,'last'))];
end
duration = diff(timeBoundary);
assert(duration>0,'The duration must be > 0')

lineSpec = '-';
if size(SIG.Y0,2)==1
    lineSpec = '-k'; 
end    
if length(args)>=1 && isLineSpec(args{1})
    lineSpec = args{1};
    args = args(2:end);
end

parser = inputParser;
parser.FunctionName = 'plotECG';

parser.addParameter('mmPerSec'           , mm_default  , @(x)validateattributes(x,{'double'},{'real','finite','positive','scalar'}))
parser.addParameter('secPerScreenWidth'  , 1           , @(x)validateattributes(x,{'double'},{'real','finite','positive','scalar'}))
parser.addParameter('ShowAxisTicks'      , 'on'        , @(x)any(validatestring(x,{'on','off'})))
parser.addParameter('AutoStackSignals'   , {}          , @(x)iscellstr(x) || isstring(x))
parser.addParameter('SecondXAxisFunction', 'none'      , @(x)validateattributes(x,{'char','function_handle'},{'vector','nonempty'}))
parser.addParameter('SecondXAxisLabel'   , ''          , @(x)validateattributes(x,{'char'},{})) 
parser.addParameter('YLimMode'           , 'dynamic'   , @(x)any(validatestring(x,{'dynamic','fixed'})))
parser.addParameter('AutoMarkers'        , '.'         , @(x)any(validatestring(x,{'+','o','*','.','x','square','diamond','v','^','>','<','pentagram','hexagram','none'})))
parser.addParameter('ColorOrder'         , []          , @(x)validateattributes(x,{'double'},{'real','finite','nonnegative', '<=',1, 'size',[NaN,3]}))
parser.addParameter('Parent'             , 0           , @(x)isscalar(x) && isgraphics(x) && x~=0)
parser.addParameter('Units'              , 'normalized', @(x)any(validatestring(x,{'pixels','normalized','inches','centimeters','points','characters'})))
parser.addParameter('Position'           , [0,0,1,1]   , @(x)validateattributes(x,{'double'},{'real','finite','nonnegative', 'size',[1 4]}))

parser.parse(args{:})

SIG.AutoStackSignals = parser.Results.AutoStackSignals;
if ~isempty(SIG.AutoStackSignals)
    nStr = numel(SIG.AutoStackSignals);
    nSig = size(SIG.Y0,2);
    assert(nStr==nSig, 'You specified %u Strings in ''AutoStackSignals'', but the number of signals in Y is %u.',nStr,nSig);
end
        

%% Add the GUI components

mmPerSec = [];
FontSize = 11;

secPerScreenWidth = [];
if ismember('secPerScreenWidth',parser.UsingDefaults)
    mmPerSec = parser.Results.mmPerSec;
else
    secPerScreenWidth = parser.Results.secPerScreenWidth;
end
mmPerSec_slider = mmPerSec;
% N = size(SIG.Y0,1); % number of data points
N = round(duration / period)+1; 
axWidth_cm = 30;
axWidth_px = 100;

% Layout constants
fontSize = 11;
units = 'centimeters';
space = 0.05;
sliderHeight = .35;
checkboxHeight = 1;
editWidth = 2;

% Add components, save handles in a struct
hs = struct;
if parser.Results.Parent==0
    % Create new figure
    % TODO make initial figure height dependent on number of filters; voltage scaling  
    hs.parent = figure('Units','normalized', 'OuterPosition',[0.3,0.53,0.65,0.45], 'HandleVisibility','Callback');
else
    hs.parent = parser.Results.Parent;
end

% Find parent figure
hs.fig = hs.parent;
while ~isempty(hs.fig) && ~strcmp('figure', get(hs.fig,'type'))
    hs.fig = get(hs.fig,'parent');
end

% Disable all interactive modes. 
% Only then the WindowScrollWheelFcn can be set. 
rotate3d(hs.fig,'off')
zoom(hs.fig,'off')
pan(hs.fig,'off')
% Now set custom WindowScrollWheelFcn
hs.fig.WindowScrollWheelFcn = @figScroll;

hs.panel = uipanel(... % This uipanel can be put into another GUI
    'Parent',hs.parent,...
    'Units',parser.Results.Units,...
    'Position',parser.Results.Position,...
    'BorderWidth',0,...
    'SizeChangedFcn',@resizegui,... 
    'Visible','off');

hs.ax2 = axes(... 
    'Parent',hs.panel,...
    'ActivePositionProperty','Position',...
    'XAxisLocation','top',...
    'YAxisLocation','right',...
    'YTickLabel',{''},...
    'Color','none');
if strcmp(parser.Results.SecondXAxisFunction,'none')
    set(hs.ax2,'Visible','off')
end

hs.ax = axes(...
    'Parent',hs.panel,...
    'TickLabelInterpreter','none',...
    'ActivePositionProperty','Position');
if ~isempty(parser.Results.ColorOrder)
    hs.ax.ColorOrder = parser.Results.ColorOrder;
    hs.ax.NextPlot = 'replacechildren';
end

   
d = -log(N/7);


    
%% Create chart line handle

click_info.x = [];
click_info.y = [];

%hs.line = plot(hs.ax,1,1:size(SIG.Y0,2),lineSpec,parser.Unmatched); % Unmatched name-value pairs as plot parameters 
hs.line = plot(hs.ax,1,1:size(SIG.Y0,2),lineSpec); % Safer: Don't allow unmatched name-value pairs. Plot can still be modified by handles. 

% Remove 10^x axes factor
hs.ax2.XAxis.Exponent = 0;
hs.ax2.XAxis.ExponentMode = 'manual';
hs.ax2.YAxis.Exponent = 0;
hs.ax2.YAxis.ExponentMode = 'manual';
hs.ax.XAxis.Exponent = 0;
hs.ax.XAxis.ExponentMode = 'manual';
hs.ax.YAxis.Exponent = 0;
hs.ax.YAxis.ExponentMode = 'manual';

if strcmpi(parser.Results.ShowAxisTicks,'on')
    hs.ax.XLabel.String = defaultXLabel;
    hs.ax.TickLength = [0.001,0.001];
    hs.ax2.TickLength = [0.001,0.001];
    hs.ax2.XLabel.String = parser.Results.SecondXAxisLabel;
    hs.ax.XMinorGrid = 'on';
    if isempty(parser.Results.AutoStackSignals)
        if (isfield(varargin{2}, 'YLabel') && ischar(varargin{2}.YLabel))
            hs.ax.YLabel.String = varargin{2}.YLabel;
        else
            hs.ax.YLabel.String = 'Voltage in mV';
        end
    else
        hs.ax.YLabel.String = 'Channel';
    end        
else
    set(hs.ax ,'XTick',[], 'YTick',[])
    set(hs.ax2,'XTick',[], 'YTick',[])
end

if ~isempty(SIG.AutoStackSignals) && strcmp(parser.Results.YLimMode,'fixed')
    % Stack signals horizontally. 
    [sigPosVec,sigAddVec] = auto_stack_nooverlap(SIG.Y0);
    hs.ax.YTick = flip(sigPosVec);
    hs.ax.YTickLabel = flip(SIG.AutoStackSignals(:));
    hs.ax.TickLabelInterpreter = 'none';
else
    sigPosVec = zeros(1,size(SIG.Y0,2));
    sigAddVec = zeros(1,size(SIG.Y0,2));
end

Y0pos = bsxfun(@plus,SIG.Y0,sigAddVec);
range = [min(Y0pos(:)),max(Y0pos(:))];
dlt = diff(range)/50;
range(1) = range(1)-dlt;
range(2) = range(2)+dlt;
if strcmp(parser.Results.YLimMode,'fixed') && nnz(isnan(range))==0 && range(2)>range(1)
    hs.ax .YLimMode = 'manual';
    hs.ax2.YLimMode = 'manual';
    hs.ax. YLim = range; 
    hs.ax2.YLim = range; 
end


% Make figure visible after adding components
%btnDown()
redraw(true);
try getframe(hs.fig); catch, end % update system queue
resizegui

if ~isempty(mmPerSec)
    numPoints = axWidth_cm*10/(mmPerSec*period);
else
    numPoints = secPerScreenWidth/period;
end
zoomValue = log(numPoints/N)/d;
zoomValue = max(zoomValue,0);
zoomValue = min(zoomValue,1);

resizegui
redraw(true)
hs.panel.Visible = 'on';




%% Updatefunctions
    function figScroll(~,callbackdata)
        scrollCount = callbackdata.VerticalScrollCount;
        val = hs.scroll.Value + scrollCount*hs.scroll.SliderStep(2);
        val = max(hs.scroll.Min,val);
        val = min(hs.scroll.Max,val);
        hs.scroll.Value = val;
        redraw(true);
    end

    function redraw(varargin)
        if ~ishandle(hs.line(1)) && length(varargin)>1
            % figure overplotted by normal plot()
            return
        end
        
        set(gcf,'Pointer','watch');        
        
        % zoomValue==0: numPoints=N
         zoomValue=1;
         numPoints=N/1000;
        
        % N * exp(d*x)
        %numPoints = N*exp(d*zoomValue);
        numPoints = round(numPoints);
        numPoints = max(numPoints,2);
        
        % scrollValue==0: startIndex=1;
        scrollValue=1;
        startIndex=1;
        %startIndex = (N-numPoints)*scrollValue+1; % m*x+b
        endIndex = startIndex+numPoints;
        
        if ~isscalar(SIG.X0)
            startTime = timeBoundary(1)+period*(startIndex-1);
            [~,startIndex] = min(abs(startTime-SIG.X0));
            endTime = timeBoundary(1)+period*(endIndex-1);
            [~,endIndex] = min(abs(endTime-SIG.X0));
        end
        
        startIndex = round(startIndex);
        endIndex = round(endIndex);
        startIndex = max(startIndex,1);
        endIndex = min(endIndex,N);
        
        % Maximum factor_max values per pixel, 
        % so very long signals don't hang Matlab
        factor = round(numPoints/max(1,axWidth_px));
        factor_max = 1000; % increase this if you want to find the "needle in the haystack" (single outlier sample) 
        if factor>factor_max
            spc = floor(factor/factor_max);
        else
            spc = 1;
        end
        ind = startIndex:spc:endIndex;
        %fprintf('spc: %f\n',spc)
        
        % Use original or filtered signal according to checkbox state
        if isfield(SIG,'filter') && SIG.filter.mainCheck.Value == SIG.filter.mainCheck.Max
            if isscalar(SIG.X), XData=1/SIG.X*(ind-1); else, XData=SIG.X(ind); end
            YData = SIG.Y(ind,:);
        else
            if isscalar(SIG.X0), XData=period*(ind-1); else, XData = SIG.X0(ind); end
            YData = SIG.Y0(ind,:);
        end
        
        if isscalar(SIG.X0)
            startTime = XData(1);
            endTime = XData(end);
        end
        
        % Don't show much more samples than pixels. 
        % Make sure that minimum and maximum data is shown anyway
        % (except if factor is > factor_max, for responsiveness)
        maxSamplesPerPixel = 2;
        if size(YData,1)/(axWidth_px*maxSamplesPerPixel) > 2
            factor = ceil(size(YData,1)/(max(1,axWidth_px)*maxSamplesPerPixel));
            remove = mod(size(YData,1),factor);
            XData = XData(1:(end-remove));
            YData = YData(1:(end-remove),:);
            XData = reshape(XData,factor,[]);
            XData = [min(XData,[],1);max(XData,[],1)];
            XData = XData(:)';
            YData = permute(YData,[3,1,2]);
            YData = reshape(YData,factor,[],size(YData,3));
            YData = [min(YData,[],1,'includenan');max(YData,[],1,'includenan')]; % preserves 'NaN' separations
            YData = [min(YData,[],1');max(YData,[],1)];
            YData = reshape(YData,[],size(YData,3));
        end
        
        % On the other hand, if there are much less samples than pixels, 
        % show additional dots
        factor = size(YData,1)/max(1,axWidth_px);
        if ~strcmp(parser.Results.AutoMarkers,'none')
            if factor<0.2
                set(hs.line, 'Marker',parser.Results.AutoMarkers);
            else
                set(hs.line, 'Marker','none');
            end
        end
        
 
        if ~isempty(SIG.AutoStackSignals) && ~strcmp(parser.Results.YLimMode,'fixed')
            % Stack signals horizontally dynamically
            [sigPosVec,sigAddVec] = auto_stack(YData);
            hs.ax.YTick = flip(sigPosVec);
            hs.ax.YTickLabel = flip(SIG.AutoStackSignals(:));
            hs.ax.TickLabelInterpreter = 'none';
        end
        YData = bsxfun(@plus,YData,sigAddVec);

 
        % hs.ax2 limits
        if ~strcmp(parser.Results.SecondXAxisFunction,'none')
            ax2Limits = [feval(parser.Results.SecondXAxisFunction,startTime), feval(parser.Results.SecondXAxisFunction,endTime)];
            if ax2Limits(1)<ax2Limits(2)
                set(hs.ax2,'XDir','normal')
            else
                ax2Limits = flip(ax2Limits);
                set(hs.ax2,'XDir','reverse')
            end
            set(hs.ax2,'XLim',ax2Limits)
        end

        set(hs.line,'XData',XData);
        for iLine = 1:size(YData,2)
            set(hs.line(iLine),'YData',YData(:,iLine));
        end
        set(hs.ax,'XLim',[startTime,endTime])
        minY = min(YData(:));
        maxY = max(YData(:));
        delta = (maxY-minY)/50;
        minY = minY-delta;
        maxY = maxY+delta;
        if nnz(sigPosVec)>1
            minY = min([minY;sigPosVec(:)]);
            maxY = max([maxY;sigPosVec(:)]);
        end
        
        if strcmp(parser.Results.YLimMode,'dynamic') && nnz(isnan([minY,maxY]))==0 && maxY>minY
            set(hs.ax2,'YLim',[minY,maxY])
            set(hs.ax,'YLim',[minY,maxY])
        end

        set(gcf,'Pointer','arrow');

    end



    function resizegui(varargin)
        
        panelUnits = hs.panel.Units;
        
        % Centimeter layout
        set(hs.panel ,'Units',units);
        set(hs.ax    ,'Units',units);
        set(hs.ax2   ,'Units',units);
        
        width = hs.panel.Position(3);
        height = hs.panel.Position(4);
        
        yPos = space;
        
         
        % Axis
        if strcmpi(parser.Results.ShowAxisTicks,'on')
            insets = get(hs.ax,'TightInset');
            if isequal(hs.ax2.Visible,'on')
                insets = insets + get(hs.ax2,'TightInset');
            end
        else
            insets = [0,0,0,0];
        end
        
        pos = [space,yPos,max(1,width-3*space),max(1,height-1.6*yPos)];
        pos = [pos(1)+insets(1), pos(2)+insets(2), pos(3)-insets(1)-insets(3), pos(4)-insets(2)-insets(4)];
        pos = [pos(1), pos(2), max(0,pos(3)), max(0,pos(4))];
        
        set(hs.ax, 'Units',units, 'Position',pos)
        set(hs.ax2, 'Units',units, 'Position',pos)
        set(hs.panel,'Units',panelUnits);
        
        
        % Update axWidth_cm and axWidth_px
        set(hs.ax,'Units','centimeters');
        axWidth_cm=get(hs.ax,'Position'); axWidth_cm=axWidth_cm(3); axWidth_cm=max(axWidth_cm,0);
        set(hs.ax,'Units','pixels');
        axWidth_px=get(hs.ax,'Position'); axWidth_px=round(axWidth_px(3)); axWidth_px=max(axWidth_px,0);
        
        % Change zooming such that mmPerSec stays the same
        if ~isempty(varargin) && ~isempty(mmPerSec) % do this only for calls by GUI, not during the initialization call
            numPoints = axWidth_cm*10/(mmPerSec_slider*period);
            zoomValue = log(numPoints/N)/d;
            zoomValue = max(zoomValue,0);
            zoomValue = min(zoomValue,1);
            redraw(true)
        end
    end

    function height = layoutFilter(~,~,width)
        yPos = space;
        % Layout the sliders and their text fields from bottom to top
        nCtrl = length(SIG.filter.slider);
        % Find maximum label width
        labelWidth = 1;
        for iCtrl = 1:nCtrl
            ext = SIG.filter.slider(iCtrl).text.Extent(3);
            if ext > labelWidth
                labelWidth = ext;
            end
        end
        for iCtrl = flip(1:nCtrl)
            xPos = space;
            % Text label
            pos = [xPos,yPos,labelWidth,sliderHeight];
            pos = [pos(1), pos(2), max(0,pos(3)), max(0,pos(4))];
            set(SIG.filter.slider(iCtrl).text, 'Units',units, 'Position',pos);
            xPos=pos(1)+pos(3)+space;
            % Edit box
            pos = [xPos,yPos,editWidth,sliderHeight];
            pos = [pos(1), pos(2), max(0,pos(3)), max(0,pos(4))];
            set(SIG.filter.slider(iCtrl).edit, 'Units',units, 'Position',pos);
            xPos=pos(1)+pos(3)+space;
            % Slider
            pos = [xPos,yPos,width-xPos-space,sliderHeight];
            pos = [pos(1), pos(2), max(0,pos(3)), max(0,pos(4))];
            set(SIG.filter.slider(iCtrl).slider, 'Units',units, 'Position',pos);
            % New line
            yPos=pos(2)+pos(4)+space;
        end
        % Layout the checkbox
        yPos = yPos-3*space;
        pos = [space,yPos,width-2*space,checkboxHeight];
        pos = [pos(1), pos(2), max(0,pos(3)), max(0,pos(4))];
        set(SIG.filter.mainCheck, 'Units',units, 'Position',pos);
        yPos = pos(2)+pos(4)+space;
        height = yPos+3*space;
    end

    function delete_plotECG(varargin)
        %fprintf('delete_plotECG\n')
        SIG = [];
        click_info = [];
        if isvalid(hs.fig)
            hs.fig.WindowScrollWheelFcn = '';
        end
    end
    
hs.ax.DeleteFcn    = @delete_plotECG;
hs.panel.DeleteFcn = @delete_plotECG;




%% Return output arguments

if nargout>=1
    varargout{1} = hs.line;
end
if nargout>=2
    varargout{2} = hs;
end


end











%% Helper Functions

function y = editToSlider(edit,slider)
y = str2double(get(edit,'String'));
if y<=0
    % negative value provided: use minimum possible value
    y = slider.Min;
    edit.String = num2str(y,4);
end
% Logarithmic Conversion
a = slider.Min;
b = slider.Max;
r = log(a/b)/(a-b);
p = a*exp(-log(a/b)*a/(a-b));
if isnan(y)
    % no valid number string typed: restore old value 
    y = p*exp(r*slider.Value);
    edit.String = num2str(y,4);
else
    % convert to logarithmic scale
    x = log(y/p)/r;
    if x<slider.Min
        slider.Value = slider.Min;
    elseif x>slider.Max
        slider.Value = slider.Max;
    else
        slider.Value = x;
    end
end
drawnow
end


function y = sliderToEdit(edit,slider)
x = slider.Value;
% convert to exponential scale
% y = p*exp(r*x), x:[a,b], y:[a,b]
a = slider.Min; 
b = slider.Max;
r = log(a/b)/(a-b);
p = a*exp(-log(a/b)*a/(a-b));
y = p*exp(r*x);
edit.String = num2str(y,4); 
%edit.String = sprintf('%0.3g',y); 
end


function ls = isLineSpec(str)
ls = ischar(str) && length(str)<=4;
allowed = '-:.+o*xsd^v><phrgbcmykw';
for pos = 1:length(str)
    ls = ls && any(str(pos)==allowed);
end
end


function str = func2str2(func)
if ischar(func)
    str = func;
else
    str = func2str(func);
end
end


function str = function_file(func)
if ischar(func)
    funH = str2func(func);
    funS = func;
else
    funH = func;
    funS = func2str(func);
end
S = functions(funH);
str = S.file;
if isempty(str)
    str = funS;
else 
    str = sprintf('%s()   %s',funS,str);
end
end


function [sigPosVec,sigAddVec] = auto_stack(YData)
% Stacks Signals Horizontally with little overlap
% Used after each scroll/zoom action for 'AutoStackSignals' 
% with 'YLimMode' set to 'dynamic'.
% You might want to adjust this for your specific needs. 

%YData = bsxfun(@minus,YData,YData(1,:));
signalMed = median(YData,1,'omitnan');
YData = bsxfun(@minus,YData,signalMed);
overlap = YData;
overlap = diff(overlap,1,2); % positive values are overlap
overlap(isnan(overlap)) = 0;
overlapS = sort(overlap,1,'descend');
index = max(1,round(size(overlapS,1)*.007));
signalSpacing = overlapS(index,:)*1.1;
stdd = std(YData,1,1);
stdd = min(stdd(1:end-1),stdd(2:end));
signalSpacing = max(signalSpacing, median(signalSpacing,'omitnan')*.5 );
signalSpacing = max(signalSpacing, stdd*4);
% Increas very small spacings
signalSpacing = max(signalSpacing, max(signalSpacing)./1000.*ones(size(signalSpacing)));
signalSpacing = max(eps,signalSpacing);
sigPosVec = -cumsum([0 signalSpacing]);
sigAddVec = sigPosVec-signalMed;
end


function [sigPosVec,sigAddVec] = auto_stack_nooverlap(YData)
% Stacks Signals Horizontally with strictly no overlap. 
% Used for 'AutoStackSignals' with 'YLimMode' set to 'fixed'.
% You might want to adjust this for your specific needs. 

signalMed = median(YData,1,'omitnan');
YData = bsxfun(@minus,YData,signalMed);
overlap = YData;
overlap = min(overlap(:,1:end-1),[],1) - max(overlap(:,2:end),[],1);
overlap(isnan(overlap)) = 0;
signalSpacing = -overlap*1.01;
% Increas very small spacings
signalSpacing = max(signalSpacing, max(signalSpacing)./1000.*ones(size(signalSpacing)));
signalSpacing = max(eps,signalSpacing);
sigPosVec = -cumsum([0 signalSpacing]);
sigAddVec = sigPosVec-signalMed;
% MMS:
sigAddVec = -((0:length(sigAddVec)-1))*mean(signalSpacing);
sigPosVec = sigAddVec;
end










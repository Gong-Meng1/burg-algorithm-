hs.scroll = uicontrol(...
    'Parent',hs.panel,...
    'Style','slider',...
    'Min',0,...
    'Value',0,...
    'Max',1,...
    'SliderStep',[1e-4,.07],... 
    'TooltipString','Scroll the signal',...
    'Interruptible','on',...
    'Callback',{@redraw,true});
    hListener = addlistener(hs.scroll,'ContinuousValueChange',@redraw); 
    setappdata(hs.scroll,'sliderListener',hListener);
    
hs.zoom = uicontrol(...
    'Parent',hs.panel,...
    'Style','slider',...
    'Min',0,...
    'Value',.5,...
    'Max',1,...
    'SliderStep',[1e-4,.07],...
    'TooltipString','Zoom the signal',...
    'Interruptible','on',...
    'Callback',{@redraw,true});
    hListener = addlistener(hs.zoom,'ContinuousValueChange',@redraw); 
    setappdata(hs.zoom,'sliderListener',hListener);
    
    function zoom_callback(varargin)
        redraw(varargin{:});
        mmPerSec_slider = (axWidth_cm*10)/(numPoints*period);
    end

d = -log(N/7);

hs.scale = uicontrol(...
    'Parent',hs.panel,...
    'Style','slider',...
    'Min',0.001,...
    'Value',1,...
    'Max',100,...
    'SliderStep',[1e-4,.07],... 
    'TooltipString','Scale the signal.',...
    'Interruptible','on',...
    'Callback',{@redraw,true});
    hListener = addlistener(hs.scale,'ContinuousValueChange',@redraw); 
    setappdata(hs.scale,'sliderListener',hListener);

        scaleValue = get(hs.scale,'Value');
        scrollValue = get(hs.scroll,'Value');
        zoomValue   = get(hs.zoom,'Value');

classdef bcursor
    % cursor: an moveable patch (event with duration)
    properties
        vline
        motionCallback
        upCallback
        Axes
    end
    
    methods
        function obj = bcursor( hAxes, pos, dur, mcallback, ucallback, varargin)
            % cursor Construct an instance of this class
            
            obj.motionCallback  = mcallback;    
            obj.upCallback      = ucallback;
            obj.Axes            = hAxes;
            obj.vline = xline(pos,  ...
                'ButtonDownFcn', @obj.buttondn, ...
                'Parent', hAxes, ...
                varargin{:} );
        end
        
        function buttondn(obj, h, events)
            ud = get(gcf,'UserData');            
            
            ud.vline = h;
            ud.downEvents = events;
            
            set(gcf,'UserData', ud, ...
                'WindowButtonMotionFcn',@obj.buttonmotion,...
                'WindowButtonUpFcn',@obj.buttonup);         
        end
        
        
        function buttonup(obj, h, events)             
            set(h,'WindowButtonMotionFcn','','WindowButtonUpFcn','')
            ud = get(h,'UserData');
            
            if ~isempty(obj.upCallback)
                feval(obj.upCallback, ud.vline, events)
            end
        end
        
        function buttonmotion(obj, h, events)
            ud = get(h,'UserData');
            np = get (gca, 'CurrentPoint');
            
            set(ud.hline,'Value',np(1));
            
            if ~isempty(obj.motionCallback)
                feval(obj.motionCallback, ud.vline, events)
            end
        end
    end
end

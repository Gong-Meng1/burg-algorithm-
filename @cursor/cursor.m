classdef cursor
    % cursor: an moveable verical line (event)
    properties
        hline
        motionCallback
        upCallback
    end
    
    methods
        function obj = cursor( hAxes, pos, mcallback, ucallback, varargin)
            % cursor Construct an instance of this class
                 
            obj.motionCallback = mcallback;    
            obj.upCallback = ucallback;
            
            obj.hline = xline(pos,  ...
                'ButtonDownFcn', @obj.buttondn, ...
                'Parent', hAxes, ...
                varargin{:} );
        end
        
        function buttondn(obj, h, events)
            ud = get(gcf,'UserData');            
            store = get([gcf gca],'Units');
            
            set([gcf gca],'Units','pixels');
            FigurePos = get(gcf,'Position');
            
            ud.AxesPos = get(gca,'Position') + [FigurePos(1:2) 0 0];
            
            ud.hline = h;
            ud.downEvents = events;
            
            set(gcf,'UserData', ud, ...
                'WindowButtonMotionFcn',@obj.buttonmotion,...
                'WindowButtonUpFcn',@obj.buttonup);
            
            set([gcf gca],{'Units'},store);
        end
        
        
        function buttonup(obj, h, events)             
            set(h,'WindowButtonMotionFcn','','WindowButtonUpFcn','')
            ud = get(h,'UserData');
            
            if ~isempty(obj.upCallback)
                feval(obj.upCallback, ud.hline, events)
            end
        end
        
        function buttonmotion(obj, h, events)
            
            ud = get(h,'UserData');
            np = get (gca, 'CurrentPoint');
            
            set(ud.hline,'Value',np(1));
            disp(np(1))
            if ~isempty(obj.motionCallback)
                feval(obj.motionCallback, ud.hline, events)
            end
        end
    end
end

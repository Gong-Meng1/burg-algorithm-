function [outputArg1,outputArg2] = addECGAnn(uFig,EEGStruct)
    hold on
    plot(EEGStruct.RTopTime,EEGStruct.RTopVal,'ro')
    ml = max(ylim);
    nd = (EEGStruct.RTopVal*0) + ml;
    plot(EEGStruct.RTopTime,nd,'rv','MarkerFaceColor','r')
    
    %% Plot the IBI value labels in between the top r-top markers:
    text( double(EEGStruct.RTopTime(1:end-1) + EEGStruct.RTopTime(2:end))/2, ...
        double(nd(1:end-1))/1.05,...
        int2str(EEGStruct.ibis(:)*1000),...
        'FontSize', 8, 'HorizontalAlignment', 'center');
    Child = get(gca, 'Children');
    set(Child, 'Clipping', 'on');
    hold off
end


function [outputArg1,outputArg2] = addECGAnn(this)
    if (this.Workspace.EEG.nbchan == 1)
       Tools.plotECG(this.Workspace.EEG.times, this.Workspace.EEG, 'b-',...
                                'ShowInformationList','none',...
                                'ShowAxisTicks','on',...
                                'mmPerSec', 25,...
                                'YLimMode', 'fixed',...
                                'ShowInformationList','none',...
                                'Parent',  this.Figures(end));
    else
               Tools.plotECG(this.Workspace.EEG.times, this.Workspace.EEG, 'b-',...
                                'ShowInformationList','none',...
                                'ShowAxisTicks','on',...
                                'mmPerSec', 25,...
                                'AutoStackSignals', {this.Workspace.EEG.chanlocs.labels},...
                                'YLimMode', 'fixed',...
                                'ShowInformationList','none',...
                                'Parent',  this.Figures(end));
    end
    uAxis = gca;
    
    hold on
    %% OLD WAY
%     ml = max(ylim);
%     nd = (this.Workspace.EEG.RTopVal*0) + ml;
%     plot(uAxis,this.Workspace.EEG.RTopTime,nd,'rv','MarkerFaceColor','r')
%     
%     %% Plot the IBI value labels in between the top r-top markers:
%     text( uAxis, double(this.Workspace.EEG.RTopTime(1:end-1) + this.Workspace.EEG.RTopTime(2:end))/2, ...
%         double(nd(1:end-1))/1.05,...
%         int2str(this.Workspace.EEG.ibis(:)*1000),...
%         'FontSize', 8, 'HorizontalAlignment', 'center');
%     
    %Child = get(gca, 'Children');
    %set(Child, 'Clipping', 'on');
    %% END OLD WAY
    %% cursor way
    ibis = [this.Workspace.EEG.ibis(:);NaN];
    for rt = 1:length(this.Workspace.EEG.RTopTime)
        this.Workspace.EEG.rt_annotation(rt) = cursor(uAxis, ...
            this.Workspace.EEG.RTopTime(rt), ...
            [],[],...
            'Color', [.8,.1,.1,.3],...
            'LineStyle', '-.', ...
            'Label', ibis(rt), ...
            'LabelVerticalAlignment', 'top', ...
            'LabelHorizontalAlignment', 'right');
    end
    hold off
    
end
function IBIClickedCallback(src,eventData)
   clickedRTopInd = find(src.YData == eventData.IntersectionPoint(2));
   
   src.Color = 'blue';
   s=eventData;
end
function IBIOverCallback(src,eventData)
   clickedRTopInd = find(src.YData == eventData.IntersectionPoint(2));
   
   src.Color = 'blue';
   s=eventData;
end

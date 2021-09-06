function addECGAnn(this)
if (this.Workspace.EEG.nbchan == 1)
    Tools.plotECG(this.Workspace.EEG.times, this.Workspace.EEG, 'b-',...
        'ShowAxisTicks','on',...
        'mmPerSec', 25,...
        'YLimMode', 'fixed',...
        'Parent',  this.Figures(end));
else
    Tools.plotECG(this.Workspace.EEG.times, this.Workspace.EEG, 'b-',...
        'ShowInformationList','none',...
        'ShowAxisTicks','on',...
        'mmPerSec', 25,...
        'AutoStackSignals', {this.Workspace.EEG.chanlocs.labels},...
        'YLimMode', 'fixed',...
        'Parent',  this.Figures(end));
end
uAxis = gca;
hold on
%% cursor way
ibis = [this.Workspace.EEG.ibis(:);NaN];
for rt = 1:length(this.Workspace.EEG.RTopTime)
    ibit = this.Workspace.EEG.RTopTime(rt);
    this.Workspace.EEG.rt_annotation(rt) = cursor(uAxis, ...
        ibit, ...
        @IBIMove,@IBIMoved,...
        'Color', [.8,.1,.1,.3],...
        'LineStyle', '-.', ...
        'Label', ibis(rt), ...
        'LabelVerticalAlignment', 'top', ...
        'LabelHorizontalAlignment', 'right',...
        'UserData', rt);
            % ,...

end

hold off

    function IBIMove(line, ~)
        ix = get(line, 'UserData');
        RTop =  get(line, 'Value');
        
        set(this.Workspace.EEG.rt_annotation(ix).vline, 'Label', ...
            round(this.Workspace.EEG.RTopTime(ix+1) - RTop,3));
    end

    function IBIMoved(line, ~)
        set(gcf,'Pointer','watch');
        index = get(line, 'UserData');
        
        this.Workspace.EEG.RTopTime(index) = get(line, 'Value');  % new RTop value after dragging
        [this.Workspace.EEG.RTopTime,nidx] = sort(this.Workspace.EEG.RTopTime);
        this.Workspace.EEG.ibis =  round(diff(this.Workspace.EEG.RTopTime),3);
        ibis = [this.Workspace.EEG.ibis(:);NaN];
        for nrt = max(1, index-5):min( length(this.Workspace.EEG.RTopTime), index+5)
            set(this.Workspace.EEG.rt_annotation(nrt).vline, 'Label', round(ibis(nidx(nrt)),3));
            set(this.Workspace.EEG.rt_annotation(nrt).vline, 'UserData', nidx(nrt));            
        end
        set(gcf,'Pointer','arrow');
    end
end
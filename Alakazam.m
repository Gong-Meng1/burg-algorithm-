classdef Alakazam < handle
    % Brainvision analyser like program created in MATLAB
    %
    % Based On:
    % "matlab.ui.internal.desktop.showcaseMPCDesigner()" Author(s): R. Chen
    % Copyright 2015 The MathWorks, Inc.
    % C:\Program Files\MatLAB\R2018b\toolbox\matlab\toolstrip\+matlab\+ui\+internal\+desktop
    
    % Author(s): M.Span, University of Groningen,
    % dept. Experimental Psychology
    
    properties (Transient = false)
        ToolGroup
        Figures
        FDropHandler
        Workspace
        originalLnF
    end
    
    methods
        
        function this = Alakazam(varargin)
            %[flist,plist] = matlab.codetools.requiredFilesAndProducts('Alakazam.m'); [flist'; {plist.Name}']
            
            % Al
            addpath(genpath('Transformations'), 'mlapptools', genpath('../Alakazam/functions'));
            %mlapptools.toggleWarnings('off');
            import javax.swing.UIManager;
            this.originalLnF = 'com.sun.java.swing.plaf.windows.WindowsLookAndFeel' ;
            %javax.swing.UIManager.getLookAndFeel;
            newLnF = 'com.jgoodies.looks.plastic.Plastic3DLookAndFeel';   %string
            javax.swing.UIManager.setLookAndFeel(newLnF);
            
            % create tool group
            this.ToolGroup = ToolGroup('Alakazam','AlakazamApp');
            
            addlistener(this.ToolGroup, 'GroupAction',@(src, event) closeCallback(this, event));
            % create plot (hg)
            this.Figures = gobjects(1,1);
            % create tab group (new mcos api)
            tabgroup = BuildTabGroupAlakazam(this);
            % add tab group to toolstrip (via tool group api)
            this.ToolGroup.addTabGroup(tabgroup);
            % select current tab (via tool group api)
            this.ToolGroup.SelectedTab = 'tabHome';
            % render app
            this.ToolGroup.setPosition(100,100,1080,720);
            this.ToolGroup.open;
            
            % left-to-right document layout
            MD = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            MD.setDocumentArrangement(this.ToolGroup.Name, MD.TILED, java.awt.Dimension(1,1));
            
            this.Workspace = WorkSpace(this);
            this.Workspace.open();
            % after this, the workspace Panel holds the DataTree
            this.ToolGroup.setDataBrowser(this.Workspace.Panel);
        end
        
        function delete(this)
            if ~isempty(this.ToolGroup) && isvalid(this.ToolGroup)
                delete(this.ToolGroup);
            end
            javax.swing.UIManager.setLookAndFeel(this.originalLnF);
            delete(this.Figures);
        end
        
        function dropTargetCallback(src,data)
            disp('Dropped');
        end
        
        function ActionOnTransformation(this, ~, ~, userdata)
            % this function is the callback for all transformations.
            try
                callfnction = char(userdata);
                lastdotpos = find(callfnction == '.', 1, 'last');
                id = callfnction(1:lastdotpos-1);
                functionCall= ['EEG=' id '(x.EEG);'];
                
                [a.EEG, used_params] = feval(id, this.Workspace.EEG);
                a.EEG.Call = functionCall;
                if (isstruct(used_params))
                    a.EEG.params = used_params;
                else
                    
                    a.EEG.params = struct( 'Param', used_params);
                end
                
                CurrentNode = this.Workspace.Tree.SelectedNodes.Name;
                % Build new FileID (Name) based on the name of the current
                % node, the used transformationID and a timestamp.
                Key = [id datestr(datetime('now'), 'yymmddHHMMSS')];
                a.EEG.File = strcat(this.Workspace.CacheDirectory, char(CurrentNode), Key, '.mat');
                a.EEG.id =  [char(CurrentNode) ' - ' id];
                
                NewNode=uiextras.jTree.TreeNode('Name',a.EEG.id,'Parent',this.Workspace.Tree.SelectedNodes, 'UserData',a.EEG.File);
                if strcmpi(a.EEG.DataType, 'TIMEDOMAIN')
                    setIcon(NewNode,this.Workspace.TimeSeriesIcon);
                elseif strcmpi(a.EEG.DataType, 'FREQUENCYDOMAIN')
                    setIcon(NewNode,this.Workspace.FrequenciesIcon);
                end
                NewNode.Parent.expand();
                this.Workspace.Tree.SelectedNodes = NewNode;
                
                
                a.EEG.data = a.EEG.data;
                EEG=a.EEG;
                save(a.EEG.File, 'EEG');
                this.Workspace.EEG=EEG;
                plotCurrent(this);
            catch ME
                %warndlg(ME.message, 'Error in transformation');
                throw (ME)
                %pause(1);
            end
        end
        
        function plotCurrent(this)
            f = findobj('Type', 'Figure','Tag', this.Workspace.EEG.File);
            if ~isempty(f)
                % then just show it
                this.ToolGroup.showClient(get(f, 'Name'));
                return
            end
            
            % add plot as a new document
            this.Figures(end+1) = figure('NumberTitle', 'off', 'Name', this.Workspace.EEG.id,'Tag', this.Workspace.EEG.File, ...
                'Renderer', 'painters' , ...
                'Color' ,[.98 .98 .98], ...
                'PaperOrientation','landscape', ...
                'PaperPosition',[.05 .05 .9 .9], ...
                'PaperPositionMode', 'auto',...
                'PaperType', 'A0', ...
                'Units', 'normalized', ...
                'MenuBar', 'figure', ...
                'Toolbar', 'auto',...
                'DockControls','on', ...
                'Visible','off' ...
                );
            
            %% EPOCHED DATA PLOT
            if strcmp(this.Workspace.EEG.DataFormat, 'EPOCHED')
                tempEEG = this.Workspace.EEG;
                tempEEG.data = squeeze(tempEEG.data(:,:,1));
                if strcmp(this.Workspace.EEG.DataType, 'TIMEDOMAIN')
                    if (this.Workspace.EEG.nbchan > 1)
                        % Multichannel plot epoched
                    else
                        % Singlechannel plot epoched
                    end
                elseif strcmp(this.Workspace.EEG.DataType, 'FREQUENCYDOMAIN')
                    %% Fourier Plot (Multichannel and singlechannel) epoched
                    Tools.plotFourier(tempEEG, this.Figures(end));
                end
                this.ToolGroup.addFigure(this.Figures(end));
                this.Figures(end).Visible = 'on';
            else
                %% NOT EPOPCHED: CONTINUOUS
                if strcmp(this.Workspace.EEG.DataType, 'TIMEDOMAIN')
                    if (this.Workspace.EEG.nbchan > 1)
                        if (isfield(this.Workspace.EEG, 'ibis'))
%                             Tools.plotECG(this.Workspace.EEG.times, this.Workspace.EEG,...
%                                 'ShowInformationList','none',...
%                                 'ShowAxisTicks','on',...
%                                 'mmPerSec', 25,...
%                                 'YLimMode', 'fixed',...
%                                 'AutoStackSignals', {this.Workspace.EEG.chanlocs.labels},...
%                                 'ShowInformationList','none',...
%                                 'Parent',  this.Figures(end));
                            
                            Tools.addECGAnn(this);
                        else
                            % Multichannel plot, no ibis
                            Tools.plotECG(this.Workspace.EEG.times, this.Workspace.EEG, ...
                                'ShowInformationList','none',...
                                'ShowAxisTicks','on',...
                                'YLimMode', 'fixed', ...
                                'mmPerSec', 25,...
                                'AutoStackSignals', {this.Workspace.EEG.chanlocs.labels},...
                                'Parent',  this.Figures(end));
                        end
                     else
                        % Singlechannel Plot, IBIS calculated:
                        if (isfield(this.Workspace.EEG, 'ibis'))
%                             Tools.plotECG(this.Workspace.EEG.times, this.Workspace.EEG, 'b-',...
%                                 'ShowInformationList','none',...
%                                 'ShowAxisTicks','on',...
%                                 'mmPerSec', 25,...
%                                 'YLimMode', 'fixed',...
%                                 'ShowInformationList','none',...
%                                 'Parent',  this.Figures(end));
%                             
                            Tools.addECGAnn(this);
                        else
                            Tools.plotECG(this.Workspace.EEG.times, this.Workspace.EEG, 'b-',...
                                'mmPerSec', 25,...
                                'ShowInformationList','none',...
                                'ShowAxisTicks','on',...
                                'YLimMode', 'fixed',...
                                'ShowInformationList','none',...
                                'Parent',  this.Figures(end));
                        end
                    end
                    %% Plot the UREvents
                    hold on
                    limits = ylim();
                    for i = 1:length(this.Workspace.EEG.urevent)
                        xpos1 = this.Workspace.EEG.urevent(i).latency / this.Workspace.EEG.srate;
                        if (this.Workspace.EEG.urevent(i).duration > 1)
                            xpos2 = xpos1 + ((this.Workspace.EEG.urevent(i).duration / this.Workspace.EEG.srate)-1);
                            area([xpos1 xpos1 xpos2 xpos2], [limits(2) limits(1) limits(1) limits(2)], ...
                                'FaceColor', 'blue', 'FaceAlpha', .1, 'EdgeAlpha', .2, 'EdgeColor', 'blue', 'basevalue', limits(2));
                        else
                            line([xpos1 xpos1], limits, 'Color', [0,0,1,.4], 'LineStyle', '-');
                            text(xpos1, min(limits)+(.01*(abs(limits(2)-limits(1)))),  this.Workspace.EEG.urevent(i).type, ...
                                'FontSize', 8, ...
                                'HorizontalAlignment', 'center', ...
                                'Color', [0,0,1,.1]);
                        end
                    end
                    hold off
                    
                else
                    %Fourier Plot
                    Tools.plotFourier(this.Workspace.EEG, this.Figures(end));
                end
                this.ToolGroup.addFigure(this.Figures(end));
                this.Figures(end).Visible = 'on';
                set(this.Figures(end), 'Toolbar', 'figure');
                %[tb,btns] = axtoolbar(gca,{'export','brush','datacursor','restoreview'});
                
            end
        end
        
        function TreeDropNode(this, Tree, args)
            % Called when a Treenode is Dropped on another Treenode.
            % I prefer a switch of "copy" and "move" here.
            if ~isempty(args.Source.Parent.Parent) % if not a rootnode
                switch args.DropAction
                    case 'copy'
                        % No action modifier: actually moves.
                        set(args.Source,'Parent',args.Target)
                        %% Do the Evaluation of the commands here:
                        % dont forget to rename the target Node.
                        expand(args.Target)
                        expand(args.Source)
                    case 'move'
                        % control click: action modifier: actually copies.
                        %% Do the Evaluation of the commands here:
                        % dont forget to rename the target Node.
                        %NewSourceNode = copy(args.Source,args.Target);
                        this.Evaluate(args.Target.UserData, args.Source.UserData, args.Target);
                        
                        %expand(args.Target)
                        %expand(args.Source)
                        %expand(NewSourceNode)
                    otherwise
                        % Do nothing
                end
            end
        end
        
        function Evaluate(this, NewData, OldData, NewParentNode)
            % this should be done recursively......
            
            x = load(NewData, 'EEG');
            Old = load(OldData, 'EEG');
            
            idx1 = strfind(Old.EEG.Call, '=');
            idx2 = strfind(Old.EEG.Call, '(');
            id = Old.EEG.Call(idx1+1:idx2-1);
            
            [a.EEG, ~] = feval(id, x.EEG, Old.EEG.params);
            
            CurrentNode = x.EEG.id;
            Key = [id datestr(datetime('now'), 'yymmddHHMMSS')];
            a.EEG.File = strcat(this.Workspace.CacheDirectory, char(CurrentNode), Key, '.mat');
            a.EEG.id =  [char(CurrentNode) ' - ' id];
            a.EEG.Call = Old.EEG.Call;
            a.EEG.params = Old.EEG.params;
            % newNode = javaObjectEDT('AlakazamHelpers.EEGLABTreeNode', a.EEG.id, a.EEG.File);
            NewNode=uiextras.jTree.TreeNode('Name',a.EEG.id,'Parent',NewParentNode, 'UserData',a.EEG.File);
            if strcmpi(a.EEG.DataType, 'TIMEDOMAIN')
                setIcon(NewNode,this.Workspace.TimeSeriesIcon);
            elseif strcmpi(a.EEG.DataType, 'FREQUENCYDOMAIN')
                setIcon(NewNode,this.Workspace.FrequenciesIcon);
            end
            NewNode.Parent.expand();
            this.Workspace.Tree.SelectedNodes = NewNode;
            
            EEG=a.EEG;
            save(a.EEG.File, 'EEG');
            this.Workspace.EEG=EEG;
        end
        
        function MouseClicked(this,Tree,args)
            if (args.Button == 1) % left Button
                %if (args.Clicks == 2) % double click left button
                    % One way or the other: load and display the data.
                    id = Tree.SelectedNodes.Name;
                    matfilename = Tree.SelectedNodes.UserData;
                    if exist(matfilename, 'file') == 2
                        % if the file already exists:
                        a=load(matfilename, 'EEG');
                        a.EEG.id = string(id);
                        this.Workspace.EEG = a.EEG;
                    end
                    plotCurrent(this);
                %end
            end
            if (args.Button == 3) % right Button
                % show Tearoff Menu!
                disp('Tear!')
            end
        end
        
        
        function SelectionChanged(this,Tree,args) %#ok<*INUSD>
            disp('Alakazam::SelectionChanged Unimplemented')
        end
        
        function closeCallback(this, event)
            ET = event.EventData.EventType;
            if strcmp(ET, 'CLOSED')
                delete(this);
            end
        end
        
    end
end


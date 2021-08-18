function CreateTreeComponent(this)
% using a very slightly modified tree component, hence the copy in +uiextra
% the panel is the databrowsert
    
    this.Panel = javaObjectEDT('javax.swing.JPanel',javaObjectEDT('java.awt.BorderLayout'));   
    
    Root = figure('Visible', 'off');
    this.Tree = uiextras.jTree.Tree('DndEnabled', true, ...
        'Editable', true, ...
        'Parent', Root, ...
        'RootVisible', 'off', ...
        'SelectionChangeFcn', @(h,e) this.Parent.SelectionChanged(h,e), ...
        'MouseClickedCallback', @(h,e) this.Parent.MouseClicked(h,e), ...
        'NodeDroppedCallback',  @(h,e) this.Parent.TreeDropNode(h,e) ...
    );
    
    %%
    this.Dummy = javaObjectEDT('javax.swing.JPanel',javaObjectEDT('java.awt.GridLayout',12,12));
    for i = 1:(12*12)
        this.Dummy.add(javaObjectEDT('javax.swing.JButton', 'Center'));
    end 
%     
%     fighandle = figure('Visible', 'off');
%     this.Dummy = uicontrol(...
%         'style'   , 'pushbutton',...
%         'parent'  , fighandle,...
%         'string'  , 'OK',...
%         'position', [1,1,100,100]);

    %%
    
    this.javaObjects = this.Tree.getJavaObjects();
    
    this.Panel.add(this.Dummy, 'South')
    this.Panel.add(this.javaObjects.jScrollPane, 'Center');
    
    %% For no obvious reason I put the used icons within "this" class, the Workspace...
    
    this.RawFileIcon = fullfile(pwd,'Icons','bookicon.gif');
    this.TimeSeriesIcon = fullfile(pwd,'Icons','pagesicon.gif');
    this.FrequenciesIcon = fullfile(pwd,'Icons','frequencyIcon.gif');
end

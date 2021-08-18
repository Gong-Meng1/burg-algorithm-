function CreateTreeComponent(this)
% using a very slightly modified tree component, hence the copy in +uiextra
% the panel is the databrowsert
    Root = figure('Visible', 'off');
    this.Panel = javaObjectEDT('javax.swing.JPanel',javaObjectEDT('java.awt.BorderLayout'));    
    this.Tree = uiextras.jTree.Tree('DndEnabled', true, ...
        'Editable', true, ...
        'Parent', Root, ...
        'RootVisible', 'off', ...
        'SelectionChangeFcn', @(h,e) this.Parent.SelectionChanged(h,e), ...
        'MouseClickedCallback', @(h,e) this.Parent.MouseClicked(h,e), ...
        'NodeDroppedCallback',  @(h,e) this.Parent.TreeDropNode(h,e) ...
    );
    
    %%
    this.Dummy = javaObjectEDT('javax.swing.JButton', 'Button 1');

    %%
    
    this.javaObjects = this.Tree.getJavaObjects();
    this.Panel.add(this.Dummy, 'South')
    this.Panel.add(this.javaObjects.jScrollPane, 'North');
    
    %% For no obvious reason I put the used icons within "this" class, the Workspace...
    
    this.RawFileIcon = fullfile(pwd,'Icons','bookicon.gif');
    this.TimeSeriesIcon = fullfile(pwd,'Icons','pagesicon.gif');
    this.FrequenciesIcon = fullfile(pwd,'Icons','frequencyIcon.gif');
end

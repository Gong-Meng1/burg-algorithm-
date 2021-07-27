function open(this,~,~)
    allChildren = this.Tree.Root.Children;
    allChildren.delete;    
    %% Read the ROOT directory for datafiles;
    % We opted to let each of the typeloaders traverse into the tree.
    
    fileList = dir (strcat(this.RawDirectory, '*.vhdr'));
    for file = 1:length(fileList)
        this.loadBVAFile(this, fileList(file).name)
    end
    fileList = dir (strcat(this.RawDirectory, '*.XDF'));
    for file = 1:length(fileList)
        this.loadXDFFile(this, fileList(file).name)
    end
    fileList = dir (strcat(this.RawDirectory, '*.EDF'));
    for file = 1:length(fileList)       
        this.loadEDFFile(this, fileList(file).name)       
    end
    
end
function open(this,~,~)
    allChildren = this.Tree.Root.Children;
    allChildren.delete;    
    %% Read the ROOT directory for datafiles;
    % We opted to let each of the typeloaders traverse into the tree.
    if (~exist(this.CacheDirectory, 'dir'))
        mkdir(this.CacheDirectory);
    end
    if (~exist(this.RawDirectory, 'dir'))
        mkdir(this.RawDirectory);
    end
    if (~exist(this.ExportsDirectory, 'dir'))
        mkdir(this.ExportsDirectory);
    end

    fileList = dir (strcat(this.RawDirectory, '*.mat'));
    for file = 1:length(fileList)
        this.loadMATFile(this, fileList(file).name)
    end
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
        fileList = dir (strcat(this.RawDirectory, '*.BLE'));
    for file = 1:length(fileList)
        this.loadCortriumFile(this, fileList(file).name)
    end
end
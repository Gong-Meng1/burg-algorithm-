function loadXDFFile(this, WS, name)
%%
%
%
%
%
%%
x = fileparts( which('sopen') );
rmpath(x);
addpath(x,'-begin');

import matlab.ui.internal.toolstrip.*
[~,id,~] = fileparts(name);

% add the (semi)rootnode:

matfilename = strcat(WS.CacheDirectory, id, '.mat');
xdffilename = strcat(WS.RawDirectory, name);

if exist(matfilename, 'file') == 2
    % if the file already exists:
    matfile = dir(matfilename);
    xdffile = dir(xdffilename);
    if xdffile.datenum > matfile.datenum
    else
        % else read the rawfile
        a=load(strcat(WS.CacheDirectory, id, '.mat'), 'EEG');
        this.EEG = a.EEG;
        this.EEG.id = id;
        EEG.chanlocs(1).theta = 0;
        EEG.chanlocs(1).labels = 'ECG';
        EEG.chanlocs = EEG.chanlocs';
        this.EEG.File = matfilename;
    end
else
    % no matfile: create the matfile
    % addpath(fullfile(fileparts(mfilename('fullpath'))));

    stream = Tools.load_xdf(xdffilename);
    stream  = stream{1};
    EEG = Tools.eeg_emptyset;
    EEG.data = stream.time_series;
    [EEG.nbchan,EEG.pnts,EEG.trials] = size(EEG.data);
    [EEG.filepath,fname,fext] = fileparts(xdffilename); EEG.filename = [fname fext];
    if isfinite(stream.info.effective_srate) && stream.info.effective_srate>0
        EEG.srate = round(stream.info.effective_srate);
    else
        EEG.srate = round(str2num(stream.info.nominal_srate)); %#ok<ST2NM>
    end
    EEG.xmin = 0;
    EEG.xmax = (EEG.pnts-1)/EEG.srate;
    EEG.etc.desc = stream.info.desc;
    EEG.etc.info = rmfield(stream.info,'desc');

    
    %     EEG=Tools.pop_biosig(bdffilename);
    %     Tools.pop_writebva(EEG, [bdffilename(1:end-4) 'bva']);
    EEG.chanlocs(1).theta = 0;
    EEG.chanlocs(1).labels = 'ECG';
    EEG.chanlocs = EEG.chanlocs';

    EEG=eeg_checkset(EEG);
    EEG.DataType = 'TIMEDOMAIN';
    EEG.DataFormat = 'CONTINUOUS';
    EEG.id = id;
    EEG.times = stream.time_stamps - stream.time_stamps(1);
    EEG.File = matfilename;
    EEG.lss = Tools.EEG2labeledSignalSet(this.EEG);
    save(matfilename, 'EEG', '-v7.3');
    this.EEG=EEG;
end

%% Adds the loaded 'EEG' to the tree.
tn = uiextras.jTree.TreeNode('Name',id, 'UserData', matfilename, 'Parent', this.Tree.Root);
setIcon(tn,this.RawFileIcon);

%% Now recursively check for children of this file, and read them if they are there there.
this.treeTraverse(id, WS.CacheDirectory, tn);
end
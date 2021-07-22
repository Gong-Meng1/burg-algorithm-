function loadEDFFile(this, WS, name)
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

matfilename = strcat(WS.CacheDirectory, id, '.mat');
edffilename = strcat(WS.RawDirectory, name);

if exist(matfilename, 'file') == 2
    % if the file already exists:
    matfile = dir(matfilename);
    edffile = dir(edffilename);
    if edffile.datenum > matfile.datenum
    else
        % else read the rawfile
        a=load(strcat(WS.CacheDirectory, id, '.mat'), 'EEG');
        this.EEG = a.EEG;
        this.EEG.id = id;
    end
else
    % no matfile: create the matfile
    EEG = eeg_emptyset;
    tt = edfread(edffilename);
    data = [tt.(1){:}];
    EEG.data = data(1:end);
   
    [EEG.nbchan,EEG.pnts,EEG.trials] = size(EEG.data);
    [EEG.filepath,fname,fext] = fileparts(edffilename); EEG.filename = [fname fext];
    EEG.srate = 1000; 
    EEG.xmin = 0;
    EEG.xmax = (EEG.pnts-1)/EEG.srate;
    EEG.etc.desc = '';
    EEG.etc.info = 'desc';

    EEG.chanlocs(1).theta = 0;
    EEG.chanlocs(1).labels = 'ECG';
    EEG.chanlocs = EEG.chanlocs';

    EEG=eeg_checkset(EEG);
    EEG.DataType = 'TIMEDOMAIN';
    EEG.DataFormat = 'CONTINUOUS';
    EEG.id = id;
    EEG.times = (1:length(EEG.data))/EEG.srate;
    EEG.File = matfilename;
    EEG.lss = Tools.EEG2labeledSignalSet(this.EEG);
    save(matfilename, 'EEG', '-v7.3');
    this.EEG=EEG;
end

% add the (semi)rootnode:
tn = uiextras.jTree.TreeNode('Name',id, 'UserData', matfilename, 'Parent', this.Tree.Root);
setIcon(tn,this.RawFileIcon);

end
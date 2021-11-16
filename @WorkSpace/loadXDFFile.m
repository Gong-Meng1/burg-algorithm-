function loadXDFFile(this, WS, name)
%%
%
%
%
%
%%
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
        %EEG.chanlocs(1).theta = 0;
        %EEG.chanlocs(1).labels = 'ECG';
        %EEG.chanlocs = EEG.chanlocs';
        this.EEG.File = matfilename;
    end
else
    % no matfile: create the matfile
    mkdir ([tempdir 'tmpXDF'])
    data = dataSourceXDF( xdffilename , [tempdir 'tmpXDF']);
    nchan = size(data);
    EEG = data.export2eeglab(1:nchan(2), [], [], false);
    
    %rmdir([tempdir 'tmpXDF'], 's')

%     
%     stream = Tools.load_xdf(xdffilename);
%     stream  = stream{1};
%     EEG = Tools.eeg_emptyset;
%     EEG.data = stream.time_series;
     [EEG.nbchan,EEG.pnts,EEG.trials] = size(EEG.data);
     [EEG.filepath,fname,fext] = fileparts(xdffilename); EEG.filename = [fname fext];
     EEG.times = EEG.times/1000;
%     if isfinite(stream.info.effective_srate) && stream.info.effective_srate>0
%         EEG.srate = round(stream.info.effective_srate);
%     else
%         EEG.srate = round(str2num(stream.info.nominal_srate)); %#ok<ST2NM>
%     end
%     EEG.xmin = 0;
%     EEG.xmax = (EEG.pnts-1)/EEG.srate;
%     EEG.etc.desc = stream.info.desc;
%     EEG.etc.info = rmfield(stream.info,'desc');
% 
%     EEG.chanlocs(1).theta = 0;
%     EEG.chanlocs(1).labels = 'ECG';
%     EEG.chanlocs = EEG.chanlocs';

    EEG=Tools.eeg_checkset(EEG);
    EEG.DataType = 'TIMEDOMAIN';
    EEG.DataFormat = 'CONTINUOUS';
    EEG.id = id;
%    EEG.times = stream.time_stamps - stream.time_stamps(1);
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
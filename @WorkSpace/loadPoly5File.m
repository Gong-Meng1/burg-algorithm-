function loadPoly5File(this, WS, name)
%%
%   Loads the XDF file into an readeable format for Alakazam
%   Needs the EEGLAB to be in the path, and needs an installed Mobilab
%   plugin to be activated.....
%   
%
%%
[~,id,~] = fileparts(name);

% add the (semi)rootnode:

matfilename = strcat(WS.CacheDirectory, id, '.mat');
Poly5filename = strcat(WS.RawDirectory, name);

if exist(matfilename, 'file') == 2
    % if the file already exists:
    matfile = dir(matfilename);
    Poly5file = dir(Poly5filename);
    if Poly5file.datenum > matfile.datenum
    else
        % else read the rawfile
        a=load(strcat(WS.CacheDirectory, id, '.mat'), 'EEG');
        this.EEG = a.EEG;
        this.EEG.id = id;
        this.EEG.File = matfilename;
    end
else
    % no matfile: create the matfile
    [pathname,filename,extension] = fileparts(Poly5filename);
    %n = [pathname,'\',filename,extension]
    TMSIDATA = TMSi.Poly5.read([pathname,'\',filename,extension]);
    EEG = toEEGLab(TMSIDATA);
%     EEG        = Tools.eeg_emptyset();
% 
%     EEG.data = TMSIDATA.samples;
%     % DAMN YOU!!
%     %rmdir([tempdir 'tmpXDF'], 's')
% 
%     [EEG.nbchan,EEG.pnts,EEG.trials] = size(EEG.data);
%     [EEG.filepath,fname,fext] = fileparts(Poly5filename); EEG.filename = [fname fext];
%     EEG.srate = TMSIDATA.sample_rate;
%     EEG.times = (1:EEG.pnts) / EEG.srate;
%     EEG.xmax = EEG.times(end);
%     EEG.xmin = 1/EEG.srate;
%     EEG=Tools.eeg_checkset(EEG);
%     labs=[TMSIDATA.channels{:}]
%     EEG.chanlocs.labels = {labs.name};
    EEG.DataType = 'TIMEDOMAIN';
    EEG.DataFormat = 'CONTINUOUS';
    EEG.id = id;
    EEG.File = matfilename;
    % EEG.lss = Tools.EEG2labeledSignalSet(this.EEG);
    save(matfilename, 'EEG', '-v7.3');
    this.EEG=EEG;
end

%% Adds the loaded 'EEG' to the tree.
tn = uiextras.jTree.TreeNode('Name',id, 'UserData', matfilename, 'Parent', this.Tree.Root);
setIcon(tn,this.RawFileIcon);

%% Now recursively check for children of this file, and read them if they are there there.
this.treeTraverse(id, WS.CacheDirectory, tn);
end

function EEG = loadXDF(filename)
    td = tempdir;
    tnf = tempname(td);
    mkdir (tnf)
    data = dataSourceXDF( filename , tnf );
    sr=[]; ns=[]; 
    maxsr=-1;
    polar = [];
    for i = 1:length(data.item)
        sr(i) = data.item{i}.samplingRate; %#ok<AGROW> 
        ns(i) = size(data.item{i},1); %#ok<AGROW> 
        if strcmp(class(data.item{i}), 'markerStream') %#ok<STISA> 
            sr(i)=0; %#ok<AGROW> 
        end
        if sr(i) > maxsr 
            maxsr=sr(i);
            maxsrchan = i;
        end
        if sr(i) == 130
            %polarband
            polar = [polar i]; %#ok<AGROW> 
        end
    end

    ismarker = (sr==0);
    datachannels = find(~ismarker);

    datachannels = datachannels(datachannels ~= maxsrchan);
    datachannels = [datachannels maxsrchan];

    EEG = data.export2eeglab(datachannels, find(ismarker), [],false);

    if polar
        polarchannels = data.export2eeglab(polar, find(ismarker), [],false);
        for c = 1:size(polarchannels.data,1)
            polarchannels.data(c,isnan(polarchannels.data(c,:))) = mean(polarchannels.data(c,:), 'omitnan');
        end
    end

    for c = 1:size(EEG.data,1)
            EEG.data(c,isnan(EEG.data(c,:))) = mean(EEG.data(c,:), 'omitnan');
    end

    EEG.Polarchannels = polarchannels;
end
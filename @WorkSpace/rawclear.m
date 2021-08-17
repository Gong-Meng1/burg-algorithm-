function rawclear(this,~,~)
answer = questdlg('Are you sure you want to delete all your work?', ...
    'Clear Workspace?', ...
    'Yes, delete!','Sorry, what? No!','Sorry, what? No!');
if strcmp(answer, 'Yes, delete!')
    rmdir(this.CacheDirectory, 's');
    mkdir(this.CacheDirectory);
    %delete(strcat(this.CacheDirectory, '*.mat'));
    open(this);
end
end

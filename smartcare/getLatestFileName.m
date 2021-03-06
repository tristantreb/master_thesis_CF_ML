function [latestfname, filefound] = getLatestFileName(basedir, subfolder, fnamematchstring)

% getLatestFileName - returns the name of the most recent version of a file
% in a given directory matching a particular wildcard string match

filelisting = dir(fullfile(basedir, subfolder, sprintf('%s', fnamematchstring)));

if size(filelisting, 1) > 0
    % sort based on date in filename instead of date of last modification
    filetable = cell2table(struct2cell(filelisting)');
    filetable = sortrows(filetable, 'Var1', 'descend');
    latestfname = filetable.Var1{1};

%     %old
%     filetable = cell2table(struct2cell(filelisting)');
%     filetable.fname = filetable.Var1;
%     filetable.moddate = filetable.Var3;
%     filetable.moddate = datetime(filetable.moddate);
%     filetable = filetable(:, {'fname', 'moddate'});
%     filetable = sortrows(filetable, {'moddate'}, 'descend');
%     latestfname = filetable.fname{1};

    filefound = true;
    
else
    latestfname = '';
    filefound = false;
end

end


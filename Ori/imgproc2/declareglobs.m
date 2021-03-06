% These don't get saved
global globlist clearlist globstring preproc changed guihandle commandsuiH ...
    imagedata wallH activefig circH selH workingareaH hairH procstates ...
    old_cellgeom palettes old_procstate old_highlighting_handles batch_mode...
    batch_first_file never_saved active_imageH quickeditH clusters_data

% These get saved
globlist = {'filenames', 'celldata', 'cellgeom', 'circles', ...
	    'procparams', 'workingarea', 'summary', 'clusters_data', ...
	    'procstate', 'casename', 'file_path', 'highlighting_handles'};

%These are cleared before loading a new case file
clearlist = {'filenames', 'celldata', 'cellgeom', 'circles', ...
	    'workingarea', 'summary', ...
	    'procstate', 'casename', 'file_path', 'preproc', ...
        'changed', 'imagedata', ...
        'workingareaH', 'hairH', 'old_cellgeom', 'highlighting_handles'};
% clearlist = {'filenames', 'celldata', 'cellgeom', 'circles', ...
% 	    'procparams', 'workingarea', 'summary', ...
% 	    'caseversion', 'procstate', 'casename', 'file_path', 'preproc', ...
%         'changed', 'wallH', 'imagedata', 'circH', 'selH', ...
%         'workingareaH', 'hairH', 'old_cellgeom', 'highlighting_handles'};

    

procstates.HIGHLIGHT =1;
procstates.NONE =     2;
procstates.LOADED =   3;
procstates.CIRCLES =  4;
procstates.EDGES =    5;
procstates.CELLS =    6;
procstates.ANALYZED = 7;

globstring='';
for I=1:length(globlist)
  globstring=[globstring ' ' char(globlist(I))];
end

eval(['global' globstring])

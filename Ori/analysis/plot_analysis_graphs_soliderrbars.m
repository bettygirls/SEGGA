function figsH = plot_analysis_graphs_soliderrbars(action, vars, dir_names, groups, ...
    home_dir, save_dir, target_time_step, time_lim, figsH, text_argin,shift_hack,...
     unifydecimals,xtra_txt,ylim_input,solid_errs_bool,save_filetypes)
% action determins how to spread the different group-variable plots across
% figures. Accepted values are 'one_fig_per_group', 'one_fig_per_var', 
% 'one_fig', 'single_movies_var' and 'single_movies_group'.
% 
% vars is a struct array setting which variables to plot. 
% vars(i).var_name is the variable name of the i-th variable to plot. It is
% loaded from the file vars(i).file_name
% optional fields are:
% 
% vars(i).boundary_l and vars(i).boundary_r determins behavior of nan
% values beyond left and right boundaries, respectively. (when a movie time
% span is shorter than of other movies with which its data are averaged). 
% vars(i).boundary_l = 0 to set to zero, = 1 to set to the same value as
% the boundary value, = 2 to set to nan (and then ignored when averaging).
% 
% vars(i).title is the title / legend string
% vars(i).color = 1x3;
% vars(i).linewidth = linewidth (default == 3);
% vars(i).linespec = linespec string. If a color setting is specified in 
% the linespec, it's ignored. The groups.linespec overrides the
% vars.linespec when action == 'one_fig'.
% 
% vars(i).func FUNCTION to apply to the variable after loading it. Input 
% variables should be (x, t) where x is the loaded var and t is the time
% shift of the current movie. Should return a vector.
% vars(i).avg_func AVERAGING function to use with the variable. Will be 
% called one time point at a time. Should accept a vector and return a
% scalar.
% vars(i).post_func FUNCTION to apply to the variable after averging it.
% Mainly used for smoothening. Should accept a vector and return a vector.
% 
% vars(i).err_varname - get error bars from loaded data
% vars(i).err_title - error title
% vars(i).error = empty, or undefined -> std err
% vars(i).error = 0  -> no error bars
% vars(i).error = 1  -> std err
% vars(i).error = 2  -> std deviation
% vars(i).error = 3  -> "err_varname" specified error loaded from data
%  **** NOTE - "err_varname" must exist in [load vars(i).filename
%  vars(i).err_varname]
% 
% 
% The returned figsH is an array of handles of all plotted figures.
% 
% If the passed figsH is not empty it must be an array of figure handles. 
% With a nonempty figsH, instead of creating new figures, the plots will 
% be drawn in the existing figures whose handles are passed. The length of 
% figsH must be the number  of figure windows created when no figure 
% handles are passed: 
% length(vars)  if action == 'one_fig_per_var' or action == 'single_movies_var', 
% length(groups) if action == 'one_fig_per_group', 
% 1 if action == 'one_fig'.
% number of movies if action == 'single_movies_group',
if nargin < 16 || isempty(save_filetypes)
    save_filetypes = {'tif','fig','pdf'};
end

if nargin < 15 || isempty(solid_errs_bool)
    solid_errs_bool = false;
end

if nargin <14
    ylim_input = [];
end

if nargin <13 || isempty(xtra_txt)
    xtra_txt = '';
end


if nargin <12
    unifydecimals = false;
end

if nargin <11
    shift_hack = 0;
end

if nargin < 10
    text_argin = '';
end

if nargin < 9
    figsH = [];
end

if nargin < 8
    time_lim = [];
end

ori_dir = pwd;

if nargin < 4 || isempty(home_dir)
    home_dir = pwd;
end

if nargin < 5 || isempty(save_dir)
    display('need to input ''save dir''');
    return;
end

cd(home_dir);

% init vars and options from 'vars' struct array
for i = 1:length(vars)
    if ~isfield(vars, 'title') || isempty(vars(i).title)
        vars(i).title = vars(i).var_name;
    end
end
default_l_boundary_val = 2; %fill with nans
default_r_boundary_val = 2; %fill with nans
for i = 1:length(vars)
    if ~isfield(vars, 'boundary_l') || isempty(vars(i).boundary_l)
        vars(i).boundary_l = default_l_boundary_val;
    end
end
for i = 1:length(vars)
    if ~isfield(vars, 'boundary_r') || isempty(vars(i).boundary_r)
        vars(i).boundary_r = default_r_boundary_val;
    end
end
for i = 1:length(vars)
    if ~isfield(vars, 'color') || isempty(vars(i).color)
        vars(i).color = get_cluster_colors(i);
    end
end
for i = 1:length(vars)
    if ~isfield(vars, 'linespec') || isempty(vars(i).linespec)
        vars(i).linespec = '';
    end
end
for i = 1:length(vars) %Which function to use when averaging the variable
                       %(the default is the arithemtic mean)                   
    if ~isfield(vars, 'avg_func') || isempty(vars(i).avg_func)
        vars(i).avg_func = [];
    end
end

%%%%% init groups from 'groups' struct array
if nargin < 3 || isempty(groups)
    for i = 1:length(dir_names)
        groups(i).dirs = i;
        groups(i).label = dir_names{i};
        groups(i).color = get_cluster_colors(i);
        groups(i).linespec = '';
    end
else
    for i = 1:length(groups)
        if ~isfield(groups, 'label') || isempty(groups(i).label)
            groups(i).label = [dir_names{groups(i).dirs}];
        end
        if ~isfield(groups, 'color') || isempty(groups(i).color)
            groups(i).color = get_cluster_colors(i);
        end
        if ~isfield(groups, 'linespec') || isempty(groups(i).linespec)
            groups(i).linespec = '';
        end
    end
end

[vecs shifts_returned dir_ind time_step_ret single_movie_dirs special_errs vars] = read_vecs_from_files(...
    home_dir, dir_names, vars);


% % %  special parameter for shifts of corellations
halfshiftcors = -(51);
if shift_hack ==1
%     shifts_returned = ones(1,length(time_step_ret)).*halfshiftcors;
    shifts_returned = zeros(1,length(time_step_ret));
end


start_time = min(shifts_returned .* time_step_ret);
for i = 1:length(shifts_returned)
    l(i) = length(vecs{1, i});
end
end_time = max((shifts_returned + l) .* time_step_ret);

if nargin < 7 || isempty(target_time_step)
    target_time_step = min(time_step_ret);
end
global_timescale = (start_time:target_time_step:end_time)';
global_timescale = global_timescale / 60;

if strcmpi(action, 'single_movies_var') || strcmpi(action, 'single_movies_group')
    for i = 1:length(single_movie_dirs)
        groups(i).dirs = i;
        groups(i).label = single_movie_dirs{i};
        groups(i).color = get_cluster_colors(i);
        groups(i).linespec = '';
    end
    dir_ind = eye(length(single_movie_dirs)) > 0;
end

avg_vecs = average_and_sum_vecs(vecs, shifts_returned, ...
    groups, dir_ind, time_step_ret, global_timescale, vars, special_errs);



switch lower(action)
    case {'one_fig_per_group', 'single_movies_group'}
         figsH = plot_all_vars_overlayed(avg_vecs, global_timescale, ...
            groups, vars, figsH, time_lim, save_dir, text_argin,unifydecimals,...
            special_errs,xtra_txt,ylim_input,solid_errs_bool,save_filetypes);
    case {'one_fig_per_var', 'single_movies_var'}
        figsH = plot_by_group(avg_vecs, {vars.title}, groups, vars, ...
            global_timescale, figsH, time_lim, save_dir, text_argin,unifydecimals,...
            xtra_txt,ylim_input,solid_errs_bool,save_filetypes);
    case 'one_fig'
        figsH = plot_all_one_window(avg_vecs, global_timescale, ...
            groups, vars, figsH, time_lim, save_dir, text_argin,unifydecimals,...
            xtra_txt,ylim_input,solid_errs_bool,save_filetypes);
end

% save_avg_with_shifts(avg_vecs, var_name, ...
%     1 + min(shifts_returned), group_dest_dir, filename, group_timeaxes, ...
%     time_step_ret);

cd(ori_dir);

function [vecs shifts_returned dir_ind time_step_ret movie_dirs special_errs vars] = read_vecs_from_files(...
    home_dir, root_dir_names, vars)
dir_ind = false(length(root_dir_names));
cnt = 0;
special_errs = cell(length(vars),length(root_dir_names));
vecs = cell(length(vars),length(root_dir_names));

for i = 1:length(root_dir_names)
    cd(root_dir_names{i});
    sub_dir = pwd;
    dir_names = dir;
    for j = 3:length(dir_names)
        if dir_names(j).isdir
            cd(sub_dir);
            cd(dir_names(j).name)
            if ~isdir('seg')
                continue
            end
            cd('seg')
            if ~length(dir('shift_info.mat'))
                continue
            end
            if ~length(dir('timestep.mat'))
                disp(['timestep.mat not found in ' pwd])
                continue
            end
            
            load('shift_info');
            load('timestep');
            



            cnt = cnt + 1;
            movie_dirs{cnt} = dir_names(j).name;
            dir_ind(i, cnt) = true; %for cases when we skip directories
            shifts_returned(cnt) = shift_info;
            time_step_ret(cnt) = timestep;
            
            
            for k = 1:length(vars)
                d = load(vars(k).file_name, vars(k).var_name);
                if isfield(vars(k), 'func') && ~isempty(vars(k).func)
                    d.(vars(k).var_name) = vars(k).func(d.(vars(k).var_name), shift_info);
                end
                vecs{k, cnt} = d.(vars(k).var_name);
            end
            
            for k = 1:length(vars)
                if isfield(vars(k), 'err_varname') && ~isempty(vars(k).err_varname)
                    d = load(vars(k).file_name, vars(k).err_varname);
                    if isfield(vars(k), 'err_func') && ~isempty(vars(k).err_func)
                        d.(vars(k).err_varname) = vars(k).err_func(d.(vars(k).err_varname), shift_info);
                    end
                    special_errs{k, cnt} = d.(vars(k).err_varname);
                end
                
                if isfield(vars(k), 'exclude_data_func') && ~isempty(vars(k).exclude_data_func)
                    d = load(vars(k).file_name, vars(k).var_name);
                    if ~isempty(dir(vars(k).exclude_bool_file))
                        load(vars(k).exclude_bool_file);
                        if exclude_bool
                            display(['warning - erasing variable ',vars(k).title, 'as directed by erase_bool.mat']);
                            display(pwd);
                            % load it regular and apply any necessary funct
                            if isfield(vars(k), 'func') && ~isempty(vars(k).func)
                                d.(vars(k).var_name) = vars(k).func(d.(vars(k).var_name), shift_info);
                            end
                                %remove this data from the plot
                                d.(vars(k).var_name) = vars(k).exclude_data_func(d.(vars(k).var_name));
                                vecs{k, cnt} = d.(vars(k).var_name);
                        end
                    end
                end
            end
            

                if isfield(vars(k),'name_func') && ~isempty(vars(k).name_func)
                    d = load(vars(k).file_name, vars(k).var_name);
                    d = d.(vars(k).var_name);
                    vars(k).newtitle = [vars(k).title, '_',vars(k).name_func(d, vars(k).chan_ind)];
                end
            
%             d = load(filename, var_name);
%             if isvector(d.(var_name))
%                 vecs{1, cnt} = d.(var_name);
%             else
%                 for arr_cnt = 1:size(d.(var_name), 2)
%                     vecs{arr_cnt, cnt} = d.(var_name)(:, arr_cnt);
%                 end
%             end
%             starts_before_elon(cnt) = found_min; 
        end    
    end
    cd(home_dir);
end


function avg_vecs = average_and_sum_vecs(vecs, shifts, groups, dir_ind, ...
    time_steps, global_timescale, vars, special_errs)

grouped_dir_ind = false(length(groups), length(dir_ind(1, :)));
for j = 1:length(groups)
    for k = 1:length(groups(j).dirs)
        grouped_dir_ind(j, :) = grouped_dir_ind(j, :) | dir_ind(groups(j).dirs(k), :);
    end
end


for i = 1:size(vecs, 1)
    for j = 1:length(groups)
        
        time_steps_group = time_steps(grouped_dir_ind(j,:));
        
        [avg_vecs(i).group(j).avg avg_vecs(i).group(j).std_err ...
            avg_vecs(i).group(j).std_std avg_vecs(i).group(j).num] = ...
            avg_shifted_vecs_with_nans({vecs{i, grouped_dir_ind(j, :)}}, ...
            shifts(grouped_dir_ind(j, :)), vars(i).boundary_l, ...
            vars(i).boundary_r, time_steps_group, global_timescale, vars(i).avg_func);
        
    if exist('special_errs') && any(cellfun(@(x,t)any(x),{special_errs{i,:}}))
        [avg_vecs(i).group(j).spcl_err, ~, ...
            ~, ~] = ...
            avg_shifted_vecs_with_nans({special_errs{i, grouped_dir_ind(j, :)}}, ...
            shifts(grouped_dir_ind(j, :)), vars(i).boundary_l, ...
            vars(i).boundary_r, time_steps_group, global_timescale, vars(i).avg_func);
        
    end
        
%         DLF EDIT 2013July15 changing the timesteps to have only those for
%         the group being averaged
        if isfield(vars(i), 'post_func') && ~isempty(vars(i).post_func)
            new_mean = vars(i).post_func(avg_vecs(i).group(j).avg);
            if isfield(vars(i), 'post_func_err_linear') && vars(i).post_func_err_linear
                avg_vecs(i).group(j).std_err = avg_vecs(i).group(j).std_err .* ...
                    abs(new_mean ./ avg_vecs(i).group(j).avg);
                avg_vecs(i).group(j).std_std = avg_vecs(i).group(j).std_std .* ...
                    abs(new_mean ./ avg_vecs(i).group(j).avg);
            else
                avg_vecs(i).group(j).std_err = abs(vars(i).post_func...
                    (avg_vecs(i).group(j).avg + avg_vecs(i).group(j).std_err)...
                    - new_mean);
                avg_vecs(i).group(j).std_std = abs(vars(i).post_func...
                    (avg_vecs(i).group(j).avg + avg_vecs(i).group(j).std_std)...
                    - new_mean);
            end
            avg_vecs(i).group(j).avg = new_mean;
        end
    end    
end


function save_avg_with_shifts(avg_vecs, var_name, shift, group_dir, ...
    filename, group_timeaxes, time_steps, target_time_step)
for j = 1:length(group_dir)
    for i = 1:length(avg_vecs)
        if isempty(group_timeaxes{j})
            time_axis = (shift + (1:length(avg_vecs(i).group(j).avg)) - 1)/4;
        else
            time_axis = (shift + group_timeaxes{j})/4;
        end
        
        eval([var_name '_avg(:, i) = avg_vecs(i).group(j).avg;']);
        eval([var_name '_std_err(:, i) = avg_vecs(i).group(j).std_err;']);
    end
    dest_file = fullfile(group_dir{j}, filename);
    if length(dir(dest_file))
        save(dest_file, [var_name '_avg'], [var_name '_std_err'], 'time_axis', '-append')
    else
        save(dest_file, [var_name '_avg'], [var_name '_std_err'], 'time_axis')
    end
    eval(['clear ' var_name '_avg']);
    eval(['clear ' var_name '_std_err']);
end


function [avg_vecs factors y_shifts] = ...
    shift_and_scale_vecs(avg_vecs, factors, y_shifts)
for i = 2:length(avg_vecs)
    y_shifts(i) = min(avg_vecs(i).group(1).avg);
    avg_vecs(i).group(1).avg = avg_vecs(i).group(1).avg - y_shifts(i);
    factors(i) = max(avg_vecs(i).group(1).avg);
    avg_vecs(i).group(1).avg = avg_vecs(i).group(1).avg / factors(i);
    avg_vecs(i).group(1).std_err = avg_vecs(i).group(1).std_err / factors(i);
end


function figsH = plot_by_group(avg_vecs, titles, groups, vars, time_axis, ...
    figsH, time_lim, save_dir, text_argin, unifydecimals,xtra_txt,ylim_input,solid_errs_bool,save_filetypes)
% colors = [0 0 0; 1 0 0; 0 1 0; 0 0 1; 0.6 0 1; 0 1 1; 1 1 0; 0.5 0.5 0.5];
% if nargin < 5 || isempty(colors)
%     colors = [0 0 0; 0 0 1; 1 0 0 ; 0 1 1; 0.5 0.5 0.5];
% end
% if length(groups) > length(colors(:, 1))
%     colors = get_cluster_colors(1:length(groups));
%     colors(1, :) = 0;
% end
% err_colors = (colors + 2)/3;

% if nargin <6 || isempty(linespecs)
%     linespecs = cell(size(groups));
%     for i = 1:length(linespecs)
%         linespecs{i} = '';
%     end
% end

if isempty(figsH)
    use_existing_figs = false;
else
    use_existing_figs = true;
end

for i = 1:length(avg_vecs)
    if ~use_existing_figs
        figsH(i) = figure;
    else
        figure(figsH(i));
    end
    for j = length(groups):-1:1
        err_colors = (groups(j).color + 2)/3;
        if ~isfield(vars(i), 'error') || isempty(vars(i).error) || vars(i).error == 1
            err_data = avg_vecs(i).group(j).std_err;
        elseif vars(i).error == 0
            continue
        elseif vars(i).error == 2
            err_data = avg_vecs(i).group(j).std_std;
        end
        


%                 errorbar(time_axis, avg_vecs(i).group(j).avg, err_data, ...
%             'color', err_colors, 'linewidth', 0.5);
        
    keeps = ~isnan(avg_vecs(i).group(j).avg);
    time_axis_short = time_axis(keeps);
    tempyvals = avg_vecs(i).group(j).avg(keeps);
    err_data = err_data(keeps);
    linewidth = 2;
    if ~solid_errs_bool
                 [hLine, hPatch] = boundedline(time_axis_short,tempyvals,err_data,...
                    '-r',gca,... 
                    'transparency', 0.2,...
                    'orientation', 'vert',...
                    'cmap',groups(j).color,...
                    'linewidth',linewidth,...
                    'alpha');
    else
                [hLine, hPatch] = boundedline(time_axis_short,tempyvals,err_data,...
                    '-r',gca,... 
                    'orientation', 'vert',...
                    'cmap',groups(j).color,...
                    'linewidth',linewidth...
                    );
    end
    hold on
end

    h = [];
    for j = 1:length(groups)
        if ~isfield(vars(i), 'linewidth') || isempty(vars(i).linewidth)
            linewidth = 4;
        else
            linewidth = vars(i).linewidth;
        end
        


            h = [h plot(time_axis, avg_vecs(i).group(j).avg, groups(j).linespec, ...
                    'linewidth', linewidth,  'color', groups(j).color)];         
%         h = [h plot(time_axis, (avg_vecs(i).group(j).avg), groups(j).linespec, ...
%                     'linewidth', linewidth,  'color', groups(j).color)];
        hold on
    end
    
    
    if ~isempty(time_lim)
        xlim(time_lim)
    end

        text((max(get(gca,'xlim'))+min(get(gca,'xlim')))/2,...
    (max(get(gca,'ylim'))+min(get(gca,'ylim')))*4/5,text_argin);
    leghandle = legend(h, {groups.label}, 'location', 'NorthWest', 'interpreter', 'none','Color', 'none', 'Box', 'off');
    title(titles{i}, 'fontsize', 16, 'fontweight', 'bold')
    xlabel('Time [minutes]', 'fontsize', 14);

    set(gca, 'fontsize', 16, 'fontweight', 'bold', 'box', 'off');
%     pos = [153   225   504   867];
%     pos = [680   472   874   620];
    pos = [680   408   801   684];
    set(gcf, 'position', pos);
    
    if unifydecimals
        if any(mod(get(gca, 'YTick'),1)>0)
            if any(mod(get(gca, 'YTick'),0.1)>0)
            set(gca, 'YTickLabel', num2str(get(gca, 'YTick')', '%.2f'));
            else
            set(gca, 'YTickLabel', num2str(get(gca, 'YTick')', '%.1f'));
            end
        end
    end
    
    if ~verLessThan('matlab', '9.0') %% 2016a or more recent
        set(gcf,'PaperUnits','normalized');
        startPP = get(gcf,'PaperPosition');
%         newPP = [max(0,startPP(1)),max(0,startPP(2)),min(1,startPP(3)),min(1,startPP(4))];
        newPP = [max(0,startPP(1)),0.2,min(1,startPP(3)),0.6];
        set(gcf,'PaperPosition',newPP);
    end
%     set(gca,'TickDir','out');
    bname = [save_dir, titles{i}];
    
    if ~isdir(save_dir)
        display(['creatings save dir: ',save_dir]);
        mkdir(save_dir);
    end
    
    for s_i = 1:length(save_filetypes)
        saveas(gcf, [bname '.',save_filetypes{s_i}]);
    end
    set(gca, 'Layer','top');
	close(gcf);
%     print(gcf, [bname '.emf'], '-dmeta',   '-r0',    '-loose')


end


function figsH = plot_all_vars_overlayed(avg_vecs, time_axis, groups, vars, ...
    figsH, time_lim, save_dir, text_argin, unifydecimals, special_errs, xtra_txt,ylim_input,solid_errs_bool,save_filetypes)
% if nargin < 5 || isempty(colors)
% %     colors = [0 .81 0; 0 0 1; 0 1 1];
%     colors = [1 0 0; 0 1 0; 1 0 0 ; 0 1 0; 0.5 0.5 0.5];
% end
% if length(avg_vecs) > length(colors(:, 1))
%     colors = get_cluster_colors(1:length(avg_vecs));
%     colors(1, :) = 0;
% end
% err_colors = (colors + 3)/4;

% if nargin <6 || isempty(linespecs)
%     linespecs = cell(size(titles));
%     for i = 1:length(linespecs)
%         linespecs{i} = '';
%     end
% end
if isempty(figsH)
    use_existing_figs = false;
else
    use_existing_figs = true;
end

for j = 1:length(groups)
    if ~use_existing_figs
        figsH(j) = figure;
    else
        figure(figsH(j));
    end
    axesh = axes('Parent', figsH(j));


    h = [];
    legtxt = {};
    for i = length(avg_vecs):-1:1
        if ~isfield(vars(i), 'linewidth') || isempty(vars(i).linewidth)
            linewidth = 4;
        else
            linewidth = vars(i).linewidth;
        end
        
        if ~isfield(vars(i), 'error') || isempty(vars(i).error) || vars(i).error == 1
            err_data = avg_vecs(i).group(j).std_err;
        elseif vars(i).error == 0
            continue
        elseif vars(i).error == 2
            err_data = avg_vecs(i).group(j).std_std;
            
        elseif vars(i).error == 3 && ~isempty(special_errs)
            err_data = avg_vecs(i).group(j).spcl_err;
        end
        
        
        
        
        keeps = ~isnan(avg_vecs(i).group(j).avg);
        time_axis_short = time_axis(keeps);
        tempyvals = avg_vecs(i).group(j).avg(keeps);
        err_data = err_data(keeps);
        
        if ~solid_errs_bool
             [hLine, hPatch] = boundedline(time_axis_short,tempyvals,err_data,...
                '-r',axesh,... 
                'transparency', 0.2,...
                'orientation', 'vert',...
                'cmap',vars(i).color,...
                'linewidth',linewidth,...
                'alpha'...
                );
        else
            [hLine, hPatch] = boundedline(time_axis_short,tempyvals,err_data,...
                '-r',axesh,... 
                'orientation', 'vert',...
                'cmap',vars(i).color,...
                'linewidth',linewidth...
                );
        end%',alpha');
            h = [h hLine];
%            
%           also do the old plot technique because the 'boundedline' gets
%           spotty for some reason
            plot(time_axis, (avg_vecs(i).group(j).avg), ...
            vars(i).linespec, 'linewidth', linewidth+0.5,  'color', vars(i).color);
            
            if isfield(vars(i),'newtitle') && ~isempty(vars(i).newtitle)
                legtxt = [legtxt,vars(i).newtitle];
            else
                legtxt = [legtxt,vars(i).title];
            end
            hold on
            
            
%             if ~isempty(special_errs)
%         
%                 h = [h plot(time_axis, (avg_vecs(i).group(j).avg), ...
%                     vars(i).linespec, 'linewidth', linewidth,  'color', vars(i).color)];
%                 legtxt = [legtxt,vars(i).err_title];
%             end
                
    end
    if ~isempty(time_lim)
        xlim(time_lim)
    end

%     ylim([-0.7 0.4]);
    set(gca, 'fontsize', 14, 'fontweight', 'bold');
    xlabel('Time (min)', 'fontsize', 14,'fontweight', 'bold');
    leghandle = legend(h, legtxt, 'fontweight', 'bold','interpreter', 'none',...
        'Location','SouthWest','Color', 'none',  'Box', 'off');
    title(groups(j).label, 'interpreter', 'none')
    pos = [680   408   801   684];
    set(gcf, 'position', pos);

    plot([-25 30], [0 0], 'k');
        bname = [save_dir, groups(j).label,'-all-vars',];
    
    if unifydecimals
        if any(mod(get(gca, 'YTick'),1)>0)
            if any(mod(get(gca, 'YTick'),0.1)>0)
            set(gca, 'YTickLabel', num2str(get(gca, 'YTick')', '%.2f'));
            else
            set(gca, 'YTickLabel', num2str(get(gca, 'YTick')', '%.1f'));
            end
        end
    end
    if exist('xtra_txt')&~isempty(xtra_txt)
        bname = [bname,'-',xtra_txt];
    end
        
    if exist('ylim_input')&~isempty(ylim_input)
        set(gca,'ylim',ylim_input);
    end
    set(gca, 'Layer','top');
        
    if ~verLessThan('matlab', '9.0') %% 2016a or more recent
        set(gcf,'PaperUnits','normalized');
        startPP = get(gcf,'PaperPosition');
%         newPP = [max(0,startPP(1)),max(0,startPP(2)),min(1,startPP(3)),min(1,startPP(4))];
        newPP = [max(0,startPP(1)),0.2,min(1,startPP(3)),0.6];
        set(gcf,'PaperPosition',newPP);
    end
    
% %     set(gca,'TickDir','out');
%     saveas(gcf, [bname '.fig']);
%     saveas(gcf, [bname '.pdf']);
%      saveas(gcf, [bname '.tif']);
% %     ylim([-0.8 1])

     for s_i = 1:length(save_filetypes)
        saveas(gcf, [bname '.',save_filetypes{s_i}]);
    end
	close(gcf);




end

function figsH = plot_all_one_window(avg_vecs, time_axis, groups, vars, ...
    figsH, time_lim,save_dir, text_argin, unifydecimals,xtra_txt,ylim_input,solid_errs_bool,save_filetypes)

% colors = [1 0 0; 0 0 .75; 0 0 .75 ; 1 0 0; 0.5 0.5 0.5];
max_j = length(groups);
for j = 1:length(groups)
    for i = 1:length(avg_vecs)
        cnt = (i-1)*max_j + j;
        colors(cnt, :) = groups(j).color;
    end
end


if length(avg_vecs)*length(groups) > length(colors(:, 1))
    colors(length(colors(:, 1)):(length(avg_vecs)*length(groups)), :)...
        = get_cluster_colors(...
           length(colors(:, 1)):(length(avg_vecs)*length(groups)));
    colors(1, :) = 0;
end
err_colors = (colors + 3)/4;


if isempty(figsH)
    figsH = figure;
else
    figure(figsH(1));
end
h = [];
% var_ind = [];
titles = {};
for j = 1:length(groups)
    for i = 1:length(avg_vecs)
        cnt = (i-1)*max_j + j;
        if ~isfield(vars(i), 'error') || isempty(vars(i).error) || vars(i).error == 1
            err_data = avg_vecs(i).group(j).std_err;
        elseif vars(i).error == 0
            continue
        elseif vars(i).error == 2
            err_data = avg_vecs(i).group(j).std_std;
        end

%         errorbar(time_axis, (avg_vecs(i).group(j).avg), err_data, 'color', err_colors(cnt, :));
keeps = ~isnan(avg_vecs(i).group(j).avg);
time_axis_short = time_axis(keeps);
tempyvals = avg_vecs(i).group(j).avg(keeps);
err_data = err_data(keeps);
if ~solid_errs_bool
             [hLine, hPatch] = boundedline(time_axis_short,tempyvals,err_data,...
                '-r',axesh,... 
                'transparency', 0.2,...
                'orientation', 'vert',...
                'cmap',vars(i).color,...
                'linewidth',linewidth,...
                'alpha'...
                );
else
            [hLine, hPatch] = boundedline(time_axis_short,tempyvals,err_data,...
                '-r',axesh,... 
                'orientation', 'vert',...
                'cmap',vars(i).color,...
                'linewidth',linewidth...
                );
end
        hold on
    end

    
    for i = length(avg_vecs):-1:1
        cnt = (i-1)*max_j + j;
        if ~isfield(vars(i), 'linewidth') || isempty(vars(i).linewidth)
            linewidth = 4;
        else
            linewidth = vars(i).linewidth;
        end
        h = [h plot(time_axis, (avg_vecs(i).group(j).avg), ...
            vars(i).linespec, 'linewidth', linewidth,  'color', colors(cnt, :))];
%         var_ind = [var_ind i];
        titles{end+1} = [groups(j).label '    ' vars(i).title];
        hold on
    end
    if ~isempty(time_lim)
        xlim(time_lim)
    end

%     ylim([0 0.45]);
    set(gca, 'fontsize', 14, 'fontweight', 'bold');
     xlabel('Time (min)', 'fontsize', 14,'fontweight', 'bold');
    leghandle = legend(h(end:-1:1), titles, 'interpreter', 'none','fontweight', 'bold','Color', 'none', 'Box', 'off');
%     title(group_labels{j}, 'interpreter', 'none')
    pos = [680   408   801   684];
    set(gcf, 'position', pos);
%     ylabel('log_2(AP intensity/DV intensity)', 'fontsize', 14);
    plot([-25 30], [0 0], 'k');
    
    if unifydecimals
        if any(mod(get(gca, 'YTick'),1)>0)
            if any(mod(get(gca, 'YTick'),0.1)>0)
            set(gca, 'YTickLabel', num2str(get(gca, 'YTick')', '%.2f'));
            else
            set(gca, 'YTickLabel', num2str(get(gca, 'YTick')', '%.1f'));
            end
        end
    end
    set(gca, 'Layer','top');
    
    if ~verLessThan('matlab', '9.0') %% 2016a or more recent
        set(gcf,'PaperUnits','normalized');
        startPP = get(gcf,'PaperPosition');
%         newPP = [max(0,startPP(1)),max(0,startPP(2)),min(1,startPP(3)),min(1,startPP(4))];
        newPP = [max(0,startPP(1)),0.2,min(1,startPP(3)),0.6];
        set(gcf,'PaperPosition',newPP);
    end
    
    % 	remove_origin_ticks();
    ticksize = get(gca, 'TickLength');
    set(gca,'TickLength',ticksize.*2);
    set(gca,'linewidth',3);
    set(gca, 'Layer','top');
    
    for s_i = 1:length(save_filetypes)
        saveas(gcf, [bname '.',save_filetypes{s_i}]);
    end
	close(gcf);
    
% %     set(gca,'TickDir','out');
% 	bname = [save_dir, 'all-vars'];
%     saveas(gcf, [bname '.fig']);
%     saveas(gcf, [bname '.pdf']);
%     saveas(gcf, [bname '.tif']);
% %     ylim([-1 1])
end
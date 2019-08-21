function full_idx = get_full_idx(om,QP,which_field)
% by Baraa Mohandes
% This is largely based on the original MOST code: opt_model\display
% full_idx = get_full_idx(om,QP,which_field)
% Inputs:
% om: the opt_model. i.e: mdo.om                    This input is mandatory
% QP: the QP matrix in mdo. i.e. mdo.QP;            This input is optional
% which_field: if you don't want to produce the full list of indices
%              for 'var', 'lin' and 'qdc'
%              if you want to declare the third input which_field
%              but not the second input QP
%              then you should call: get_full_idx(om,[],which_field)
%              if "which_field" was NOT provided, all 3 fields 'var' 'lin' and 'qdc' will be analyzed
% 
% Outputs:
% full_idx is a structure of three fields: full_idx.var and full_idx.lin, full_idx.qdc
% each one of these fields is another structure (nested structure) containing two fields:
% full_list and full_order
% full_list contains an n x m cell array
% 
% a matpower object (OM or opt_model) aggregates the Pg variable for all machines in a system
% as one variable with om.var.idx.i1 reported as 1, and om.var.idx.iN as 1+ng
% if you want to extract the xmin, xmax and x0 for a certain machine, there is no built-in way
% to do that. You'd have to look at mdo.QP.xmin(om.var.idx.i1+ g)
% this manual approach has high potential for error. It gets nasty when you have multiple time periods
% multiple wind scenarios and multiple contingency scenarios.
% Therefore, get_full_idx generates a full list of indices, not only for 'var' but also for 'lin' and 'qdc'
% as stated above, 
% full_idx.var.full_list is an nvars x 4 cell array
% The first column is the number of this pack of variables (for {t,j,k}) combining (ng) variables
% This pack of variables is broken down to each one of its components (ng)
% The second column is the second index (n out of ng)
% The third column is the linear index of this variable (as if you were to use sub2ind(column1,column2). It is the row number of this variable in mdo.QP.xmin, xmax and x0
% The fourth column is an extended name of this variable
% 
% full_idx.lin.full_list is an om.lin.N x 5 cell array 
% Columns 1, 2, 3 and 5 carry the same meaning (or report the same information) explained for full_idx.var.full_list
% The 5th column, however, contains a list of all variables involved in this constraint
% 
%  
% full_idx.qdc.full_list is an om.qdc.N x 5 cell array
% Columns 1, 2, 3 and 5 carry the same meaning (or report the same information) explained for full_idx.var.full_list
% The 5th column, however, contains a list of all variables involved in this cost
% 
% 
% get_full_idx is a bit slow because of the number of for-loops inside
% I'd call it only once for large models.
% 
% 
% Example: use the tutorial in MOST manual under "GETTING STARTED" page 13
% 
% mpc = loadcase('ex_case3b'); 
% transmat = ex_transmat(12); 
% xgd = loadxgendata('ex_xgd_uc', mpc); 
% [iwind, mpc, xgd] = addwind('ex_wind_uc', mpc, xgd); 
% [iess, mpc, xgd, sd] = addstorage('ex_storage', mpc, xgd); 
% contab = ex_contab();
% profiles = getprofiles('ex_load_profile'); 
% profiles = getprofiles('ex_wind_profile', profiles, iwind); 
% mdi = loadmd(mpc, transmat, xgd, sd, contab, profiles); 
% mpopt = mpoption('verbose', 3);  
% mdo = most(mdi, mpopt); mdo1 = mdo;
% 
% 
% %Now call get_full_idx
% full_idx = get_full_idx(mdo.om,mdo.QP);
% 
% 
% 
% 
% Old explanation:
% The advantage of this function is getting also the ID of a constraint (or variable), within the full set of constraints (or variables)
% that is, out of om.lin.N (or om.var.N)
% this helps identifying a certain constraint (or variable) to modify it inside om.QP.A, om.QP.u, om.QP.l
% 
% first column in full_idx.(lin) is number of this constraint subset, out of om.lin.NS
% second column in full_idx.(lin) is number of this one constraint within its subset, out of om.lin.idx.N.(this subset)
% third column in full_idx.(lin) is row number of this one constraint in QP.A and QP.l and QP.u
% fourth column is indices of variables involved in this constraint
% fifth column in full_idx.(lin) is its name
% 
% first column in full_idx.(lin) is number of this constraint subset, out of om.lin.NS
% second column in full_idx.(lin) is number of this one constraint within its subset, out of om.lin.idx.N.(this subset)
% third column in full_idx.(lin) is row number of this one constraint in QP.A and QP.l and QP.u
% fourth column in full_idx.(lin) is its name
% 
% 
% get_full_idx also comes very handy when you want to extract information
% from the solution/output. For example, extract the values of dual variables
% and values of primary variables
% 

disp(['Inside ',mfilename]);
full_idx = struct('var',{cell(om.var.N,4)},'lin',{cell(om.lin.N,5)},'qdc',{cell(om.qdc.N,5)});
[var,lin,~,~,~,qdc] = om.get_idx();
vars_names = fieldnames(var.i1);
lins_names = fieldnames(lin.i1);
qdcs_names = fieldnames(qdc.i1);

if ~exist('which_field') || isempty(which_field)
which_field = [1 1 1];
else
which_field = [any(contains(which_field,'var','ignorecase',true)),any(contains(which_field,'lin','ignorecase',true)),any(contains(which_field,'qdc','ignorecase',true))];
end

%% var
tic;
if which_field(1)
big_cell = [{om.var.order.name}',{om.var.order.idx}'];
idx_str = cellfun(@(x) num2str([x{:}],'%d,'),big_cell(:,2),'un',0);
idx_str2 = strcat(big_cell(:,1),'(',idx_str);
% full_string = arrayfun(@(i) {repmat(i,max(1,om.var.idx.N.(om.var.order(i).name)(om.var.order(i).idx{:})),1),strcat(repmat(idx_str2(i),max(1,om.var.idx.N.(om.var.order(i).name)(om.var.order(i).idx{:})),1),num2str([1:om.var.idx.N.(om.var.order(i).name)(om.var.order(i).idx{:})]'),')')},[1:om.var.NS]','un',0);
% full_string = arrayfun(@(i) {repmat(i,(om.var.idx.N.(om.var.order(i).name)(om.var.order(i).idx{:})),1),[1:(om.var.idx.N.(om.var.order(i).name)(om.var.order(i).idx{:}))]',strcat(repmat(idx_str2(i),(om.var.idx.N.(om.var.order(i).name)(om.var.order(i).idx{:})),1),num2str([1:om.var.idx.N.(om.var.order(i).name)(om.var.order(i).idx{:})]'),')')},[1:om.var.NS]','un',0);
N = om.var.idx.N;
name = {om.var.order.name};
order_idx = {om.var.order.idx};
% full_string = arrayfun(@(i) { %arrayfun are always slower than for-loops
%                              repmat(i,(N.(name{i})(order_idx{i}{:})),1),...
%                              [1:(N.(name{i})(order_idx{i}{:}))]',...
%                              strcat(repmat(idx_str2(i),(N.(name{i})(order_idx{i}{:})),1),num2str([1:N.(name{i})(order_idx{i}{:})]'),')')
%                              },[1:om.var.NS]','un',0);
full_string0 = cell(om.var.NS,1);

parfor i = 1:om.var.NS
full_string0{i} =  {
                   repmat(i,(N.(name{i})(order_idx{i}{:})),1),...
                   [1:(N.(name{i})(order_idx{i}{:}))]',...
                   strcat(repmat(idx_str2(i),(N.(name{i})(order_idx{i}{:})),1),num2str([1:N.(name{i})(order_idx{i}{:})]'),')')
                   };
end

full_string = cat(1,full_string0{:});
full_string2 = {cat(1,full_string{:,1}),cat(1,full_string{:,2}), cat(1,full_string{:,3})};
full_string2{3} = erase(full_string2{3},' ');
full_string2{3} = strrep(full_string2{3},',)',',0)');

full_idx.var(:,1) = num2cell(full_string2{1});
full_idx.var(:,2) = num2cell(full_string2{2});
full_idx.var(:,3) = num2cell([1:om.var.N]');
full_idx.var(:,end) = full_string2{3};
end
clear full_string0 full_string full_string2 big_cell idx_str idx_str2 N name order_idx i;
toc;
%% lin
tic;
if which_field(2)
big_cell = [{om.lin.order.name}',{om.lin.order.idx}'];
idx_str = cellfun(@(x) num2str([x{:}],'%d,'),big_cell(:,2),'un',0);
idx_str2 = strcat(big_cell(:,1),'(',idx_str);
% full_string = arrayfun(@(i) {repmat(i,max(1,om.lin.idx.N.(om.lin.order(i).name)(om.lin.order(i).idx{:})),1),strcat(repmat(idx_str2(i),max(1,om.lin.idx.N.(om.lin.order(i).name)(om.lin.order(i).idx{:})),1),num2str([1:om.lin.idx.N.(om.lin.order(i).name)(om.lin.order(i).idx{:})]'),')')},[1:om.lin.NS]','un',0);
% full_string = arrayfun(@(i) {repmat(i,(om.lin.idx.N.(om.lin.order(i).name)(om.lin.order(i).idx{:})),1),[1:(om.lin.idx.N.(om.lin.order(i).name)(om.lin.order(i).idx{:}))]',strcat(repmat(idx_str2(i),(om.lin.idx.N.(om.lin.order(i).name)(om.lin.order(i).idx{:})),1),num2str([1:om.lin.idx.N.(om.lin.order(i).name)(om.lin.order(i).idx{:})]'),')')},[1:om.lin.NS]','un',0);
N = om.lin.idx.N;
name = {om.lin.order.name};
order_idx = {om.lin.order.idx};
% full_string = arrayfun(@(i) {
%                              repmat(i,(N.(name{i})(order_idx{i}{:})),1),...
%                              [1:(N.(name{i})(order_idx{i}{:}))]',...
%                              strcat(repmat(idx_str2(i),(N.(name{i})(order_idx{i}{:})),1),num2str([1:N.(name{i})(order_idx{i}{:})]'),')')
%                              },[1:om.lin.NS]','un',0);
full_string = cell(om.lin.NS,1);
tic;
parfor i = 1:om.lin.NS
full_string{i} =  {
                  repmat(i,(N.(name{i})(order_idx{i}{:})),1),...
                  [1:(N.(name{i})(order_idx{i}{:}))]',...
                  strcat(repmat(idx_str2(i),(N.(name{i})(order_idx{i}{:})),1),num2str([1:N.(name{i})(order_idx{i}{:})]'),')')
                  };
end
clear i;
toc;
full_string = cat(1,full_string{:});
full_string2 = {cat(1,full_string{:,1}),cat(1,full_string{:,2}), cat(1,full_string{:,3})};
full_string2{3} = erase(full_string2{3},' ');
full_string2{3} = strrep(full_string2{3},',)',',0)');

full_idx.lin(:,1) = num2cell(full_string2{1});
full_idx.lin(:,2) = num2cell(full_string2{2});
full_idx.lin(:,3) = num2cell([1:om.lin.N]');
full_idx.lin(:,end) = full_string2{3};
clear full_string full_string2;

lin_vars = cell(om.lin.N,1);
parfor i = 1:om.lin.N
lin_vars{i} = full_idx.var(find(QP.A(i,:)),end); %matlab will give you a warning that logical indexing might be better; ignore it; find is faster
end
clear i;

full_idx.lin(:,4) = lin_vars(:);
end
clear full_string full_string0 full_string2 big_cell idx_str idx_str2 N name order_idx i lin_vars a b;
toc;
%% qdc
tic;
if which_field(3)
big_cell = [{om.qdc.order.name}',{om.qdc.order.idx}'];
idx_str = cellfun(@(x) num2str([x{:}],'%d,'),big_cell(:,2),'un',0);
idx_str2 = strcat(big_cell(:,1),'(',idx_str);
% full_string = arrayfun(@(i) {repmat(i,max(1,om.qdc.idx.N.(om.qdc.order(i).name)(om.qdc.order(i).idx{:})),1),strcat(repmat(idx_str2(i),max(1,om.qdc.idx.N.(om.qdc.order(i).name)(om.qdc.order(i).idx{:})),1),num2str([1:om.qdc.idx.N.(om.qdc.order(i).name)(om.qdc.order(i).idx{:})]'),')')},[1:om.qdc.NS]','un',0);
% full_string = arrayfun(@(i) {repmat(i,(om.qdc.idx.N.(om.qdc.order(i).name)(om.qdc.order(i).idx{:})),1),[1:(om.qdc.idx.N.(om.qdc.order(i).name)(om.qdc.order(i).idx{:}))]',strcat(repmat(idx_str2(i),(om.qdc.idx.N.(om.qdc.order(i).name)(om.qdc.order(i).idx{:})),1),num2str([1:om.qdc.idx.N.(om.qdc.order(i).name)(om.qdc.order(i).idx{:})]'),')')},[1:om.qdc.NS]','un',0);
N = om.qdc.idx.N;
name = {om.qdc.order.name};
order_idx = {om.qdc.order.idx};
% full_string = arrayfun(@(i) {
%                              repmat(i,(N.(name{i})(order_idx{i}{:})),1),...
%                              [1:(N.(name{i})(order_idx{i}{:}))]',...
%                              strcat(repmat(idx_str2(i),(N.(name{i})(order_idx{i}{:})),1),num2str([1:N.(name{i})(order_idx{i}{:})]'),')')
%                              },[1:om.qdc.NS]','un',0);
full_string = cell(om.qdc.NS,1);
parfor i = 1:om.qdc.NS
full_string{i} = {
                 repmat(i,(N.(name{i})(order_idx{i}{:})),1),...
                 [1:(N.(name{i})(order_idx{i}{:}))]',...
                 strcat(repmat(idx_str2(i),(N.(name{i})(order_idx{i}{:})),1),num2str([1:N.(name{i})(order_idx{i}{:})]'),')')
                 };
end

full_string = cat(1,full_string{:});
full_string2 = {cat(1,full_string{:,1}),cat(1,full_string{:,2}), cat(1,full_string{:,3})};
full_string2{3} = erase(full_string2{3},' ');
full_string2{3} = strrep(full_string2{3},',)',',0)');

full_idx.qdc(:,1) = num2cell(full_string2{1});
full_idx.qdc(:,2) = num2cell(full_string2{2});
full_idx.qdc(:,3) = num2cell([1:om.qdc.N]');
full_idx.qdc(:,end) = full_string2{3};
end
clear full_string full_string0 full_string2 big_cell idx_str idx_str2 N name order_idx i;
toc;
end
function mpc = ex_case3b
%EX_CASE3B  Three bus example system for stochastic unit commitment.
%   Same as EX_CASE3A with the following changes:
%       - Non-zero PMIN values for generators
%       - Linear (vs quadratic) generator costs
%       - Includes some STARTUP and SHUTDOWN costs
%   Please see CASEFORMAT for details on the case file format.

%   MOST
%   Copyright (c) 2015-2016, Power Systems Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%
%   This file is part of MOST.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See https://github.com/MATPOWER/most for more info.

%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
1     3     0     0     0     0     1     1     0   135     1  1.05  0.95
2     2     0     0     0     0     1     1     0   135     1  1.05  0.95
3     2     0     0     0     0     1     1     0   135     1  1.05  0.95
];

%% generator data
%bus Pg    Qg   Qmax   Qmin Vg	mBase status Pmax	Pmin    Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
mpc.gen = [
1   125     0    25   -25     1   100     1   200    60     0     0     0     0     0     0     0   250   250     0     0
1   125     0    25   -25     1   100     1   200    65     0     0     0     0     0     0     0   250   250     0     0
2   200     0    50   -50     1   100     1   500    60     0     0     0     0     0     0     0   600   600     0     0
3  -450     0     0     0     1   100     1     0  -450     0     0     0     0     0     0     0   500   500     0     0
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
1      2  0.005   0.01      0    300    300    300      0      0      1   -360    360
1      3  0.005   0.01      0    240    240    240      0      0      1   -360    360
2      3  0.005   0.01      0    300    300    300      0      0      1   -360    360
];

%%-----  OPF Data  -----%%
%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
2      0      0      2     25      0
2    200    200      2     30      0
2   3000    600      2     40      0
2      0      0      2   1000      0
];

%%-----  Reserve Data  -----%%
%% reserve zones, element i, j is 1 if gen j is in zone i, 0 otherwise
mpc.reserves.zones = [
	1	1	1	0;
];
%this means that: define a zone of reserve whose members are generators 1,2,3 but not 4. 
% reserves.req below mentions how much total reserve is required in this zone
% reserves.qty below mentions the maximum reserve each generator can give (not infinite)

%% reserve requirements for each zone in MW
mpc.reserves.req   = 150;



%% This is my reserve definition, it overwrites the previous

% mpc.reserves.pweights = [
% 0 0 0 -0.25 %reserve must be larger than 0.25 of demand; negative -0.25 because load is negative
% ];
% to implement the reserve criterion that: total reserve >= max(Pg(:))
% then you're gonna need to define ng zones (i.e. size(reserves.zones,1) = ng
% and also define pweights with ng rows; that is: size(reserves.pweights,1) = ng
% let's say that igr is the indices of generators that will provide reserve. 
% if all generators provide reserve, then igr=1:ng

ng=size(mpc.gen,1);
which_load = isload(mpc.gen);
igr=sum(~which_load);
mpc.reserves.zones = ones(ng,igr);
mpc.reserves.zones(which_load,:)=[];
mpc.reserves.zones(:,which_load)=0;
mpc.reserves.pweights = eye(size(mpc.reserves.zones,1),ng);
mpc.reserves.req = zeros(size(mpc.reserves.zones,1),1);
mpc.reserves.zones = mpc.reserves.zones  - eye(size(mpc.reserves.zones ));

%% reserve costs in $/MW for each gen that belongs to at least 1 zone
%% (same order as gens, but skipping any gen that does not belong to any zone)
% mpc.reserves.cost  = [	5;	5;	21;	];
% mpc.reserves.cost  = [	5;	5;	16.25;	];
% mpc.reserves.cost  = [	0;	0;	11.25;	];
mpc.reserves.cost  = [	1;	3;	5;	];

%% OPTIONAL max reserve quantities for each gen that belongs to at least 1 zone
%% (same order as gens, but skipping any gen that does not belong to any zone)
mpc.reserves.qty   = [	100;	100;	200;	];

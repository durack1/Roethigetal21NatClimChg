% This file generates lists of CMIP6 files used in Figure generation
%
% Paul J. Durack 15th October 2021
%
% make_modList.m

% PJD 15 Oct 2021   - Started


% Cleanup workspace and command window
clear, clc, close all

% Load latest data
load /work/durack1/Shared/210128_PaperPlots_Rothigetal/210824T225103_210726_CMIP6.mat

% Load, define and clean variables
sos = sos_CMIP6_ssp585_2071_2101_modelNames;
sos = sos(~cellfun('isempty', sos));
mrro = mrro_CMIP6_ssp585_2071_2101_modelNames;
mrro = mrro(~cellfun('isempty', mrro));

% Concatenate variable
sosMrro = [sos; mrro];

% Remove dupes and sort
[~, idx] = unique(sosMrro);
sosMrroUnique = sosMrro(idx);
sosMrroUniqueSorted = sort(sosMrroUnique);
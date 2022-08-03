% This file generates two-panel figures displaying density changes for
% global basins as sourced from DW10
%
% Paul J. Durack 7th January 2011
%
% make_AR6_Fig1_CMIP6vsObs_soetal.m

%{
% PJD  1 Mar 2021   - Copied from /export/durack1/git/Roethigetal21NatClimChg/make_AR6_Fig3p23_CMIP6minusWOA18_thetaoAndso.m
%                     and updated contents
% PJD 20 Mar 2021   - Updated K test from >250 to >200 (205K recorded CanESM5, 209K GISS-E2-1-G)
% PJD 21 Mar 2021   - Added contour ranges for mrro; Complete run through without badLists
% PJD 21 Mar 2021   - Added test for missing files
% PJD 23 Mar 2021   - Updated badLists
% PJD 24 Mar 2021   - Update run through ssp460 (ind: 7) tos partial - tos exclusion list incomplete
% PJD 24 Mar 2021   - Deal with mrro log scaling
%                   https://www.mathworks.com/matlabcentral/answers/100066-how-do-i-create-a-logarithmic-scale-colormap-or-colorbar#answer_365558
% PJD 25 Mar 2021   - Update ssp534-over sos
% PJD 25 Mar 2021   - Updated to latest 210324 processed files (was 210226)
% PJD 25 Mar 2021   - Corrected variable typo's ([inVar,'_CdmsRegrid']) for new data
% PJD 25 Mar 2021   - Updated to latest 210325 processed files (was 210324, which had rogue files)
% PJD 27 Mar 2021   - Added conditional basin masking {'sos','tos'} only
% PJD 27 Mar 2021   - Revise and augment badLists from complete 210325 data (mrro,sos,tas,tos)
% PJD 27 Mar 2021   - Added badListFlag
% PJD 20 Apr 2021   - Generate draft Figure 1
% PJD 17 Aug 2021   - Update dataDate to 210726
% PJD 17 Aug 2021   - Update export -> home
% PJD 23 Aug 2021   - Update logic, remove clc calls
% PJD 23 Aug 2021   - Corrected sos, tos E3SM1-0, INM-CM4-8 .glb-l-gr. -> .glb-2d-gr.
% PJD 23 Aug 2021   - Updated strcmp logic for badList matching
% PJD 24 Aug 2021   - Toggle strcmp logic
% PJD 24 Aug 2021   - Updated mrro exclusion list
%                     historical: CanESM5, TaiESM1
%                     ssp119 GISS-E2-1-G
%                     ssp126 NorESM2-LM, GISS-E2-1-G
%                     ssp245 NorESM2-LM
%                     ssp370 NorESM2-LM
%                     ssp434 GISS-E2-1-G
%                     ssp460 GISS-E2-1-G
%                     ssp585 NorESM2-LM, GISS-E2-1-G
% PJD 26 Oct 2021   - Updated for ssp585 data reporting (now commented)
%}
% PJD  8 Mar 2022   - Updated for latest data
% PJD 10 Mar 2022   - Renamed make_AR6_Fig1_CMIP6vsObs_soetal.m -> make_RothigFigs.m
% PJD 19 Mar 2022   - Added to badLists:
%                   'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-H.r1-5i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
% PJD 29 Apr 2022   - Updated myMatEnv work path; new data 220427 (was 220228)
% PJD 30 Apr 2022   - Updated csirolib path
% PJD  1 Aug 2022   - Latest data update 220729; Added new functional addpath
% PJD  1 Aug 2022   - Update export_fig 3.15 -> 3.27
% PJD  2 Aug 2022   - Update exclusion lists
% PJD  3 Aug 2022   - Updated mrro exclusion list
%                   TO-DO:
%                   Check:
%                   ssp119 mrro,
%                   ssp126 mrro
%                   ssp245 mrro
%                   ssp370 mrro
%                   ssp434 mrro
%                   ssp460 mrro
%                   ssp534-over mrro
%                   ssp585 mrro
%                   Infill mrro - plot 2 maps, WOA025 landsea mask - upstream

% Cleanup workspace and command window
clear, clc, close all
% Initialise environment variables
[homeDir,~,dataDir,obsDir,~,aHostLongname] = myMatEnv(2);
outDir = os_path([homeDir,'210128_PaperPlots_Rothigetal/']);
dataDate = '220729' ; %'220427' ; %'220228' ; %'210726';
dateFormat = datestr(now,'yymmdd');
dateFormatLong = [datestr(now,'yymmdd'),'T',datestr(now,'HHMMSS')];
badListFlag = 0; % 1 = Test against badList before final run
addpath([dataDir,'toolbox-local/csirolib/'], '-BEGIN') % Add clmap, coast

% Setup plotting scales
mcont1 = 0:.25:10; % 0:1:30 map [min -6.5e-5, median 8.9e-7, max 7.3e-4]
mcont2 = mcont1; % colourbar labels
mcont3 = 0:.125:10; % colourbar colour increments
mscaler = 1e5;
ptcont1 = -2.5:2.5:30;
ptcont2 = ptcont1;
ptcont3 = -2.5:1.25:30;
ptscaler = 1;
scont1 = 30.25:0.5:39.75;
scont2 = 30:0.5:40;
scont3 = 30:0.25:40;
sscaler = 1;
%sscale = [1 1]; gscale = [0.3 0.5]; ptscale = [3 3];
fonts_c = 6; fonts_ax = 6; fonts_lab = 10; fonts = 7;

%% If running through entire script cleanup old figure files
[command] = matlab_mode;
disp(command)
if ~contains(command,'-batch ') % Test for interactive mode
    purge_all = input('* Are you sure you want to purge ALL current figure files? Y/N [Y]: ','s');
    if strcmpi(purge_all,'y')
        purge = 1;
    else
        purge = 0;
    end
else % If batch job purge files
    purge = 1;
end
if purge
    delete([outDir,dateFormat,'*_cmip*.eps']);
    delete([outDir,dateFormat,'*_cmip*.png']);
    delete([outDir,dateFormat,'_WOA18*.png']);
    delete([outDir,dateFormat,'_cmip*.png']);
    delete([outDir,dateFormat,'_CMIP6*.mat']);
end

%% Print time to console, for logging
disp(['TIME: ',datestr(now)])
setenv('USERCREDENTIALS','Paul J. Durack; pauldurack@llnl.gov (durack1); +1 925 422 5208')
disp(['CONTACT: ',getenv('USERCREDENTIALS')])
disp(['HOSTNAME: ',aHostLongname])
disp(['SOURCE DATA: ',fullfile(outDir,'ncs',dataDate)])
a = getGitInfo('/home/durack1/git/export_fig/') ;
disp([upper('export_fig hash: '),a.hash])
a = getGitInfo('/home/durack1/git/Roethigetal21NatClimChg/') ;
disp([upper('Roethigetal21NatClimChg hash: '),a.hash]); clear a

%% Load WOA18 data
%woaDir = os_path([obsDir,'WOA18/210201_woa/']); % decav 1955-2017 averaged decades
%infile = os_path([woaDir,'woa18_decav_t00_01.nc']);
woaDir = os_path([obsDir,'WOA18/210206_woa81B0/']); % 1981-2010 averaged climatology
infile = os_path([woaDir,'woa18_decav81B0_t00_01.nc']);
t_mean          = getnc(infile,'t_an');
t_lat           = getnc(infile,'lat');
t_lon           = getnc(infile,'lon');
t_depth         = getnc(infile,'depth'); clear infile
%infile = os_path([woaDir,'woa18_decav_s00_01.nc']);
infile = os_path([woaDir,'woa18_decav81B0_s00_01.nc']);
s_mean          = getnc(infile,'s_an'); clear infile

% Convert lat to 0 to 360 and flip grids
t_lon = t_lon+179.5;
t_mean = t_mean(:,:,[181:360,1:180]);
s_mean = s_mean(:,:,[181:360,1:180]);

% Mask marginal seas
infile = os_path([homeDir,'code/make_basins.mat']);
load(infile,'basins3_NaN_ones'); % lat/lon same as WOA18
%clf; pcolor(basins3_NaN_ones); shading flat
for x = 1:length(t_depth)
    t_mean(x,:,:) = squeeze(t_mean(x,:,:)).*basins3_NaN_ones;
    s_mean(x,:,:) = squeeze(s_mean(x,:,:)).*basins3_NaN_ones;
end; clear x infile

%{
close all
figure(1)
contourf(t_lon,t_lat,squeeze(t_mean(1,:,:)))
figure(2)
pcolor(t_lon,t_lat,basins3_NaN_ones); shading flat
%figure(3)
%contourf(t_lon,t_lat,squeeze(t_mean2(1,:,:)))
%}

% Convert in-situ temperature to potential temperature
t_depth_mat = repmat(t_depth,[1 length(t_lat)]);
pres = sw_pres(t_depth_mat,t_lat');
pres_mat = repmat(pres,[1 1 size(t_mean,3)]);
pt_mean = NaN(size(t_mean));
for x = 1:size(t_mean,3)
    pt_mean(:,:,x) = sw_ptmp(s_mean(:,:,x),t_mean(:,:,x),pres_mat(:,:,x),0);
end
clear t_mean pres pres_mat x

% Generate zonal means
pt_mean_zonal = nanmean(pt_mean,3);
pt_mean_zonal2 = mean(pt_mean,3,'omitnan');
s_mean_zonal = mean(s_mean,3,'omitnan');

% Plot 1 thetao and 2 so
for flip = 1:2
    switch flip
        case 1
            wmean = squeeze(pt_mean(1,:,:));
            wzmean = mean(pt_mean,3,'omitnan');
            cont1 = ptcont1;
            cont2 = ptcont2;
            cont3 = ptcont3;
            %varName = '_thetao_';
        case 2
            wmean = squeeze(s_mean(1,:,:));
            wzmean = mean(s_mean,3,'omitnan');
            cont1 = scont1;
            cont2 = scont2;
            cont3 = scont3;
            %varName = '_so_';
    end

    % WOA18
    close all, handle = figure('units','centimeters','visible','off','color','w'); set(0,'CurrentFigure',handle)
    ax1 = subplot(1,2,1);
    pcolor(t_lon,t_lat,wmean); shading flat; caxis([cont1(1) cont1(end)]); clmap(27); hold all
    contour(t_lon,t_lat,wmean,cont1,'color','k');
    ax2 = subplot(1,2,2);
    pcolor(t_lat,t_depth,wzmean); shading flat; caxis([cont1(1) cont1(end)]); clmap(27); axis ij; hold all
    contour(t_lat,t_depth,wzmean,cont1,'color','k');
    hh1 = colorbarf_nw('horiz',cont3,cont2);
    set(handle,'Position',[3 3 16 7]) % Full page width (175mm (17) width x 83mm (8) height) - Back to 16.5 x 6 for proportion
    set(ax1,'Position',[0.03 0.19 0.45 0.8]);
    set(ax2,'Position',[0.54 0.19 0.45 0.8]);
    set(hh1,'Position',[0.06 0.075 0.9 0.03],'fontsize',fonts_c);
    set(ax1,'Tickdir','out','fontsize',fonts_ax,'layer','top','box','on', ...
        'xlim',[0 360],'xtick',0:30:360,'xticklabel',{'0','30','60','90','120','150','180','210','240','270','300','330','360'},'xminort','on', ...
        'ylim',[-90 90],'ytick',-90:20:90,'yticklabel',{'-90','-70','-50','-30','-10','10','30','50','70','90'},'yminort','on');
    set(ax2,'Tickdir','out','fontsize',fonts_ax,'layer','top','box','on', ...
        'ylim',[0 5500],'ytick',0:500:5500,'yticklabel',{'0','500','1000','1500','2000','2500','3000','3500','4000','4500','5000','5500'},'yminort','on', ...
        'xlim',[-90 90],'xtick',-90:20:90,'xticklabel',{'-90','-70','-50','-30','-10','10','30','50','70','90'},'xminort','on');
    %export_fig([outDir,dateFormat,'_WOA18',varName,'mean'],'-png')
    %export_fig([outDir,dateFormat,'_WOA18',varName,'mean'],'-eps')
    clear ax1 ax2 hh1 wmean wzmean cont1 cont2 cont3 varName
end
disp('** WOA18 processing complete.. **')

%% Declare bad lists
%% mrro
badListCM6Mrro = {
    'CMIP6.CMIP.historical.AS-RCEC.TaiESM1.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20200624' ; % no ocean masking
    'CMIP6.CMIP.historical.AS-RCEC.TaiESM1.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20210416' ; % No ocean masking
    'CMIP6.CMIP.historical.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.CMIP.historical.CCCma.CanESM5.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r4i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r5i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r6i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r6i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r7i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r7i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r8i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r8i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r9i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r9i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r10i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r10i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r11i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r11i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r12i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r12i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r13i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r13i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r14i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r14i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r15i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r15i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r16i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r16i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r17i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r17i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r18i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r18i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r19i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r19i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r20i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r20i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r21i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r21i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r22i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r22i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r23i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r23i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r24i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r24i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r25i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r25i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r26i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r27i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r28i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r29i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r30i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r31i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r32i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r33i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r34i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r35i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r36i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r37i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r38i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r39i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r40i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5-CanOE.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.CMIP.historical.CCCma.CanESM5-CanOE.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5-CanOE.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CMCC.CMCC-CM2-SR5.r10i1p2f1.mon.mrro.land.glb-2d-gn.v20220401' ; % Invalid/deprecated data
    'CMIP6.CMIP.historical.CMCC.CMCC-CM2-SR5.r11i1p2f1.mon.mrro.land.glb-2d-gn.v20220401'
    'CMIP6.CMIP.historical.CMCC.CMCC-CM2-SR5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20200616'
    'CMIP6.CMIP.historical.CMCC.CMCC-CM2-SR5.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20211109'
    'CMIP6.CMIP.historical.CMCC.CMCC-CM2-SR5.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20211108'
    'CMIP6.CMIP.historical.CMCC.CMCC-CM2-SR5.r4i1p2f1.mon.mrro.land.glb-2d-gn.v20220112'
    'CMIP6.CMIP.historical.CMCC.CMCC-CM2-SR5.r5i1p2f1.mon.mrro.land.glb-2d-gn.v20220112'
    'CMIP6.CMIP.historical.CMCC.CMCC-CM2-SR5.r6i1p2f1.mon.mrro.land.glb-2d-gn.v20220112'
    'CMIP6.CMIP.historical.CMCC.CMCC-CM2-SR5.r7i1p2f1.mon.mrro.land.glb-2d-gn.v20220112'
    'CMIP6.CMIP.historical.CMCC.CMCC-CM2-SR5.r8i1p2f1.mon.mrro.land.glb-2d-gn.v20220316'
    'CMIP6.CMIP.historical.CMCC.CMCC-CM2-SR5.r9i1p2f1.mon.mrro.land.glb-2d-gn.v20220316'
    'CMIP6.CMIP.historical.EC-Earth-Consortium.EC-Earth3-AerChem.r4i1p1f1.mon.mrro.land.glb-2d-gr.v20201214' ; % no ocean masking
    'CMIP6.CMIP.historical.EC-Earth-Consortium.EC-Earth3-CC.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20210113' ; % no ocean masking
    'CMIP6.CMIP.historical.INM.INM-CM4-8.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190530' ; % no ocean masking
    'CMIP6.CMIP.historical.INM.INM-CM5-0.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190610' ; % no ocean masking
    'CMIP6.CMIP.historical.INM.INM-CM5-0.r2i1p1f1.mon.mrro.land.glb-2d-gr1.v20190704'
    'CMIP6.CMIP.historical.INM.INM-CM5-0.r3i1p1f1.mon.mrro.land.glb-2d-gr1.v20190703'
    'CMIP6.CMIP.historical.INM.INM-CM5-0.r4i1p1f1.mon.mrro.land.glb-2d-gr1.v20190704'
    'CMIP6.CMIP.historical.INM.INM-CM5-0.r5i1p1f1.mon.mrro.land.glb-2d-gr1.v20190705'
    'CMIP6.CMIP.historical.INM.INM-CM5-0.r6i1p1f1.mon.mrro.land.glb-2d-gr1.v20190709'
    'CMIP6.CMIP.historical.INM.INM-CM5-0.r7i1p1f1.mon.mrro.land.glb-2d-gr1.v20190709'
    'CMIP6.CMIP.historical.INM.INM-CM5-0.r8i1p1f1.mon.mrro.land.glb-2d-gr1.v20190709'
    'CMIP6.CMIP.historical.INM.INM-CM5-0.r9i1p1f1.mon.mrro.land.glb-2d-gr1.v20190710'
    'CMIP6.CMIP.historical.INM.INM-CM5-0.r10i1p1f1.mon.mrro.land.glb-2d-gr1.v20190712'
    'CMIP6.CMIP.historical.IPSL.IPSL-CM5A2-INCA.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20200729' ; % lats bound to 90
    'CMIP6.CMIP.historical.IPSL.IPSL-CM6A-LR.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20180803-blah' ; % no Antarctica
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20181015' ; % no ocean masking
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r1i1p1f3.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20190702'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r1i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20181015'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r2i1p1f3.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20190702'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r2i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20181015'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r3i1p1f3.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20190702'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r3i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20181015'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r4i1p1f3.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20190702'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r4i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20181015'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r5i1p1f3.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20190702'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r6i1p1f1.mon.mrro.land.glb-2d-gn.v20181015'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r6i1p1f2.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r6i1p3f1.mon.mrro.land.glb-2d-gn.v20190702'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r6i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r7i1p1f1.mon.mrro.land.glb-2d-gn.v20181015'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r7i1p1f2.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r7i1p3f1.mon.mrro.land.glb-2d-gn.v20190702'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r7i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r8i1p1f1.mon.mrro.land.glb-2d-gn.v20181015'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r8i1p1f2.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r8i1p3f1.mon.mrro.land.glb-2d-gn.v20190702'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r8i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r9i1p1f1.mon.mrro.land.glb-2d-gn.v20181015'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r9i1p1f2.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r9i1p3f1.mon.mrro.land.glb-2d-gn.v20190702'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r9i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r10i1p1f1.mon.mrro.land.glb-2d-gn.v20181015'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r10i1p1f2.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r10i1p3f1.mon.mrro.land.glb-2d-gn.v20190702'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r10i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r11i1p1f2.mon.mrro.land.glb-2d-gn.v20190903'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r101i1p1f1.mon.mrro.land.glb-2d-gn.v20190815'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G.r102i1p1f1.mon.mrro.land.glb-2d-gn.v20190815'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-G-CC.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190815'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190403' ; % no ocean masking
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-H.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20191003'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20191010'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r1i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-H.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20191003'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20191010'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r2i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-H.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20191003'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20191010'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r3i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-H.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20191003'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20191010'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r4i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-H.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20191003'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20191010'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r5i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r6i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r7i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r8i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r9i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r10i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-G.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20211020'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-G.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20211020'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-G.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20211020'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-G.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20211020'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-G.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-G.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20211020'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-G.r6i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-H.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-H.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-H.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-H.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-2-H.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20191120'
    'CMIP6.CMIP.historical.NCC.NorESM2-LM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190917' ; % no ocean masking
    'CMIP6.CMIP.historical.NCC.NorESM2-LM.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190920'
    'CMIP6.CMIP.historical.NCC.NorESM2-LM.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190920'
    'CMIP6.CMIP.historical.NCC.NorESM2-MM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191108' ; % no ocean masking
    'CMIP6.CMIP.historical.NCC.NorESM2-MM.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20200218'
    'CMIP6.CMIP.historical.NCC.NorESM2-MM.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20200702'
    'CMIP6.CMIP.historical.NOAA-GFDL.GFDL-CM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
    'CMIP6.CMIP.historical.NOAA-GFDL.GFDL-ESM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190726' ; % no ocean masking
    '' ; % split
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r4i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r5i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r6i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r6i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r7i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r7i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r8i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r8i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r9i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r9i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r10i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r10i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r11i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r11i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r12i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r12i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r13i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r13i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r14i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r14i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r15i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r15i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r16i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r16i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r17i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r17i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r18i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r18i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r19i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r19i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r20i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r20i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r21i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r21i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r22i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r22i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r23i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r23i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r24i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r24i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r25i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.CCCma.CanESM5.r25i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp119.IPSL.IPSL-CM6A-LR.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20190410-blah' ; % no Antarctica
    'CMIP6.ScenarioMIP.ssp119.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp119.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp119.NASA-GISS.GISS-E2-1-G.r1i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp119.NASA-GISS.GISS-E2-1-G.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp119.NASA-GISS.GISS-E2-1-G.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp119.NASA-GISS.GISS-E2-1-G.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp119.NASA-GISS.GISS-E2-1-G.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp119.NASA-GISS.GISS-E2-1-H.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20201215' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp119.NASA-GISS.GISS-E2-1-H.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20201215'
    'CMIP6.ScenarioMIP.ssp119.NOAA-GFDL.GFDL-ESM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
    '' ; % split
    'CMIP6.ScenarioMIP.ssp126.AS-RCEC.TaiESM1.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20201124' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r4i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r5i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r6i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r6i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r7i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r7i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r8i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r8i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r9i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r9i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r10i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r10i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r11i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r11i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r12i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r12i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r13i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r13i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r14i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r14i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r15i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r15i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r16i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r16i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r17i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r17i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r18i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r18i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r19i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r19i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r20i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r20i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r21i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r21i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r22i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r22i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r23i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r23i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r24i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r24i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r25i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5.r25i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5-CanOE.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5-CanOE.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CCCma.CanESM5-CanOE.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp126.CMCC.CMCC-CM2-SR5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20200717' ; % Invalid/deprecated data
    'CMIP6.ScenarioMIP.ssp126.INM.INM-CM4-8.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190603' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.INM.INM-CM5-0.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190619' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.IPSL.IPSL-CM5A2-INCA.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20201218' ; % lats bound to 90
    'CMIP6.ScenarioMIP.ssp126.IPSL.IPSL-CM6A-LR.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20190903-blah' ; % no Antarctica
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r1i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r2i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r3i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r4i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r5i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-H.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-H.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20201215'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-H.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-H.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20201215'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-H.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-H.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20201215'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-H.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-H.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20201215'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-H.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-H.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20201215'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-2-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-2-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-2-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-2-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-2-G.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp126.NCC.NorESM2-LM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20210319' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.NCC.NorESM2-MM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191108' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.NOAA-GFDL.GFDL-ESM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
    '' ; % split
    'CMIP6.ScenarioMIP.ssp245.AS-RCEC.TaiESM1.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20201124' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r4i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r5i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r6i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r6i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r7i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r7i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r8i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r8i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r9i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r9i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r10i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r10i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r11i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r11i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r12i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r12i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r13i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r13i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r14i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r14i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r15i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r15i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r16i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r16i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r17i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r17i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r18i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r18i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r19i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r19i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r20i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r20i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r21i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r21i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r22i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r22i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r23i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r23i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r24i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r24i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r25i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5.r25i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5-CanOE.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5-CanOE.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CCCma.CanESM5-CanOE.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp245.CMCC.CMCC-CM2-SR5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20200617' ; % Invalid/deprecated data
    'CMIP6.ScenarioMIP.ssp245.EC-Earth-Consortium.EC-Earth3-CC.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20210113' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp245.INM.INM-CM4-8.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190603' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp245.INM.INM-CM5-0.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190619' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp245.IPSL.IPSL-CM6A-LR.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20190119-blah' ; % no Antarctica
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r1i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r2i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r3i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r4i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r5i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r6i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r7i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r8i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r9i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-G.r10i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-H.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-H.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20201215'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-H.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-H.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20201215'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-H.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-H.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20201215'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-H.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-H.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20201215'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-H.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-1-H.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20201215'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-2-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20220115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-2-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20220115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-2-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20220115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-2-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20220115'
    'CMIP6.ScenarioMIP.ssp245.NASA-GISS.GISS-E2-2-G.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20220115'
    'CMIP6.ScenarioMIP.ssp245.NCC.NorESM2-LM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20210319' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp245.NCC.NorESM2-LM.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20210319'
    'CMIP6.ScenarioMIP.ssp245.NCC.NorESM2-LM.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20210319'
    'CMIP6.ScenarioMIP.ssp245.NCC.NorESM2-MM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191108'
    'CMIP6.ScenarioMIP.ssp245.NCC.NorESM2-MM.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20200702'
    'CMIP6.ScenarioMIP.ssp245.NOAA-GFDL.GFDL-CM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp245.NOAA-GFDL.GFDL-ESM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
    '' ; % split
    'CMIP6.ScenarioMIP.ssp370.AS-RCEC.TaiESM1.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20201014' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r4i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r5i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r6i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r6i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r7i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r7i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r8i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r8i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r9i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r9i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r10i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r10i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r11i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r11i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r12i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r12i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r13i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r13i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r14i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r14i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r15i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r15i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r16i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r16i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r17i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r17i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r18i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r18i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r19i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r19i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r20i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r20i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r21i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r21i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r22i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r22i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r23i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r23i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r24i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r24i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r25i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5.r25i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5-CanOE.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5-CanOE.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CCCma.CanESM5-CanOE.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp370.CMCC.CMCC-CM2-SR5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20200622' ; % Invalid/deprecated data
    'CMIP6.ScenarioMIP.ssp370.INM.INM-CM4-8.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190603' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp370.INM.INM-CM5-0.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190618' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp370.INM.INM-CM5-0.r2i1p1f1.mon.mrro.land.glb-2d-gr1.v20190712'
    'CMIP6.ScenarioMIP.ssp370.INM.INM-CM5-0.r3i1p1f1.mon.mrro.land.glb-2d-gr1.v20190715'
    'CMIP6.ScenarioMIP.ssp370.INM.INM-CM5-0.r4i1p1f1.mon.mrro.land.glb-2d-gr1.v20190723'
    'CMIP6.ScenarioMIP.ssp370.INM.INM-CM5-0.r5i1p1f1.mon.mrro.land.glb-2d-gr1.v20190722'
    'CMIP6.ScenarioMIP.ssp370.IPSL.IPSL-CM5A2-INCA.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20201218' ; % lats bound to 90
    'CMIP6.ScenarioMIP.ssp370.IPSL.IPSL-CM6A-LR.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20190119-blah' ; % no Antarctica
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r1i1p3f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r1i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r2i1p3f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r2i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r3i1p3f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r3i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r4i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r5i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r6i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r6i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r7i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r7i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r8i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r8i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r9i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r9i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r10i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r10i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-H.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-H.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20201215'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-H.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-H.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-H.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-H.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-2-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20211015' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-2-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-2-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-2-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-2-G.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp370.NCC.NorESM2-LM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20210319' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp370.NCC.NorESM2-MM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191108'
    'CMIP6.ScenarioMIP.ssp370.NOAA-GFDL.GFDL-ESM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
    '' ; % split
    'CMIP6.ScenarioMIP.ssp434.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp434.CCCma.CanESM5.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp434.CCCma.CanESM5.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp434.CCCma.CanESM5.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp434.CCCma.CanESM5.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp434.IPSL.IPSL-CM6A-LR.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20190506-blah' ; % no Antarctica
    'CMIP6.ScenarioMIP.ssp434.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp434.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp434.NASA-GISS.GISS-E2-1-G.r1i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp434.NASA-GISS.GISS-E2-1-G.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp434.NASA-GISS.GISS-E2-1-G.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp434.NASA-GISS.GISS-E2-1-G.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp434.NASA-GISS.GISS-E2-1-G.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp434.NASA-GISS.GISS-E2-1-H.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp434.NASA-GISS.GISS-E2-1-H.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    '' ; % split    
    'CMIP6.ScenarioMIP.ssp460.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp460.CCCma.CanESM5.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp460.CCCma.CanESM5.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp460.CCCma.CanESM5.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp460.CCCma.CanESM5.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp460.IPSL.IPSL-CM6A-LR.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20190506-blah' ; % no Antarctica
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r1i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-H.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-H.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    '' ; % split
    'CMIP6.ScenarioMIP.ssp534-over.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp534-over.CCCma.CanESM5.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp534-over.CCCma.CanESM5.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp534-over.CCCma.CanESM5.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp534-over.CCCma.CanESM5.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp534-over.IPSL.IPSL-CM6A-LR.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20190909-blah' ; % no Antarctica
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-G.r1i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-G.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-G.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-G.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-G.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-G.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-H.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-H.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-H.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-H.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-H.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-1-H.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-2-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20220315' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-2-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20220315'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-2-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20220315'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-2-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20220315'
    'CMIP6.ScenarioMIP.ssp534-over.NASA-GISS.GISS-E2-2-G.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20220315'
    'CMIP6.ScenarioMIP.ssp534-over.NCC.NorESM2-LM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20210811' ; % no ocean masking
    '' ; % split
    'CMIP6.ScenarioMIP.ssp585.AS-RCEC.TaiESM1.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20200901' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r4i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r5i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r6i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r6i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r7i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r7i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r8i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r8i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r9i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r9i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r10i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r10i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r11i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r11i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r12i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r12i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r13i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r13i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r14i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r14i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r15i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r15i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r16i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r16i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r17i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r17i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r18i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r18i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r19i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r19i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r20i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r20i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r21i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r21i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r22i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r22i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r23i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r23i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r24i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r24i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r25i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5.r25i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5-CanOE.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5-CanOE.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CCCma.CanESM5-CanOE.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp585.CMCC.CMCC-CM2-SR5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20200622' ; % Invalid/deprecated data
    'CMIP6.ScenarioMIP.ssp585.E3SM-Project.E3SM-1-1.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20201117' ; % Problems with Indonesian archipelago
    'CMIP6.ScenarioMIP.ssp585.E3SM-Project.E3SM-1-1-ECA.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20220325' ; % Problems with Indonesian archipelago
    'CMIP6.ScenarioMIP.ssp585.EC-Earth-Consortium.EC-Earth3-CC.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20210113' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp585.INM.INM-CM4-8.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190603' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp585.INM.INM-CM5-0.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190724' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp585.IPSL.IPSL-CM6A-LR.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20190903-blah' ; % no Antarctica
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking / f2 deprecated
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r1i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20200115' ; % not xml listed?
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r2i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20200115' ; % not xml listed?
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r3i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20200115' ; % not xml listed?
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r4i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20200115' ; % not xml listed?
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-G.r5i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-H.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-H.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-H.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-H.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-H.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-H.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-H.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-H.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-H.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-1-H.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-2-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20211015' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-2-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-2-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-2-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp585.NASA-GISS.GISS-E2-2-G.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20211015'
    'CMIP6.ScenarioMIP.ssp585.NCC.NorESM2-LM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20210319' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp585.NCC.NorESM2-MM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191108' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp585.NOAA-GFDL.GFDL-CM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp585.NOAA-GFDL.GFDL-ESM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
    };
%% sos
badListCM6Sos = {
    'CMIP6.CMIP.historical.CAS.FGOALS-f3-L.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191007' ; % rotated pole, thetao too
    'CMIP6.CMIP.historical.CAS.FGOALS-f3-L.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20191007'
    'CMIP6.CMIP.historical.CAS.FGOALS-f3-L.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20191008'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191107' ; % rotated pole, thetao too
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20191126'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20191012'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r4i1p1f1.mon.sos.ocean.glb-2d-gn.v20191012'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r5i1p1f1.mon.sos.ocean.glb-2d-gn.v20191013'
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r1i1p1f1.mon.sos.ocean.glb-2d-gr.v20190826' ; % mask/missing_value? duped as glb-2d <- glb-l-gr; thetao too
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r2i1p1f1.mon.sos.ocean.glb-2d-gr.v20190830'
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r3i1p1f1.mon.sos.ocean.glb-2d-gr.v20190827'
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r4i1p1f1.mon.sos.ocean.glb-2d-gr.v20190909'
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r5i1p1f1.mon.sos.ocean.glb-2d-gr.v20200429'
    'CMIP6.CMIP.historical.INM.INM-CM4-8.r1i1p1f1.mon.sos.ocean.glb-2d-gr1.v20190530-blah' ; % Values over Russia and Antarctica/grid (same for so/thetao); .glb.l -> 2d
    'CMIP6.CMIP.historical.NCAR.CESM2-FV2.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191120' ; % Masking Atlantic/Southern O/Pac
    'CMIP6.CMIP.historical.NCAR.CESM2-FV2.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20200226'
    'CMIP6.CMIP.historical.NCAR.CESM2-FV2.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20200226'
    'CMIP6.ScenarioMIP.ssp119.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20200527' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-f3-L.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-f3-L.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20200219'
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-f3-L.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20200219'
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191229' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-g3.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20191229'
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-g3.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20200101'
    'CMIP6.ScenarioMIP.ssp126.INM.INM-CM4-8.r1i1p1f1.mon.sos.ocean.glb-2d-gr1.v20190603-blah' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-f3-L.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-f3-L.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20200221'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-f3-L.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20200220'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20191229'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r4i1p1f1.mon.sos.ocean.glb-2d-gn.v20200101'
    'CMIP6.ScenarioMIP.ssp245.INM.INM-CM4-8.r1i1p1f1.mon.sos.ocean.glb-2d-gr1.v20190603-blah' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-f3-L.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-f3-L.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20200221'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-f3-L.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20200221'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r4i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r5i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.INM.INM-CM4-8.r1i1p1f1.mon.sos.ocean.glb-2d-gr1.v20190603-blah' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    'CMIP6.ScenarioMIP.ssp434.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20200526' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp460.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20200527' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp534-over.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20200526' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-f3-L.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-f3-L.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20200222'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-f3-L.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20200222'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191229'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20191230'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20200102'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r4i1p1f1.mon.sos.ocean.glb-2d-gn.v20191230'
    'CMIP6.ScenarioMIP.ssp585.INM.INM-CM4-8.r1i1p1f1.mon.sos.ocean.glb-2d-gr1.v20190603-blah' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    };
%% tas
badListCM6Tas = {
    'CMIP6.CMIP.historical.NIMS-KMA.KACE-1-0-G.r3i1p1f1.mon.tas.atmos.glb-z1-gr.v20190919' ; % Land surface >30C
    };
%% tos
badListCM6Tos = {
    'CMIP6.CMIP.historical.CAS.FGOALS-f3-L.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191007' ; % rotated pole, thetao too
    'CMIP6.CMIP.historical.CAS.FGOALS-f3-L.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20191007'
    'CMIP6.CMIP.historical.CAS.FGOALS-f3-L.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20191008'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191107' ; % rotated pole, thetao too
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20191126'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200811'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r4i1p1f1.mon.tos.ocean.glb-2d-gn.v20200811'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r5i1p1f1.mon.tos.ocean.glb-2d-gn.v20200811'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r6i1p1f1.mon.tos.ocean.glb-2d-gn.v20200811'
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r1i1p1f1.mon.tos.ocean.glb-2d-gr.v20190826' ; % mask/missing_value? thetao too - .glb-l vs .glb-2d
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r2i1p1f1.mon.tos.ocean.glb-2d-gr.v20190830'
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r5i1p1f1.mon.tos.ocean.glb-2d-gr.v20200429'
    'CMIP6.CMIP.historical.INM.INM-CM4-8.r1i1p1f1.mon.tos.ocean.glb-2d-gr1.v20190530-blah' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    'CMIP6.CMIP.historical.NCAR.CESM2-FV2.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191120' ; % Masking Atlantic/Southern O/Pac
    'CMIP6.CMIP.historical.NCAR.CESM2-FV2.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20200226'
    'CMIP6.CMIP.historical.NCAR.CESM2-FV2.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200226'
    'CMIP6.ScenarioMIP.ssp119.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20200527' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-f3-L.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-f3-L.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20200219'
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-f3-L.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200219'
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191229' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-g3.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20191229'
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-g3.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200101'
    'CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-g3.r4i1p1f1.mon.tos.ocean.glb-2d-gn.v20200101'
    'CMIP6.ScenarioMIP.ssp126.INM.INM-CM4-8.r1i1p1f1.mon.tos.ocean.glb-2d-gr1.v20190603-blah' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-f3-L.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-f3-L.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20200221'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-f3-L.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200220'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20191229'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r4i1p1f1.mon.tos.ocean.glb-2d-gn.v20200101'
    'CMIP6.ScenarioMIP.ssp245.INM.INM-CM4-8.r1i1p1f1.mon.tos.ocean.glb-2d-gr1.v20190603-blah' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-f3-L.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-f3-L.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20200221'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-f3-L.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200221'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r4i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r5i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.INM.INM-CM4-8.r1i1p1f1.mon.tos.ocean.glb-2d-gr1.v20190603-blah' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    'CMIP6.ScenarioMIP.ssp434.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20200526' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp460.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20200527' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp534-over.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20200526' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-f3-L.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-f3-L.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20200222'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-f3-L.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200222'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191229' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20191230'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200102'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r4i1p1f1.mon.tos.ocean.glb-2d-gn.v20191230'
    'CMIP6.ScenarioMIP.ssp585.INM.INM-CM4-8.r1i1p1f1.mon.tos.ocean.glb-2d-gr1.v20190603-blah' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    };

%% Process models
exps = dir([outDir,'ncs/',dataDate,'/CMIP6/']);
exps(ismember( {exps.name}, {'.', '..'})) = [];
expFlags = [exps.isdir];
exps = exps(expFlags);
for exp = 1:length(exps)
%for exp = 9:length(exps) % For ssp585 data reporting
    vars = dir(fullfile(outDir,'ncs',dataDate,'CMIP6',exps(exp).name));
    vars(ismember( {vars.name}, {'.', '..'})) = [];
    varFlags = [vars.isdir];
    vars = vars(varFlags);
    for var = 1:length(vars) % Cycle through variables
    %for var = 1:2 % For ssp585 data reporting
        fprintf('Sub folder #%0d = %s : %s\n', exp, exps(exp).name, vars(var).name);
        % mrro - test variable match
        if strcmp(vars(var).name,'mrro')
            disp(['mrro ',vars(var).name])
            if badListFlag
                badList = badListCM6Mrro;
            else
                badList = {};
            end
            scale = mscaler; % -6 to 40e-5 - inflate to 1e5
            clMap = 26; % red-blue (no white)
            cMin = 0; cMax = 40;
            % preallocate Ticks and TickLabels
            numTicks = 40;
            [cont3,cont2] = deal(zeros(1,numTicks));
            % distribute Ticks and TickLabels
            for n = 1:1:numTicks
                cont3(n) = log10(round(cMax)/numTicks*n); % ticks
                cont2(n) = round(cMax)/numTicks*n; % tickLabels
            end
            cont1 = cont2;
            clear numTicks
        end
        % sos - test variable match
        if strcmp(vars(var).name,'sos')
            disp(['sos ',vars(var).name])
            if badListFlag
                badList = badListCM6Sos;
            else
                badList = {};
            end
            cont1 = scont1;
            cont2 = scont2;
            cont3 = scont3;
            scale = sscaler; % 30 to 40
            clMap = 27; % blue-red (no white)
        end
        % tas - test variable match
        if strcmp(vars(var).name,'tas')
            disp(['tas ',vars(var).name])
            if badListFlag
                badList = badListCM6Tas;
            else
                badList = {};
            end
            cont1 = ptcont1;
            cont2 = ptcont2;
            cont3 = ptcont3;
            scale = ptscaler; % -2.5 to 30
            clMap = 27;
        end
        % tos - test variable match
        if strcmp(vars(var).name,'tos')
            disp(['tos ',vars(var).name])
            if badListFlag
                badList = badListCM6Tos;
            else
                badList = {};
            end
            cont1 = ptcont1;
            cont2 = ptcont2;
            cont3 = ptcont3;
            scale = ptscaler; % -2.5 to 30
            clMap = 27;
        end

        inVar = vars(var).name;
        ncVar = [inVar,'_mean_WOAGrid'];
        mipEra = 'CMIP6';
        timePeriod = extractAfter(exps(exp).name,'-');
        outData = fullfile(outDir,'ncs',dataDate,'CMIP6',exps(exp).name,vars(var).name,'woaGrid');

        % Deal with directory creation/cleanup
        if badListFlag
            pngDir = fullfile(outData,[inVar,'_badList']);
        else
            pngDir = fullfile(outData,inVar);
        end
        if exist(pngDir,'dir')
            rmdir(pngDir,'s');
        end
        mkdir(pngDir);

        % Now process
        disp([mipEra,' ',inVar,' starting..'])
        [~, models] = unix(['\ls -1 ',fullfile(outData,'*woaClim.nc')]);
        models = strtrim(models);
        temp = regexp(models,'\n','split'); clear models status
        models = unique(temp); clear temp

        % Test for no files
        null = strfind(models,': No such file or directory');
        if ~isempty(null{1})
            disp('is empty, continuing')
            continue
        end; clear null

        % Truncate using dupe list
        ind = NaN(50,1); y = 1;
        for x = 1:length(models)
            splits = strfind(models{x},'/');
            mod = models{x}(splits(end)+1:end);
            separators = strfind(mod,'.');
            %mod = mod(separators(3)+1:separators(11)-1);
            mod = mod(1:separators(11)-1);
            disp(['mod: ',mod])
            %if contains(mod,'.IPSL-CM6A-LR.')
            %if contains(mod,'.AS-RCEC.TaiESM1.')
            %   keyboard
            %end
            %match = strfind(badList,mod); % OLD, loose matching
            %match = strmatch(mod,badList,'exact'); % Test
            %match = strncmp(mod,badList,length(mod)); % Test
            %match = validatestring(mod,badList); % Test
            %match = num2cell(double(strcmp(mod,badList))); % Test
            %match = num2cell(strcmp(mod,badList));
            %match = find(~cellfun(@isempty,match), 1);
            match = strcmp(mod,badList);
            match = find(match, 1);
            if ~isempty(match)
                ind(y) = x;
                y = y + 1;
                disp(['drop: ',mod])
            end
            %keyboard
        end
        % Truncate using ind list
        ind = ind(~isnan(ind));
        ind = ismember(1:length(models),ind); % Logic is create index of files in bad_list
        models(ind) = [];
        clear bad_list ind match splits x y

        % Print models in ensemble to screen % For ssp585 data reporting
        %for x = 1:length(models)
        %    modStrTmp = strrep(models{x}, '/work/durack1/Shared/210128_PaperPlots_Rothigetal/ncs/210726/CMIP6/ssp585-2071-2101/', '');
        %    disp([num2str(x,'%03d'), ' ', modStrTmp])
        %end
        %keyboard
        %continue

        % Build matrix of model results
        varTmp = NaN(length(models),length(t_lat),length(t_lon));
        varTmp_model_names = cell(length(models),1);
        count = 1; ens_count = 1;
        ensemble = NaN(50,length(t_lat),length(t_lon));
        catchArray = NaN(3,length(models)); % 'blah blah' test below
        for x = 1:(length(models)-1)
            % Test for multiple realisations and generate ensemble mean
            model_ind = strfind(models{x},'.'); temp = models{x};
            %model1 = temp((model_ind(1)+1):(model_ind(2)-1)); clear temp
            model1 = temp((model_ind(4)+1):(model_ind(5)-1)); clear temp
            model_ind = strfind(models{x+1},'.'); temp = models{x+1};
            model2 = temp((model_ind(4)+1):(model_ind(5)-1)); clear temp

            % Plot model fields for bug-tracking - 2D
            tmp1 = getnc(models{x},inVar); temp = models{x};
            tmp1 = tmp1(:,[181:360,1:180]); % Correct lon offset issue
            ind = strfind(temp,'/'); tmp1name = regexprep(temp((ind(end)+1):end),'.nc','');
            % Start validation
            if strcmp(model1,'blah blah')
                disp(['model:',models{x}])
                tmp = min(tmp1(:),'omitnan');
                disp(['min:   ',num2str(tmp)]); catchArray(1,x) = tmp;
                tmp = median(tmp1(:),'omitnan');
                disp(['median:',num2str(tmp)]); catchArray(2,x) = tmp;
                tmp = max(tmp1(:),'omitnan');
                disp(['max:   ',num2str(tmp)]); catchArray(3,x) = tmp; clear tmp
                if x == length(models)-1
                    disp('Evaluate catchArray')
                    keyboard % Evaluate catchArray
                end
            end
            tmp2 = getnc(models{x+1},inVar); temp = models{x+1};
            tmp2 = tmp2(:,[181:360,1:180]); % Correct lon offset issue
            ind = strfind(temp,'/'); tmp2name = regexprep(temp((ind(end)+1):end),'.nc','');
            clear temp
            % Deal with tas in K
            if min(tmp1(:)) > 200
                disp('Fix K units')
                tmp1 = tmp1-273.15;
                tmp2 = tmp2-273.15;
            end
            % Plot model 1 and 2 and scale (mrro)
            for flip = 1:2
                switch flip
                    case 1
                        mod = tmp1*scale; clear tmp1
                        modName = tmp1name; clear tmp1name
                    case 2
                        mod = tmp2*scale; clear tmp2
                        modName = tmp2name; clear tmp2name
                end
                % Create canvas and plot
                close all, handle = figure('units','centimeters','visible','off','color','w'); set(0,'CurrentFigure',handle)
                ax1 = subplot(1,1,1);
                if strcmp(vars(var).name,'mrro')
                    pcolor(t_lon,t_lat,squeeze(mod)); shading flat; caxis([0 log10(cMax)]); clmap(clMap); hold all
                else
                    pcolor(t_lon,t_lat,squeeze(mod)); shading flat; caxis([cont1(1) cont1(end)]); clmap(clMap); hold all
                    contour(t_lon,t_lat,squeeze(mod),cont1,'color','k'); % don't contour log scale
                end
                hh1 = colorbarf_nw('horiz',cont3,cont2);
                set(handle,'Position',[3 3 16 7]) % Full page width (175mm (17) width x 83mm (8) height) - Back to 16.5 x 6 for proportion
                set(ax1,'Position',[0.04 0.19 0.94 0.8]);
                set(hh1,'Position',[0.06 0.075 0.9 0.03],'fontsize',fonts_c);
                set(ax1,'Tickdir','out','fontsize',fonts_ax,'layer','top','box','on', ...
                    'xlim',[0 360],'xtick',0:30:360,'xticklabel',{'0','30','60','90','120','150','180','210','240','270','300','330','360'},'xminort','on', ...
                    'ylim',[-90 90],'ytick',-90:20:90,'yticklabel',{'-90','-70','-50','-30','-10','10','30','50','70','90'},'yminort','on');
                export_fig([pngDir,'/',dateFormat,'_',modName],'-png')
                close all
                clear handle ax1 ax2 hh1 mod ind modName
            end

            if x == (length(models)-1) && ~strcmp(model1,model2)
                % Process final fields - if different
                infile = models{x};
                unit_test = getnc(infile,inVar);
                unit_test = unit_test(:,[181:360,1:180]); % Correct lon offset issue
                if min(min(unit_test(1,:,:))) > 200; unit_test = unit_test-273.15; end
                varTmp(count,:,:) = unit_test;
                varTmp_model_names{count} = model1;
                count = count + 1;
                infile = models{x+1};
                unit_test = getnc(infile,inVar);
                unit_test = unit_test(:,[181:360,1:180]); % Correct lon offset issue
                if min(min(unit_test(1,:,:))) > 200; unit_test = unit_test-273.15; end
                varTmp(count,:,:) = unit_test;
                varTmp_model_names{count} = model2;
            elseif x == (length(models)-1) && strcmp(model1,model2)
                % Process final fields - if same
                infile = models{x};
                unit_test = getnc(infile,inVar);
                unit_test = unit_test(:,[181:360,1:180]); % Correct lon offset issue
                if min(min(unit_test(1,:,:))) > 200; unit_test = unit_test-273.15; end
                ensemble(ens_count,:,:) = unit_test;
                ens_count = ens_count + 1;
                infile = models{x+1};
                unit_test = getnc(infile,inVar);
                unit_test = unit_test(:,[181:360,1:180]); % Correct lon offset issue
                if min(min(unit_test(1,:,:))) > 200; unit_test = unit_test-273.15; end
                ensemble(ens_count,:,:) = unit_test;
                % Write to matrix
                varTmp(count,:,:) = squeeze(mean(ensemble,'omitnan'));
                varTmp_model_names{count} = model1;
            elseif ~strcmp(model1,model2)
                disp([num2str(x,'%03d'),' ',inVar,' different count: ',num2str(count),' ',model1,' ',model2])
                % If models are different
                if ens_count > 1
                    varTmp(count,:,:) = squeeze(mean(ensemble,'omitnan'));
                    varTmp_model_names{count} = model1;
                    count = count + 1;
                    % Reset ensemble stuff
                    ens_count = 1;
                    ensemble = NaN(20,length(t_lat),length(t_lon));
                else
                    infile = models{x};
                    unit_test = getnc(infile,inVar);
                    unit_test = unit_test(:,[181:360,1:180]); % Correct lon offset issue
                    if min(min(unit_test(1,:,:))) > 200; unit_test = unit_test-273.15; end
                    varTmp(count,:,:) = unit_test;
                    varTmp_model_names{count} = model1;
                    count = count + 1;
                end
            else
                disp([num2str(x,'%03d'),' ',inVar,' same      count: ',num2str(count),' ',model1,' ',model2])
                % If models are the same
                infile = models{x};
                unit_test = getnc(infile,inVar);
                unit_test = unit_test(:,[181:360,1:180]); % Correct lon offset issue
                if min(unit_test(:)) > 200; unit_test = unit_test-273.15; end
                ensemble(ens_count,:,:) = unit_test;
                ens_count = ens_count + 1;
            end
        end
        % Trim excess values
        varTmp((count+1):end,:,:,:) = [];
        %varTmp_model_names((count+1):end) = [];
        clear count ens_count ensemble in_path infile model* unit_test x

        % Cludgey fix for bad data
        %{
        thetao(thetao < -3) = NaN;
        thetao(thetao > 35) = NaN;
        for x = 18:31
            % Truncate big stuff
            level = squeeze(thetao(:,x,:,:));
            index = level > 10;
            level(index) = NaN;
            thetao(:,x,:,:) = level;
            if x >= 23
                level = squeeze(thetao(:,x,:,:));
                index = level > 5;
                level(index) = NaN;
                thetao(:,x,:,:) = level;
            end
            if x >= 26
                level = squeeze(thetao(:,x,:,:));
                index = level > 2.5;
                level(index) = NaN;
                thetao(:,x,:,:) = level;
            end
            % truncate small stuff
            level = squeeze(thetao(:,x,:,:));
            index = level < -3;
            level(index) = NaN;
            thetao(:,x,:,:) = level;
        end
        %}

        % Mask marginal seas - conditional on variable
        if sum(strcmp(inVar,{'sos','tos'})) > 0
            for mod = 1:size(varTmp,1)
                varTmp(mod,:,:) = squeeze(varTmp(mod,:,:)).*basins3_NaN_ones;
            end; clear mod
        %elseif sum(strcmp(inVar,{'mrro'})) > 0
        %    for mod = 1:size(varTmp,1)
        %        varTmp(mod,:,:) = inpaint_nans(varTmp(mod,:,:)).*Inverse0p25DegreeMask;
        %    end; clear mod
        end

        % Calculate ensemble mean
        varTmp_mean = squeeze(mean(varTmp,1,'omitnan')); % Generate mean amongst models

        % CMIP potential temperature
        close all, handle = figure('units','centimeters','visible','off','color','w'); set(0,'CurrentFigure',handle)

        % multi-model mean - create canvas and plot
        close all, handle = figure('units','centimeters','visible','off','color','w'); set(0,'CurrentFigure',handle)
        ax1 = subplot(1,1,1);
        if strcmp(vars(var).name,'mrro')
            pcolor(t_lon,t_lat,varTmp_mean*scale); shading flat; caxis([0 log10(cMax)]); clmap(clMap); hold all
        else
            pcolor(t_lon,t_lat,varTmp_mean*scale); shading flat; caxis([cont1(1) cont1(end)]); clmap(clMap); hold all
            contour(t_lon,t_lat,varTmp_mean*scale,cont1,'color','k'); % don't contour log scale
        end
        hh1 = colorbarf_nw('horiz',cont3,cont2);
        set(handle,'Position',[3 3 16 7]) % Full page width (175mm (17) width x 83mm (8) height) - Back to 16.5 x 6 for proportion
        set(ax1,'Position',[0.04 0.19 0.94 0.8]);
        set(hh1,'Position',[0.06 0.075 0.9 0.03],'fontsize',fonts_c);
        set(ax1,'Tickdir','out','fontsize',fonts_ax,'layer','top','box','on', ...
            'xlim',[0 360],'xtick',0:30:360,'xticklabel',{'0','30','60','90','120','150','180','210','240','270','300','330','360'},'xminort','on', ...
            'ylim',[-90 90],'ytick',-90:20:90,'yticklabel',{'-90','-70','-50','-30','-10','10','30','50','70','90'},'yminort','on');
        export_fig([outDir,dateFormat,'_',dataDate,'_',mipEra,'_',exps(exp).name,'_',inVar,'_mean'],'-png')
        clear handle ax1 ax2 hh1 cont1 cont2 cont3 ncVar badList
        % Calculate zonal means
        varName = [inVar,'_',mipEra,'_',strrep(exps(exp).name,'-','_')];
        eval([varName,' = varTmp;']);
        eval([varName,'_mean = varTmp_mean;']);
        eval([varName,'_modelNames = varTmp_model_names;']); % Generate model name lookup
        clear varTmp varTmp_mean varTmp_model_names
        disp([inVar,' ',mipEra,' ',exps(exp).name,' done..'])
        clear mipEra mipVar inVar
    end
    clear var
end
clear exp expFlags varFlags
disp('** Model processing complete.. **')

%% Save WOA18 and CMIP5/6 ensemble matrices to file
% Rename obs
so_woa18_mean = s_mean; clear s_mean
thetao_woa18_mean = pt_mean; clear pt_mean
outFile = [outDir,dateFormatLong,'_',dataDate,'_CMIP6.mat'];
delete(outFile)
save(outFile, ...
    'so_woa18_mean','thetao_woa18_mean', ...
    'mrro_CMIP6_*', ...
    'sos_CMIP6_*', ...
    'tas_CMIP6_*', ...
    'tos_CMIP6_*', ...
    't_depth','t_lat','t_lon', ...
    'aHostLongname','badList*','basins3_NaN_ones', ...
    'dataDate','dataDir','exps', ...
    'homeDir','obsDir','outData','outDir','vars');
disp('** All data written to *.mat.. **')

%% Or load WOA18 and CMIP5/6 ensemble matrices from saved file
%load /work/durack1/Shared/210128_PaperPlots_Rothigetal/210328T000410_210325_CMIP6.mat

%% Figure 1 - obs sos change, ssp585 sos and mrro changes
close all
warning off export_fig:exportgraphics
fonts = 8;
dateFormat = datestr(now,'yymmdd');
sscale = 1;
mscale = 100; % In % change not needed

% Get colormap
clM = clmap(28);
clS = clmap(27);

% Load obs change
obsFile = [homeDir,'200428_data_OceanObsAnalysis/DurackandWijffels_GlobalOceanChanges_19500101-20210106__210122-205144_beta.nc'];
obsSChg = getnc(obsFile,'salinity_change',[-1 1 -1 -1],[-1 1 -1 -1]);
obsLat = getnc(obsFile,'latitude');
obsLon = getnc(obsFile,'longitude');

% Generate 3 panel plot
% Create canvas
close all, handle = figure('units','centimeters','visible','on','color','w'); set(0,'CurrentFigure',handle); clmap(27)

% Labels
xLimLab = 110; yLimLab = 57; xLimLabInfo = 80; yLimLabInfo = 52;

% Obs salinity
ax1 = subplot(3,1,1);
%colormap(ax1,clS) ; % Set palette - Blue -> Red
pcolor(obsLon,obsLat,obsSChg); caxis([-1 1]*sscale); shading flat; continents
ylab1 = ylabel('Latitude');
cb1 = colorbarf_nw('vert',-1:0.0625:1,-1:.25:1);
lab1 = text(xLimLab,yLimLab,'A');
lab1Info = text(xLimLabInfo,yLimLabInfo,{'1950-2020';'Obs. Salinity'});

% sos ssp585
% Calculate diff
s585SosDiff = sos_CMIP6_ssp585_2071_2101_mean-sos_CMIP6_historical_1985_2015_mean;
ax2 = subplot(3,1,2);
%colormap(ax2,clS) ; % Set palette - Blue -> Red
pcolor(t_lon,t_lat,s585SosDiff); caxis([-1 1]*sscale); shading flat; continents
ylab2 = ylabel('Latitude');
lab2 = text(xLimLab,yLimLab,'B');
lab2Info = text(xLimLabInfo,yLimLabInfo,{'2071-2100';'CMIP6 SSP585 Salinity'});

% mrro ssp585
% Calculate percent change
s585MrroDiff = ((mrro_CMIP6_ssp585_2071_2101_mean./mrro_CMIP6_historical_1985_2015_mean)-1)*100; % kg m-2 s-1
ax3 = subplot(3,1,3);
pcM = pcolor(t_lon,t_lat,s585MrroDiff); caxis([-1 1]*mscale); shading flat;
hold on; coast('k');
colormap(ax3,clM) ; % Switch palette - Brown -> Green
xlab3 = xlabel('Longitude');
ylab3 = ylabel('Latitude');
lab3 = text(xLimLab,yLimLab,'C');
lab3Info = text(188,40,{'2071-2100';'CMIP6 SSP585 Runoff'});
cb2 = colorbarf_nw('vert',[-1:.125:1]*mscale,[-1:.25:1]*mscale);

% Deal with axes
yticks = {'','75S','','55S','','35S','','15S','','','15N','','35N','','55N','','75N',''};
xticks = {'0','60E','120E','180','120W','60W','0'};
set(ax1,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
    'xlim',[0 360],'xtick',0:60:360,'xticklabel',{''},'yminort','on', ...
    'ylim',[-85 85],'ytick',-85:10:85,'yticklabel',yticks,'xminort','on');
set(ax2,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
    'xlim',[0 360],'xtick',0:60:360,'xticklabel',{''},'yminort','on', ...
    'ylim',[-85 85],'ytick',-85:10:85,'yticklabel',yticks,'xminort','on');
set(ax3,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
    'xlim',[0 360],'xtick',0:60:360,'xticklabel',xticks,'yminort','on', ...
    'ylim',[-85 85],'ytick',-85:10:85,'yticklabel',yticks,'xminort','on');
% Resize into canvas
set(handle,'Position',[2 2 17 20]) % Full page width (175mm (17) width x 83mm (8) height)
xlim = 0.07; xlimCb = 0.94; xlimWid = 0.015; wid = 0.85; hei = 0.3; labFont = 12; labInfoFont = 10;
set(ax1,'Position',[xlim 0.69 wid hei]);
set(lab1,'fontsize',labFont,'fontweight','bold')
set(lab1Info,'fontsize',labInfoFont,'fontweight','normal','HorizontalAlignment','center')
set(ax2,'Position',[xlim 0.37 wid hei]);
set(lab2,'fontsize',labFont,'fontweight','bold')
set(lab2Info,'fontsize',labInfoFont,'fontweight','normal','HorizontalAlignment','center')
set(cb1,'Position',[xlimCb 0.37 xlimWid 0.62],'fontsize',fonts)
set(ax3,'Position',[xlim 0.05 wid hei]);
set(lab3,'fontsize',labFont,'fontweight','bold')
set(lab3Info,'fontsize',labInfoFont,'fontweight','normal','HorizontalAlignment','center')
set(cb2,'Position',[xlimCb 0.05 xlimWid 0.3],'fontsize',fonts,'Colormap',clM)

% Print to file
outName = [outDir,dateFormat,'_durack1_Rothigetal21NatCC_Figure1'];
export_fig(outName,'-png')
export_fig(outName,'-eps')

%% Diff figures - diff maps for sos
close all
warning off export_fig:exportgraphics
fonts = 8;
dateFormat = datestr(now,'yymmdd');

% Loop through scenarios
scens = whos('sos*mean');
for scen = 2:length(scens)
    scenId = strrep(strrep(strrep(strrep(scens(scen).name,'sos_CMIP6_',''),'_mean',''),'_',' '),'2071 2101','');
    if contains(scenId,'ssp534')
        scenId = 'ssp534-over'; % Fix missing hyphen
    end
    disp(scenId)
    % Load variable and diff
    tmp = eval(scens(scen).name);
    tmp2 = tmp-sos_CMIP6_historical_1985_2015_mean;
    % Create canvas
    close all, handle = figure('units','centimeters','visible','off','color','w'); set(0,'CurrentFigure',handle); clmap(27)
    ax1 = subplot(1,2,1);
    pcolor(t_lon,t_lat,tmp); caxis([30,40]); shading flat; continents;
    hh1 = colorbarf_nw('horiz',30:0.25:40,30:1:40);
    xlab1 = xlabel('Longitude');
    ylab1 = ylabel('Latitude');
    titleAx1 = title([scenId,'2071-2101']);
    ax2 = subplot(1,2,2);
    pcolor(t_lon,t_lat,tmp2); caxis([-2 2]); shading flat; continents
    hh2 = colorbarf_nw('horiz',-2:0.25:2,-2:.5:2);
    set(hh2,'XTickLabelRotation',0)
    xlab2 = xlabel('Longitude');
    titleAx2 = title([scenId,'2071-2101 minus historical 1985-2015']);
    % Deal with axes
    set(ax1,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
        'xlim',[0 360],'xtick',0:60:360,'xticklabel',{'0','60E','120E','180','120W','60W','0'},'yminort','on', ...
        'ylim',[-85 85],'ytick',-85:10:85,'yticklabel',{'','75S','','55S','','35S','','15S','','','15N','','35N','','55N','','75N',''},'xminort','on');
    set(ax2,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
        'xlim',[0 360],'xtick',0:60:360,'xticklabel',{'0','60E','120E','180','120W','60W','0'},'yminort','on', ...
        'ylim',[-85 85],'ytick',-85:10:85,'yticklabel',{},'xminort','on');
    % Resize into canvas
    set(handle,'Position',[2 2 20 7]) % Full page width (175mm (17) width x 83mm (8) height) - Back to 16.5 x 6 for proportion
    set(ax1,'Position',[0.055 0.2 0.45 0.7]);
    set(hh1,'Position',[0.08 0.05 0.4 0.02],'fontsize',fonts)
    set(ax2,'Position',[0.520 0.2 0.45 0.7]);
    set(hh2,'Position',[0.545 0.05 0.4 0.02],'fontsize',fonts)

    % Print to file
    outName = [outDir,dateFormat,'_durack1_CMIP6_sos_',strtrim(scenId),'minusHistorical1985-2015'];
    export_fig(outName,'-png')
    export_fig(outName,'-eps')

    close all %set(gcf,'visi','on');
    clear scenId tmp tmp2 ax* hh* xlab* titleAx* outName
end
clear scen scens

%% Terminate Matlab session if batch job
clear; close all
[command] = matlab_mode;
disp(command)
if contains(command,'-batch') % If batch job exit
    disp('MATLAB: batch job determined, exiting..')
    exit
else
    disp('MATLAB: interactive mode determined.. Doing nothing particular..')
end
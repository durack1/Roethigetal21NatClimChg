% This file generates two-panel figures displaying density changes for
% global basins as sourced from DW10
%
% Paul J. Durack 7th January 2011
%
% make_AR6_Fig1_CMIP6vsObs_soetal.m

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

% Cleanup workspace and command window
clear, clc, close all
% Initialise environment variables
[homeDir,~,dataDir,obsDir,~,aHostLongname] = myMatEnv(2);
outDir = os_path([homeDir,'210128_PaperPlots_Rothigetal/']);
dataDate = '210324';
dateFormat = datestr(now,'yymmdd');

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
sscale = [1 1]; gscale = [0.3 0.5]; ptscale = [3 3];
fonts = 7; fonts_c = 6; fonts_ax = 6; fonts_lab = 10;

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
    delete([outDir,'ncs/',dataDate,'/CMIP*/*/woaGrid/*/',dateFormat,'*.png']);
end

%% Print time to console, for logging
disp(['TIME: ',datestr(now)])
setenv('USERCREDENTIALS','Paul J. Durack; pauldurack@llnl.gov (durack1); +1 925 422 5208')
disp(['CONTACT: ',getenv('USERCREDENTIALS')])
disp(['HOSTNAME: ',aHostLongname])
a = getGitInfo('/export/durack1/git/export_fig/') ;
disp([upper('export_fig hash: '),a.hash])
a = getGitInfo('/export/durack1/git/Roethigetal21NatClimChg/') ;
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
badListCM6Mrro = { };
t1 = {
    'CMIP6.CMIP.historical.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.CMIP.historical.CCCma.CanESM5.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r2i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r3i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.CMIP.historical.CCCma.CanESM5.r1i1p2f1.mon.mrro.land.glb-2d-gn.v20190429'
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
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20191003'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20191010'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r1i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20191003'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20191010'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r2i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20191003'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20191010'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r3i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20191003'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20191010'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r4i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20191003'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20191010'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r5i1p5f1.mon.mrro.land.glb-2d-gn.v20190905'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r6i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r7i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r8i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r9i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NASA-GISS.GISS-E2-1-H.r10i1p1f1.mon.mrro.land.glb-2d-gn.v20190403'
    'CMIP6.CMIP.historical.NCC.NorESM2-LM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190917' ; % no ocean masking
    'CMIP6.CMIP.historical.NCC.NorESM2-LM.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190920'
    'CMIP6.CMIP.historical.NCC.NorESM2-LM.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190920'
    'CMIP6.CMIP.historical.NCC.NorESM2-MM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191108' ; % no ocean masking
    'CMIP6.CMIP.historical.NCC.NorESM2-MM.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20200218'
    'CMIP6.CMIP.historical.NCC.NorESM2-MM.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20200702'
    'CMIP6.CMIP.historical.NOAA-GFDL.GFDL-CM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
    'CMIP6.CMIP.historical.NOAA-GFDL.GFDL-ESM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190726' ; % no ocean masking
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
    'CMIP6.ScenarioMIP.ssp119.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp119.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp119.NOAA-GFDL.GFDL-ESM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
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
    'CMIP6.ScenarioMIP.ssp126.INM.INM-CM4-8.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190603' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.INM.INM-CM5-0.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20190619' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.IPSL.IPSL-CM5A2-INCA.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20201218' ; % lats bound to 90
    'CMIP6.ScenarioMIP.ssp126.IPSL.IPSL-CM6A-LR.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20190903-blah' ; % no Antarctica
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r1i1p5f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r2i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NASA-GISS.GISS-E2-1-G.r5i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp126.NCC.NorESM2-LM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191108' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.NCC.NorESM2-MM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191108' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp126.NOAA-GFDL.GFDL-ESM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
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
    'CMIP6.ScenarioMIP.ssp245.NCC.NorESM2-LM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191108' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp245.NCC.NorESM2-LM.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20191108'
    'CMIP6.ScenarioMIP.ssp245.NCC.NorESM2-LM.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20191108'
    'CMIP6.ScenarioMIP.ssp245.NCC.NorESM2-MM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191108'
    'CMIP6.ScenarioMIP.ssp245.NCC.NorESM2-MM.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20200702'
    'CMIP6.ScenarioMIP.ssp245.NOAA-GFDL.GFDL-CM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp245.NOAA-GFDL.GFDL-ESM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
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
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r3i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r3i1p3f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r4i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r6i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r7i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r8i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r9i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NASA-GISS.GISS-E2-1-G.r10i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp370.NCC.NorESM2-LM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191108' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp370.NCC.NorESM2-MM.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20191108'
    'CMIP6.ScenarioMIP.ssp370.NOAA-GFDL.GFDL-ESM4.r1i1p1f1.mon.mrro.land.glb-2d-gr1.v20180701' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp434.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp434.CCCma.CanESM5.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp434.CCCma.CanESM5.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp434.CCCma.CanESM5.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp434.CCCma.CanESM5.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp434.IPSL.IPSL-CM6A-LR.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20190506-blah' ; % no Antarctica
    'CMIP6.ScenarioMIP.ssp434.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp434.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp460.CCCma.CanESM5.r1i1p1f1.mon.mrro.land.glb-2d-gn.v20190429' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp460.CCCma.CanESM5.r2i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp460.CCCma.CanESM5.r3i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp460.CCCma.CanESM5.r4i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp460.CCCma.CanESM5.r5i1p1f1.mon.mrro.land.glb-2d-gn.v20190429'
    'CMIP6.ScenarioMIP.ssp460.IPSL.IPSL-CM6A-LR.r1i1p1f1.mon.mrro.land.glb-2d-gr.v20190506-blah' ; % no Antarctica
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r1i1p1f2.mon.mrro.land.glb-2d-gn.v20200115' ; % no ocean masking
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r1i1p3f1.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r2i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r3i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r4i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    'CMIP6.ScenarioMIP.ssp460.NASA-GISS.GISS-E2-1-G.r5i1p1f2.mon.mrro.land.glb-2d-gn.v20200115'
    };
%% sos
badListCM6Sos = { };
t2 = {
    'CMIP6.CMIP.historical.CAS.FGOALS-f3-L.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191007' ; % rotated pole, thetao too
    'CMIP6.CMIP.historical.CAS.FGOALS-f3-L.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20191007'
    'CMIP6.CMIP.historical.CAS.FGOALS-f3-L.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20191008'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191107' ; % rotated pole, thetao too
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20191126'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r41i1p1f1.mon.sos.ocean.glb-2d-gn.v20191012'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r51i1p1f1.mon.sos.ocean.glb-2d-gn.v20191013'
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r1i1p1f1.mon.sos.ocean.glb-l-gr.v20190826' ; % mask/missing_value? thetao too
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r2i1p1f1.mon.sos.ocean.glb-l-gr.v20190830'
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r3i1p1f1.mon.sos.ocean.glb-l-gr.v20190827'
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r4i1p1f1.mon.sos.ocean.glb-l-gr.v20190909'
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r5i1p1f1.mon.sos.ocean.glb-l-gr.v20200429'
    'CMIP6.CMIP.historical.INM.INM-CM4-8.r1i1p1f1.mon.sos.ocean.glb-l-gr1.v20190530' ; % Values over Russia and Antarctica/grid (same for so/thetao)
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
    'CMIP6.ScenarioMIP.ssp126.INM.INM-CM4-8.r1i1p1f1.mon.sos.ocean.glb-2d-gr1.v20190603' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-f3-L.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-f3-L.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20200221'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-f3-L.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20200220'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20191229'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r4i1p1f1.mon.sos.ocean.glb-2d-gn.v20200101'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-f3-L.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-f3-L.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20200221'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-f3-L.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20200221'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r4i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r5i1p1f1.mon.sos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.INM.INM-CM4-8.r1i1p1f1.mon.sos.ocean.glb-2d-gr1.v20190603' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    'CMIP6.ScenarioMIP.ssp434.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20200526' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp460.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20200527' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp534-over.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20200526' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-f3-L.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-f3-L.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20200222'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r1i1p1f1.mon.sos.ocean.glb-2d-gn.v20191229'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r2i1p1f1.mon.sos.ocean.glb-2d-gn.v20191230'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20200102'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r4i1p1f1.mon.sos.ocean.glb-2d-gn.v20191230'
    'CMIP6.ScenarioMIP.ssp585.INM.INM-CM4-8.r1i1p1f1.mon.sos.ocean.glb-2d-gr1.v20190603' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    };
%% tas
badListCM6Tas = { };
t3 = {
    'CMIP6.CMIP.historical.NIMS-KMA.KACE-1-0-G.r3i1p1f1.mon.tas.atmos.glb-z1-gr.v20190919' ; % Land surface >30C
    };
%% tos
badListCM6Tos = { };
t4 = {
    'CMIP6.CMIP.historical.CAS.FGOALS-f3-L.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191007' ; % rotated pole, thetao too
    'CMIP6.CMIP.historical.CAS.FGOALS-f3-L.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20191007'
    'CMIP6.CMIP.historical.CAS.FGOALS-f3-L.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20191008'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191107' ; % rotated pole, thetao too
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20191126'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200811'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r4i1p1f1.mon.tos.ocean.glb-2d-gn.v20200811'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r5i1p1f1.mon.tos.ocean.glb-2d-gn.v20200811'
    'CMIP6.CMIP.historical.CAS.FGOALS-g3.r6i1p1f1.mon.tos.ocean.glb-2d-gn.v20200811'
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r1i1p1f1.mon.sos.ocean.glb-l-gr.v20190826' ; % mask/missing_value? thetao too
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r2i1p1f1.mon.sos.ocean.glb-l-gr.v20190830'
    'CMIP6.CMIP.historical.E3SM-Project.E3SM-1-0.r5i1p1f1.mon.sos.ocean.glb-l-gr.v20200429'
    'CMIP6.CMIP.historical.INM.INM-CM4-8.r1i1p1f1.mon.tos.ocean.glb-l-gr1.v20190530' ; % Values over Russia and Antarctica/grid (same for so/thetao)
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
    'CMIP6.ScenarioMIP.ssp126.INM.INM-CM4-8.r1i1p1f1.mon.tos.ocean.glb-2d-gr1.v20190603' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-f3-L.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-f3-L.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20200221'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-f3-L.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200220'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20191229'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp245.CAS.FGOALS-g3.r4i1p1f1.mon.tos.ocean.glb-2d-gn.v20200101'
    'CMIP6.ScenarioMIP.ssp245.INM.INM-CM4-8.r1i1p1f1.mon.tos.ocean.glb-2d-gr1.v20190603' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-f3-L.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-f3-L.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20200221'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-f3-L.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200221'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r4i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.CAS.FGOALS-g3.r5i1p1f1.mon.tos.ocean.glb-2d-gn.v20191231'
    'CMIP6.ScenarioMIP.ssp370.INM.INM-CM4-8.r1i1p1f1.mon.tos.ocean.glb-2d-gr1.v20190603' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    'CMIP6.ScenarioMIP.ssp434.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20200526' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp460.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20200527' ; % rotated pole, thetao too
    'ssp534-over missing'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-f3-L.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191008' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-f3-L.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20200222'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-f3-L.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200222'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r1i1p1f1.mon.tos.ocean.glb-2d-gn.v20191229' ; % rotated pole, thetao too
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r2i1p1f1.mon.tos.ocean.glb-2d-gn.v20191230'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20200102'
    'CMIP6.ScenarioMIP.ssp585.CAS.FGOALS-g3.r4i1p1f1.mon.tos.ocean.glb-2d-gn.v20191230'
    'CMIP6.ScenarioMIP.ssp585.INM.INM-CM4-8.r1i1p1f1.mon.tos.ocean.glb-2d-gr1.v20190603' ; % Values over Russia and Antarctica/grid (same for so/thetao)
    };

%% Process models
exps = dir([outDir,'ncs/',dataDate,'/CMIP6/']);
exps(ismember( {exps.name}, {'.', '..'})) = [];
expFlags = [exps.isdir];
exps = exps(expFlags);
for exp = 1:length(exps)
    vars = dir(fullfile(outDir,'ncs',dataDate,'CMIP6',exps(exp).name));
    vars(ismember( {vars.name}, {'.', '..'})) = [];
    varFlags = [vars.isdir];
    vars = vars(varFlags);
    for var = 1:length(vars) % Cycle through variables
        fprintf('Sub folder #%0d = %s : %s\n', exp, exps(exp).name, vars(var).name);
        % mrro - test variable match
        if strcmp(vars(var).name,'mrro')
            disp(['mrro ',vars(var).name])
            badList = badListCM6Mrro;
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

            badList = badListCM6Sos;
            cont1 = scont1;
            cont2 = scont2;
            cont3 = scont3;
            scale = sscaler; % 30 to 40
            clMap = 27; % blue-red (no white)
        end
        % tas - test variable match
        if strcmp(vars(var).name,'tas')
            disp(['tas ',vars(var).name])
            badList = badListCM6Tas;
            cont1 = ptcont1;
            cont2 = ptcont2;
            cont3 = ptcont3;
            scale = ptscaler; % -2.5 to 30
            clMap = 27;
        end
        % tos - test variable match
        if strcmp(vars(var).name,'tos')
            disp(['tos ',vars(var).name])
            badList = badListCM6Tos;
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
        pngDir = fullfile(outData,inVar);
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
            mod = mod(separators(3)+1:separators(11)-1);
            %disp(['mod:',mod])
            match = strfind(badList,mod);
            match = find(~cellfun(@isempty,match), 1);
            if ~isempty(match)
                ind(y) = x;
                y = y + 1;
                disp(['drop: ',mod])
            end
        end
        % Truncate using ind list
        ind = ind(~isnan(ind));
        ind = ismember(1:length(models),ind); % Logic is create index of files in bad_list
        models(ind) = [];
        clear bad_list ind match splits x y

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

            % Plot model fields for bug-tracking - 2D and global zonal mean
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

        % Mask marginal seas
        for mod = 1:size(varTmp,1)
            varTmp(mod,:,:) = squeeze(varTmp(mod,:,:)).*basins3_NaN_ones;
        end; clear mod

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
outFile = [outDir,dateFormat,'_',dataDate,'_CMIP6.mat'];
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
%load 210325_210324_CMIP6.mat

%% Figure 3.23 global - thetao and so clim vs WOA18
%{
close all
% Determine depth split
depth1 = find(t_depth == 1000);
for mipEra = 1:2
    switch mipEra
        case 1
            % Create anomaly fields
            thetao_mean_anom_zonal = thetao_cmip5_mean_zonal - thetao_woa18_mean_zonal;
            pt_mean_zonal = thetao_woa18_mean_zonal;
            so_mean_anom_zonal = so_cmip5_mean_zonal - so_woa18_mean_zonal;
            s_mean_zonal = so_woa18_mean_zonal;
            mipEraId = 'cmip5';
        case 2
            % Create anomaly fields
            thetao_mean_anom_zonal = thetao_cmip6_mean_zonal - thetao_woa18_mean_zonal;
            pt_mean_zonal = thetao_woa18_mean_zonal;
            so_mean_anom_zonal = so_cmip6_mean_zonal - so_woa18_mean_zonal;
            s_mean_zonal = so_woa18_mean_zonal;
            mipEraId = 'cmip6';
    end
    % Do thetao global
    close all, handle = figure('units','centimeters','visible','off','color','w'); set(0,'CurrentFigure',handle); clmap(27)

    % Potential Temperature
    % 0-1000db
    ax1 = subplot(2,2,1);
    [~,h] = contourf(t_lat,t_depth(1:depth1),thetao_mean_anom_zonal(1:depth1,:),50); hold all
    set(h,'linestyle','none'); hold all; clear h
    axis ij, caxis([-1 1]*ptscale(1)), clmap(27), hold all
    contour(t_lat,t_depth(1:depth1),pt_mean_zonal(1:depth1,:),[2.5 7.5 12.5 17.5 22.5 27.5],'k')
    [c,h] = contour(t_lat,t_depth(1:depth1),pt_mean_zonal(1:depth1,:),0:5:30,'k','linewidth',2);
    clabel(c,h,'LabelSpacing',200,'fontsize',fonts_c,'fontweight','bold','color','k')
    contour(t_lat,t_depth(1:depth1),thetao_mean_anom_zonal(1:depth1,:),-ptscale(2):1:ptscale(2),'color',[1 1 1]);
    ylab1 = ylabel('Depth (m)','fontsize',fonts);
    set(ax1,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
        'ylim',[0 1000],'ytick',0:200:1000,'yticklabel',{'0','200','400','600','800',''},'yminort','on', ...
        'xlim',[-90 90],'xtick',-90:10:90,'xticklabel','','xminort','on');

    % 1000-5000db
    ax3 = subplot(2,2,3);
    [~,h] = contourf(t_lat,t_depth(depth1:end),thetao_mean_anom_zonal(depth1:end,:),50); hold all
    set(h,'linestyle','none'); hold all; clear h
    axis ij, caxis([-1 1]*ptscale(1)), clmap(27), hold all
    contour(t_lat,t_depth(depth1:end),pt_mean_zonal(depth1:end,:),[2.5 7.5 12.5 17.5 22.5 27.5],'k')
    [c,h] = contour(t_lat,t_depth(depth1:end),pt_mean_zonal(depth1:end,:),0:5:30,'k','linewidth',2);
    clabel(c,h,'LabelSpacing',200,'fontsize',fonts_c,'fontweight','bold','color','k')
    contour(t_lat,t_depth(depth1:end),thetao_mean_anom_zonal(depth1:end,:),-ptscale(2):1:ptscale(2),'color',[1 1 1]);
    xlab3 = xlabel('Latitude','fontsize',fonts);
    text(98,4650,'Temperature','fontsize',fonts_lab,'horizontalAlignment','right','color','k','fontweight','b');
    text(-88,4650,'A','fontsize',fonts_lab*1.5,'horizontalAlignment','left','color','k','fontweight','b');
    hh3 = colorbarf_nw('horiz',-ptscale(1):0.25:ptscale(1),-ptscale(1):1:ptscale(1));
    set(hh3,'clim',[-ptscale(1) ptscale(1)]); % See https://www.mathworks.com/help/matlab/ref/matlab.graphics.illustration.colorbar-properties.html
    set(ax3,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
        'ylim',[1000 5000],'ytick',1000:500:5000,'yticklabel',{'1000','','2000','','3000','','4000','','5000'},'yminort','on', ...
        'xlim',[-90 90],'xtick',-90:10:90,'xticklabel',{'90S','','','60S','','','30S','','','EQU','','','30N','','','60N','','','90N'},'xminort','on');

    % Salinity
    % 0-1000db
    ax2 = subplot(2,2,2);
    [~,h] = contourf(t_lat,t_depth(1:depth1),so_mean_anom_zonal(1:depth1,:),50); hold all
    set(h,'linestyle','none'); hold all; clear h
    axis ij, caxis([-1 1]*sscale(1)), clmap(27), hold all
    contour(t_lat,t_depth(1:depth1),s_mean_zonal(1:depth1,:),scont1,'k')
    [c,h] = contour(t_lat,t_depth(1:depth1),s_mean_zonal(1:depth1,:),scont2,'k','linewidth',2);
    clabel(c,h,'LabelSpacing',200,'fontsize',fonts_c,'fontweight','bold','color','k')
    contour(t_lat,t_depth(1:depth1),so_mean_anom_zonal(1:depth1,:),-sscale(2):0.25:sscale(2),'color',[1 1 1]);
    set(ax2,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
        'ylim',[0 1000],'ytick',0:200:1000,'yticklabel',{''},'yminort','on', ...
        'xlim',[-90 90],'xtick',-90:10:90,'xticklabel','','xminort','on');

    % 1000-5000db
    ax4 = subplot(2,2,4);
    [~,h] = contourf(t_lat,t_depth(depth1:end),so_mean_anom_zonal(depth1:end,:),50); hold all
    set(h,'linestyle','none'); hold all; clear h
    axis ij, caxis([-1 1]*sscale(1)), clmap(27), hold all
    contour(t_lat,t_depth(depth1:end),s_mean_zonal(depth1:end,:),scont1,'k')
    [c,h] = contour(t_lat,t_depth(depth1:end),s_mean_zonal(depth1:end,:),scont2,'k','linewidth',2);
    clabel(c,h,'LabelSpacing',200,'fontsize',fonts_c,'fontweight','bold','color','k')
    contour(t_lat,t_depth(depth1:end),so_mean_anom_zonal(depth1:end,:),-sscale(2):0.25:sscale(2),'color',[1 1 1]);
    xlab4 = xlabel('Latitude','fontsize',fonts);
    text(94,4650,'Salinity','fontsize',fonts_lab,'horizontalAlignment','right','color','k','fontweight','b');
    text(-88,4650,'B','fontsize',fonts_lab*1.5,'horizontalAlignment','left','color','k','fontweight','b');
    hh4 = colorbarf_nw('horiz',-sscale(1):0.125:sscale(1),-sscale(1):0.25:sscale(1));
    set(hh4,'clim',[-sscale(1) sscale(1)])
    set(ax4,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
        'ylim',[1000 5000],'ytick',1000:500:5000,'yticklabel',{''},'yminort','on', ...
        'xlim',[-90 90],'xtick',-90:10:90,'xticklabel',{'90S','','','60S','','','30S','','','EQU','','','30N','','','60N','','','90N'},'xminort','on');

    % Resize into canvas
    set(handle,'Position',[3 3 18 7]) % Full page width (175mm (17) width x 83mm (8) height) - Back to 16.5 x 6 for proportion
    set(ax1,'Position',[0.0550 0.58 0.45 0.40]);
    set(ax3,'Position',[0.0550 0.17 0.45 0.40]);
    set(hh3,'Position',[0.0750 0.042 0.41 0.015],'fontsize',fonts);
    set(ax2,'Position',[0.535 0.58 0.45 0.40]);
    set(ax4,'Position',[0.535 0.17 0.45 0.40]);
    set(hh4,'Position',[0.555 0.042 0.410 0.015],'fontsize',fonts);

    % Drop blanking mask between upper and lower panels
    %axr1 = axes('Position',[0.0475 0.57061 0.95 0.01],'xtick',[],'ytick',[],'box','off','visible','on','xcolor',[1 1 1],'ycolor',[1 1 1]);
    axr1 = axes('Position',[0.0475 0.575 0.95 0.004],'xtick',[],'ytick',[],'box','off','visible','on','xcolor',[1 1 1],'ycolor',[1 1 1]);

    % Axis labels
    set(ylab1,'Position',[-106 1000 1.0001]);
    set(xlab3,'Position',[0 5600 1.0001]);
    set(xlab4,'Position',[0 5600 1.0001]);

    % Print to file
    export_fig([outDir,dateFormat,'_durack1_AR6WG1_Ch3_Fig3p23_',mipEraId,'minusWOA18_thetaoAndso_global'],'-png')
    export_fig([outDir,dateFormat,'_durack1_AR6WG1_Ch3_Fig3p23_',mipEraId,'minusWOA18_thetaoAndso_global'],'-eps')

    close all %set(gcf,'visi','on');
    clear ax* c h handle hh* xlab* ylab* mipEra
end
%}

%% Figure 3.23 basins - thetao and so clim vs WOA18
%{
close all
% Load basin mask
infile = os_path([homeDir,'code/make_basins.mat']);
load(infile,'basins3_NaN','lat','lon'); % lat/lon same as WOA18
%pcolor(lon,lat,basins3_NaN); shading flat

% Determine depth split
depth1 = find(t_depth == 1000);
for mipEra = 1:2
    switch mipEra
        case 0
            % Create anomaly fields
            thetao_mean_anom_zonal = thetao_cmip5_mean_zonal - thetao_woa18_mean_zonal;
            pt_mean_zonal = thetao_woa18_mean_zonal;
            so_mean_anom_zonal = so_cmip5_mean_zonal - so_woa18_mean_zonal;
            so_mean_zonal = so_woa18_mean_zonal;
            mipEraId = 'cmip5';
        case 1
            % Create anomaly fields
            thetao_mean_anom = thetao_cmip5_mean - thetao_woa18_mean;
            pt_mean = thetao_woa18_mean;
            so_mean_anom = so_cmip5_mean - so_woa18_mean;
            so_mean = so_woa18_mean;
            mipEraId = 'cmip5';
        case 2
            % Create anomaly fields
            thetao_mean_anom = thetao_cmip6_mean - thetao_woa18_mean;
            pt_mean = thetao_woa18_mean;
            so_mean_anom = so_cmip6_mean - so_woa18_mean;
            so_mean = so_woa18_mean;
            mipEraId = 'cmip6';
    end

    % Do basin zonals
    close all, handle = figure('units','centimeters','visible','off','color','w'); set(0,'CurrentFigure',handle); clmap(27)

    for basin = 1:4
        switch basin
            case 1
                % Global
                axInfo = 1;
                mask = ones([102,size(basins3_NaN)]);
                basinLabels = ['A','B'];
                basinId = 'GLO';
            case 2
                % Atlantic
                axInfo = 5;
                tmp = basins3_NaN;
                index = tmp ~= 2; tmp(index) = NaN;
                index = tmp == 2; tmp(index) = 1; clear index
                tmp = repmat(tmp,[1 1 102]);
                mask = shiftdim(tmp,2); clear tmp
                %pcolor(lon,lat,squeeze(mask(1,:,:))); shading flat
                basinLabels = ['C','D'];
                basinId = 'ATL';
            case 3
                % Pacific
                axInfo = 9;
                tmp = basins3_NaN;
                index = tmp ~= 1; tmp(index) = NaN;
                index = tmp == 1; tmp(index) = 1; clear index
                tmp = repmat(tmp,[1 1 102]);
                mask = shiftdim(tmp,2); clear tmp
                %pcolor(lon,lat,squeeze(mask(1,:,:))); shading flat
                basinLabels = ['E','F'];
                basinId = 'PAC';
            case 4
                % Indian
                axInfo = 13;
                tmp = basins3_NaN;
                index = tmp ~= 3; tmp(index) = NaN;
                index = tmp == 3; tmp(index) = 1; clear index
                tmp = repmat(tmp,[1 1 102]);
                mask = shiftdim(tmp,2); clear tmp
                %pcolor(lon,lat,squeeze(mask(1,:,:))); shading flat
                basinLabels = ['G','H'];
                basinId = 'IND';
        end

        % Generate anomaly zonal means
        thetao_mean_anom_zonal = nanmean((thetao_mean_anom.*mask),3);
        pt_mean_zonal = nanmean((pt_mean.*mask),3);
        so_mean_anom_zonal = nanmean((so_mean_anom.*mask),3);
        so_mean_zonal = nanmean((so_mean.*mask),3);
        % Check values
%{
        close all
        figure(2); pcolor(t_lat,t_depth,thetao_mean_anom_zonal); shading flat; axis ij; caxis([-4 4]); title('thetao\_anom'); colorbar; clmap(27)
        figure(3); pcolor(t_lat,t_depth,pt_mean_zonal); shading flat; axis ij; caxis([-3 35]); title('pt\_mean'); colorbar; clmap(27)
        figure(4); pcolor(t_lat,t_depth,so_mean_anom_zonal); shading flat; axis ij; caxis([-.5 .5]); title('so\_anom'); colorbar; clmap(27)
        figure(5); pcolor(t_lat,t_depth,so_mean_zonal); shading flat; axis ij; caxis([33 37]); title('so\_mean'); colorbar; clmap(27)
        set(figure(2),'posi',[20 800 600 400]);
        set(figure(3),'posi',[20 1200 600 400]);
        set(figure(4),'posi',[592 800 600 400]);
        set(figure(5),'posi',[592 1200 600 400]);
        keyboard
        close figure 2
        close figure 3
        close figure 4
        close figure 5
%}

        % Set label xy pairs
        idLab = [-88,4650];
        sVarLab = [94 4650];
        tVarLab = [99 4650];
        basinIdLab = [0,4600];

        % Potential Temperature
        % 0-1000db
        eval(['ax',num2str(axInfo),' = subplot(8,2,',num2str(axInfo),');']);
        [~,h] = contourf(t_lat,t_depth(1:depth1),thetao_mean_anom_zonal(1:depth1,:),50); hold all
        set(h,'linestyle','none'); hold all; clear h
        axis ij, caxis([-1 1]*ptscale(1)), clmap(27), hold all
        contour(t_lat,t_depth(1:depth1),pt_mean_zonal(1:depth1,:),[2.5 7.5 12.5 17.5 22.5 27.5],'k')
        [c,h] = contour(t_lat,t_depth(1:depth1),pt_mean_zonal(1:depth1,:),0:5:30,'k','linewidth',2);
        clabel(c,h,'LabelSpacing',200,'fontsize',fonts_c,'fontweight','bold','color','k')
        contour(t_lat,t_depth(1:depth1),thetao_mean_anom_zonal(1:depth1,:),-ptscale(2):1:ptscale(2),'color',[1 1 1]);
        if ismember(axInfo,[1 5 9 13])
            eval(['ylab',num2str(axInfo),' = ylabel(''Depth (m)'',''fontsize'',fonts);'])
        end
        eval(['axHandle = ax',num2str(axInfo),';'])
        set(axHandle,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
            'ylim',[0 1000],'ytick',0:200:1000,'yticklabel',{'0','200','400','600','800',''},'yminort','on', ...
            'xlim',[-90 90],'xtick',-90:10:90,'xticklabel','','xminort','on');

        % 1000-5000db
        eval(['ax',num2str(axInfo+2),' = subplot(8,2,',num2str(axInfo+2),');']);
        [~,h] = contourf(t_lat,t_depth(depth1:end),thetao_mean_anom_zonal(depth1:end,:),50); hold all
        set(h,'linestyle','none'); hold all; clear h
        axis ij, caxis([-1 1]*ptscale(1)), clmap(27), hold all
        contour(t_lat,t_depth(depth1:end),pt_mean_zonal(depth1:end,:),[2.5 7.5 12.5 17.5 22.5 27.5],'k')
        [c,h] = contour(t_lat,t_depth(depth1:end),pt_mean_zonal(depth1:end,:),0:5:30,'k','linewidth',2);
        clabel(c,h,'LabelSpacing',200,'fontsize',fonts_c,'fontweight','bold','color','k')
        contour(t_lat,t_depth(depth1:end),thetao_mean_anom_zonal(depth1:end,:),-ptscale(2):1:ptscale(2),'color',[1 1 1]);
        text(tVarLab(1),tVarLab(2),'Temperature','fontsize',fonts_lab,'horizontalAlignment','right','color','k','fontweight','b');
        text(idLab(1),idLab(2),basinLabels(1),'fontsize',fonts_lab*1.5,'horizontalAlignment','left','color','k','fontweight','b');
        text(basinIdLab(1),basinIdLab(2),basinId,'fontsize',fonts_lab*1.75,'horizontalAlignment','center','color','k','fontweight','b');
        if basin == 4
            xlab15 = xlabel('Latitude','fontsize',fonts);
            hh1 = colorbarf_nw('horiz',-ptscale(1):0.25:ptscale(1),-ptscale(1):1:ptscale(1));
            set(hh1,'clim',[-ptscale(1) ptscale(1)]); % See https://www.mathworks.com/help/matlab/ref/matlab.graphics.illustration.colorbar-properties.html
        end
        eval(['axHandle = ax',num2str(axInfo+2),';'])
        if basin == 4
            set(axHandle,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
                'ylim',[1000 5000],'ytick',1000:500:5000,'yticklabel',{'1000','','2000','','3000','','4000','','5000'},'yminort','on', ...
                'xlim',[-90 90],'xtick',-90:10:90,'xticklabel',{'90S','','','60S','','','30S','','','EQU','','','30N','','','60N','','','90N'},'xminort','on');
        else
            set(axHandle,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
                'ylim',[1000 5000],'ytick',1000:500:5000,'yticklabel',{'1000','','2000','','3000','','4000','','5000'},'yminort','on', ...
                'xlim',[-90 90],'xtick',-90:10:90,'xticklabel',{''},'xminort','on');
        end

        % Salinity
        % 0-1000db
        eval(['ax',num2str(axInfo+1),' = subplot(8,2,',num2str(axInfo+1),');']);
        [~,h] = contourf(t_lat,t_depth(1:depth1),so_mean_anom_zonal(1:depth1,:),50); hold all
        set(h,'linestyle','none'); hold all; clear h
        axis ij, caxis([-1 1]*sscale(1)), clmap(27), hold all
        contour(t_lat,t_depth(1:depth1),so_mean_zonal(1:depth1,:),scont1,'k')
        [c,h] = contour(t_lat,t_depth(1:depth1),so_mean_zonal(1:depth1,:),scont2,'k','linewidth',2);
        clabel(c,h,'LabelSpacing',200,'fontsize',fonts_c,'fontweight','bold','color','k')
        contour(t_lat,t_depth(1:depth1),so_mean_anom_zonal(1:depth1,:),-sscale(2):0.25:sscale(2),'color',[1 1 1]);
        eval(['axHandle = ax',num2str(axInfo+1),';'])
        set(axHandle,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
            'ylim',[0 1000],'ytick',0:200:1000,'yticklabel',{''},'yminort','on', ...
            'xlim',[-90 90],'xtick',-90:10:90,'xticklabel','','xminort','on');

        % 1000-5000db
        eval(['ax',num2str(axInfo+3),' = subplot(8,2,',num2str(axInfo+3),');']);
        [~,h] = contourf(t_lat,t_depth(depth1:end),so_mean_anom_zonal(depth1:end,:),50); hold all
        set(h,'linestyle','none'); hold all; clear h
        axis ij, caxis([-1 1]*sscale(1)), clmap(27), hold all
        contour(t_lat,t_depth(depth1:end),so_mean_zonal(depth1:end,:),scont1,'k')
        [c,h] = contour(t_lat,t_depth(depth1:end),so_mean_zonal(depth1:end,:),scont2,'k','linewidth',2);
        clabel(c,h,'LabelSpacing',200,'fontsize',fonts_c,'fontweight','bold','color','k')
        contour(t_lat,t_depth(depth1:end),so_mean_anom_zonal(depth1:end,:),-sscale(2):0.25:sscale(2),'color',[1 1 1]);
        text(sVarLab(1),sVarLab(2),'Salinity','fontsize',fonts_lab,'horizontalAlignment','right','color','k','fontweight','b');
        text(idLab(1),idLab(2),basinLabels(2),'fontsize',fonts_lab*1.5,'horizontalAlignment','left','color','k','fontweight','b');
        text(basinIdLab(1),basinIdLab(2),basinId,'fontsize',fonts_lab*1.75,'horizontalAlignment','center','color','k','fontweight','b');
        if basin == 4
            xlab16 = xlabel('Latitude','fontsize',fonts);
            hh2 = colorbarf_nw('horiz',-sscale(1):0.125:sscale(1),-sscale(1):0.25:sscale(1));
            set(hh2,'clim',[-sscale(1) sscale(1)])
        end
        eval(['axHandle = ax',num2str(axInfo+3),';'])
        if basin == 4
            set(axHandle,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
                'ylim',[1000 5000],'ytick',1000:500:5000,'yticklabel',{''},'yminort','on', ...
                'xlim',[-90 90],'xtick',-90:10:90,'xticklabel',{'90S','','','60S','','','30S','','','EQU','','','30N','','','60N','','','90N'},'xminort','on');
        else
            set(axHandle,'Tickdir','out','fontsize',fonts,'layer','top','box','on', ...
                'ylim',[1000 5000],'ytick',1000:500:5000,'yticklabel',{''},'yminort','on', ...
                'xlim',[-90 90],'xtick',-90:10:90,'xticklabel',{''},'xminort','on');
        end
    end

    % Resize into canvas - A4 page 8.26 x 11.69" or 20.98 x 29.69
    set(handle,'Position',[3 3 16.8 23.8]) % Full page width (175mm (17) width x 83mm (8) height) - Back to 16.5 x 6 for proportion
    axHeight = 0.11; axWidth = 0.435;
    %                   x    y     wid  hei
    %set(hh1,'Position',[0.09 0.017 0.41 0.008],'fontsize',fonts);
    set(hh1,'Position',[0.092 0.017 0.41 0.008],'fontsize',fonts);
    set(hh2,'Position',[0.56 0.017 0.41 0.008],'fontsize',fonts);
    rowHeight = 0.06;
    set(ax15,'Position',[0.08 rowHeight axWidth axHeight]);
    set(ax16,'Position',[0.547 rowHeight axWidth axHeight]);
    rowHeight = rowHeight+axHeight+.005; %.175
    set(ax13,'Position',[0.08 rowHeight axWidth axHeight]);
    set(ax14,'Position',[0.547 rowHeight axWidth axHeight]);
    rowHeight = rowHeight+axHeight+.01;%.295
    set(ax11,'Position',[0.08 rowHeight axWidth axHeight]);
    set(ax12,'Position',[0.547 rowHeight axWidth axHeight]);
    rowHeight = rowHeight+axHeight+.005; %.41
    set(ax9,'Position',[0.08 rowHeight axWidth axHeight]);
    set(ax10,'Position',[0.547 rowHeight axWidth axHeight]);
    rowHeight = rowHeight+axHeight+.01; %.530
    set(ax7,'Position',[0.08 rowHeight axWidth axHeight]);
    set(ax8,'Position',[0.547 rowHeight axWidth axHeight]);
    rowHeight = rowHeight+axHeight+.005; %.645
    set(ax5,'Position',[0.08 rowHeight axWidth axHeight]);
    set(ax6,'Position',[0.547 rowHeight axWidth axHeight]);
    rowHeight = rowHeight+axHeight+.01; %.765
    set(ax3,'Position',[0.08 rowHeight axWidth axHeight]);
    set(ax4,'Position',[0.547 rowHeight axWidth axHeight]);
    rowHeight = rowHeight+axHeight+.005; % 0.88
    set(ax1,'Position',[0.08 rowHeight axWidth axHeight]);
    set(ax2,'Position',[0.547 rowHeight axWidth axHeight]);

    % Drop data info into Indian salinity blank
    indVarLab = [90 -3500];
    woaSplit = split(woaDir,'/'); woaStrTmp = strrep(woaSplit(7),'_','\_');
    %disp(['woaStrTmp:',woaStrTmp])
    if contains(woaStrTmp,'81B0')
        woaStr = {'WOA18', ...
                  woaStrTmp, ...
                  '1981-2010'};
    else
        woaStr = {'WOA18', ...
                  woaStrTmp, ...
                  '1955-2017'};
    end
    %disp(['woaStr:',woaStr])
    %disp(['woa:',{'WOA18',woaStr}])
    yax = indVarLab(2);
    for x = 1:length(woaStr)
        yax = yax+500; disp(['yax:',num2str(yax),' ',woaStr{x}])
        text(indVarLab(1),yax,woaStr{x},'fontsize',fonts_ax,'horizontalAlignment','right','color','k','fontweight','b');
    end
    if mipEra == 1
        cmipStr = {'CMIP5', ...
                   ['historical ',cmip5TimePeriod], ...
                   ['thetao: n=',num2str(length(thetao_cmip5_modelNames))], ...
                   ['so: n=',num2str(length(so_cmip5_modelNames))]};
    else
        cmipStr = {'CMIP6', ...
                   ['historical ',cmip6TimePeriod], ...
                   ['thetao: n=',num2str(length(thetao_cmip6_modelNames))], ...
                   ['so: n=',num2str(length(so_cmip6_modelNames))]};
    end
    %disp(['cmip:',cmipStr])
    yax = yax+500;
    for x = 1:length(cmipStr)
        yax = yax+500; disp(['yax:',num2str(yax),' ',cmipStr{x}])
        text(indVarLab(1),yax,cmipStr{x},'fontsize',fonts_ax,'horizontalAlignment','right','color','k','fontweight','b');
    end

    % Drop blanking mask between upper and lower panels
    rowHeight = rowHeight-.004; %.876
    %axr1 = axes('Position',[0.07 rowHeight 0.95 0.003],'xtick',[],'ytick',[],'box','off','visible','on','xcolor',[1 1 1],'ycolor',[1 1 1]);
    axr1 = axes('Position',[0.07 rowHeight+.001 0.95 0.002],'xtick',[],'ytick',[],'box','off','visible','on','xcolor',[1 1 1],'ycolor',[1 1 1]);
    rowHeight = rowHeight-axHeight*2-.015; %.645
    %axr2 = axes('Position',[0.07 rowHeight 0.95 0.003],'xtick',[],'ytick',[],'box','off','visible','on','xcolor',[1 1 1],'ycolor',[1 1 1]);
    axr2 = axes('Position',[0.07 rowHeight+.001 0.95 0.002],'xtick',[],'ytick',[],'box','off','visible','on','xcolor',[1 1 1],'ycolor',[1 1 1]);
    rowHeight = rowHeight-axHeight*2-.015; %.41
    %axr3 = axes('Position',[0.07 rowHeight 0.95 0.003],'xtick',[],'ytick',[],'box','off','visible','on','xcolor',[1 1 1],'ycolor',[1 1 1]);
    axr3 = axes('Position',[0.07 rowHeight+.001 0.95 0.002],'xtick',[],'ytick',[],'box','off','visible','on','xcolor',[1 1 1],'ycolor',[1 1 1]);
    rowHeight = rowHeight-axHeight*2-.015; %.175
    %axr4 = axes('Position',[0.07 rowHeight 0.95 0.003],'xtick',[],'ytick',[],'box','off','visible','on','xcolor',[1 1 1],'ycolor',[1 1 1]);
    axr4 = axes('Position',[0.07 rowHeight+.001 0.95 0.002],'xtick',[],'ytick',[],'box','off','visible','on','xcolor',[1 1 1],'ycolor',[1 1 1]);
                                 %0.875      0.004
    % Axis labels
    xPos = -110; yPos = 1000;
    set(ylab1,'Position',[xPos yPos 1.0001]);
    set(ylab5,'Position',[xPos yPos 1.0001]);
    set(ylab9,'Position',[xPos yPos 1.0001]);
    set(ylab13,'Position',[xPos yPos 1.0001]);
    set(xlab15,'Position',[0 5686 1.0001]);
    set(xlab16,'Position',[0 5686 1.0001]);

    % Print to file
    export_fig([outDir,dateFormat,'_durack1_AR6WG1_Ch3_Fig3p23_',mipEraId,'minusWOA18_thetaoAndso_basin'],'-png')
    export_fig([outDir,dateFormat,'_durack1_AR6WG1_Ch3_Fig3p23_',mipEraId,'minusWOA18_thetaoAndso_basin'],'-eps')

    close all %set(gcf,'visi','on');
    clear ax* c h handle hh* xlab* ylab* mipEra
end %for mipEra
%}

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
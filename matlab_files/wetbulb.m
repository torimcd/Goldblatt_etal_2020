function a = wetbulb(filepath, outfileloc, cam_version)

    % read in CAM output
    T = ncread(filepath,'T');
    lat = ncread(filepath,'lat');
    lon = ncread(filepath,'lon');
    lev = ncread(filepath,'lev');
    time = ncread(filepath,'time');

    % take the zonal mean
    Tmean = nanmean(T,1);
    Tmean = squeeze(Tmean);


    % calculate and plot potential temperature

    % set constants
    R= 287.1;
    cp = 1004;
    p0 = 1e5;

    % unit conversion
    p = lev*100;
    pp = ones(size(lat))*p';

    sigma = Tmean.*(p0./pp).^(R/cp);


    % find and plot wet bulb potential temperature
    % inititalize
    sigmaw = 999*ones(size(sigma));

    % function we will integrate is
    % dTdp = pseudoadiabatig(p,T,Rd,Md,cpd,condensablegas,condensedphase)
    Rd = R;
    cpd = cp;
    Md = 0.02897;

    options = odeset('reltol',1e-6');

    parfor ii = 1:numel(sigmaw)
           pspan = [pp(ii) 1e5];
        if pspan(1) == pspan(2)
            sigmaw(ii) = Tmean(ii);
        else
            To = Tmean(ii);
            [~,Tw] = ode45(@(p,T) pseudoadiabatig(p,T,Rd,Md,cpd,'h2o','l'), pspan,To, options);
            sigmaw(ii) = Tw(end);
        end
    end
    % plot
    figure(12)
    clf


    % write potential temp as nc file

    if strcmp(cam_version,'cam4')
        wbpt_newfile = outfileloc + 'c4_wbpt_10.nc';
    elseif strcmp(cam_version,'cam5')
         wbpt_newfile = outfileloc + 'c5_wbpt_10.nc';
    end
        

    % Open the file
    ncid = netcdf.create([wbpt_newfile],'NC_WRITE');
 
    % Define the dimensions
    dimidlat = netcdf.defDim(ncid,'latitude',96);
    dimidlon = netcdf.defDim(ncid,'lev',26);
 
    % Define IDs for the dimension variables (pressure,time,latitude,...)
    latitude_ID=netcdf.defVar(ncid,'latitude','double',[dimidlat]);
    level_ID=netcdf.defVar(ncid,'lev','double',[dimidlon]);
 
    % Define the main variable ()
    sigmaw_ID = netcdf.defVar(ncid,'sigmaw','double',[dimidlat dimidlon]);
 
    % We are done defining the NetCdf
    netcdf.endDef(ncid);
 
    % Then store the dimension variables
    netcdf.putVar(ncid,latitude_ID,lat);
    netcdf.putVar(ncid,level_ID,lev);
 
    % Then store my main variable
    netcdf.putVar(ncid,sigmaw_ID,sigmaw);
 
    % We're done, close the netcdf
    netcdf.close(ncid)

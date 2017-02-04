function mainfile_xls(infile, outfile, installcost_fname)
    %AUTHOR: BORJA, Shiela Kathleen L.
    %DATE: March 1, 2016
    %DESCRIPTION: read data from file

    %initialize the value for number of solar farms to be installed
    no_solar_farms = 3;
    %no_solar_farms = 4;

    O_and_M=15162; %PHP 15,162,000 - Chinese O&M for 20 years/ 1 MW from OCAMPO

    Y=500; %target energy produced

    %initialize value for efficiency of PV modules-based from SW 245-255 poly
    %series/pro-series
    mu_PV=0.15;
    %initialize value for efficiency of inverters-based from SMA 5000TL-21
    mu_inv=0.97;

    %fileID for the lpx file
    out_fid = fopen(outfile,'w');

    %fileID for the installation cost csv file
    installcost_fid = fopen(installcost_fname,'rt');

    %read input file
    %mat is the matrix containing the numerical data from the csv file
    mat =  xlsread(infile);
    % count the number of feasible installation sites
    r = size(mat(:, 1));
    m = r(1);
    
    %initialize energy array which contains the computed energy of each location
    energy=zeros(r(1),1);
    %global irradiance: W/m^2, area:acre (1 acre=4046.86 m^2)
    %compute the projected energy output of each location
    for i=1:r(1)
        %solar irradiance*F_AREA*m^2*PV efficiency*INV efficiency
        energy(i,1)=(mat(i,4)*(mat(i,2)*4046.86)*mu_PV*mu_inv)/1000000; %MW;
    end
    
    %Construct matrix where data on the factors considered will be stored
    %[ID, SOLAR IRRADIANCE, AREA, DISTANCE FROM ROAD, DISTANCE FROM BU AREA, DISTANCE FROM TRANS LINES]
    A=[mat(:,1),mat(:,4), mat(:,2), mat(:,7), mat(:,13), mat(:,10)];
    
    %create an lpx file 
    %goal 1 -> total energy produced
    fprintf(out_fid, 'max: ');
    for i=1:m
    %fprintf(out_fid,'id=%d, solar_irradiance=%f, area=%f, distance_from _road=%f, distance_from _rural_area=%f,distance_from _trans_lines=%f,distance_from _sub_sta=%f, distance_from _others=%f, distance_from _airport=%f, energy=%f MW \n', A(i,1),A(i,2),A(i,3),A(i,4),A(i,5),A(i,6),A(i,7),A(i,8),A(i,9),energy(i,1));
    if energy(i,1)~=0    
        if (energy(i,1)<0) && (i>1)
            fprintf(out_fid,' - ');
        elseif (energy(i,1)>=0) && (i>1)
            fprintf(out_fid,' + ');
        end
        fprintf(out_fid,'%.4f*x%d',energy(i,1),i);
    end

    end
    fprintf(out_fid, ';\n');

    %goal 2 -> distance from transmission line
    fprintf(out_fid, 'min: ');
    for i=1:m
    %fprintf(out_fid,'id=%d, solar_irradiance=%f, area=%f, distance_from _road=%f, distance_from _rural_area=%f,distance_from _trans_lines=%f,distance_from _sub_sta=%f, distance_from _others=%f, distance_from _airport=%f, energy=%f MW \n', A(i,1),A(i,2),A(i,3),A(i,4),A(i,5),A(i,6),A(i,7),A(i,8),A(i,9),energy(i,1));
    if A(i,6)~=0    
        if (A(i,6)<0) && (i>1)
            fprintf(out_fid,' - ');
        elseif (A(i,6)>=0) && (i>1)
            fprintf(out_fid,' + ');
        end
        fprintf(out_fid,'%.4f*x%d',A(i,6),i);
    end

    end
    fprintf(out_fid, ';\n');

    %goal 3 -> distance from road
    fprintf(out_fid, 'min: ');
    for i=1:m
    %fprintf(out_fid,'id=%d, solar_irradiance=%f, area=%f, distance_from _road=%f, distance_from _rural_area=%f,distance_from _trans_lines=%f,distance_from _sub_sta=%f, distance_from _others=%f, distance_from _airport=%f, energy=%f MW \n', A(i,1),A(i,2),A(i,3),A(i,4),A(i,5),A(i,6),A(i,7),A(i,8),A(i,9),energy(i,1));
    if A(i,4)~=0    
        if (A(i,4)<0) && (i>1)
            fprintf(out_fid,' - ');
        elseif (A(i,4)>=0) && (i>1)
            fprintf(out_fid,' + ');
        end
        fprintf(out_fid,'%.4f*x%d',A(i,4),i);
    end

    end
    fprintf(out_fid, ';\n');

    %goal 4 -> distance from built-up areas
    fprintf(out_fid, 'max: ');
    for i=1:m
    %fprintf(out_fid,'id=%d, solar_irradiance=%f, area=%f, distance_from _road=%f, distance_from _rural_area=%f,distance_from _trans_lines=%f,distance_from _sub_sta=%f, distance_from _others=%f, distance_from _airport=%f, energy=%f MW \n', A(i,1),A(i,2),A(i,3),A(i,4),A(i,5),A(i,6),A(i,7),A(i,8),A(i,9),energy(i,1));
    if A(i,5)~=0    
        if (A(i,5)<0) && (i>1)
            fprintf(out_fid,' - ');
        elseif (A(i,5)>=0) && (i>1)
            fprintf(out_fid,' + ');
        end
        fprintf(out_fid,'%.4f*x%d',A(i,5),i);
    end

    end
    fprintf(out_fid, ';\n');



    %goal 5 -> installation cost
    [data]=textscan(installcost_fid, '%d %f', 'headerlines', 1, 'delimiter', ',', 'TreatAsEmpty', 'NA', 'EmptyValue', NaN);
    mat = {data{1},data{2}};
    r=size(data{1});
    fclose(installcost_fid);

    %initialize matrix A which contains the data for each feasible location
    A=zeros(r(1),2);
    [m,n]=size(A);
    
    %store values to matrix
    for i=1:m
       for j=1:n
            A(i,j)=mat{1,j}(i,1);
       end
    end
    
    fprintf(out_fid, 'min: ');
    for i=1:m
    if A(i,2)~=0    
        if (A(i,2)<0) && (i>1)
            fprintf(out_fid,' - ');
        elseif (A(i,2)>=0) && (i>1)
            fprintf(out_fid,' + ');
        end
        fprintf(out_fid,'%.4f*x%d',A(i,2),i);
    end

    end
    fprintf(out_fid, ';\n');

    %goal 6 -> operations and maintenance cost
    %Operations and Maintenance cost based from Marcial Ocampo's ADV Model
    %for chinese with BOI, 1 MW O&M is PHP 15,162,000 for 20 years

    fprintf(out_fid, 'min: ');
    for i=1:m
    %fprintf(out_fid,'id=%d, solar_irradiance=%f, area=%f, distance_from _road=%f, distance_from _rural_area=%f,distance_from _trans_lines=%f,distance_from _sub_sta=%f, distance_from _others=%f, distance_from _airport=%f, energy=%f MW \n', A(i,1),A(i,2),A(i,3),A(i,4),A(i,5),A(i,6),A(i,7),A(i,8),A(i,9),energy(i,1));
    if energy(i,1)~=0    
        if (energy(i,1)<0) && (i>1)
            fprintf(out_fid,' - ');
        elseif (energy(i,1)>=0) && (i>1)
            fprintf(out_fid,' + ');
        end
        fprintf(out_fid,'%.4f*x%d',(energy(i,1)*O_and_M)/1000,i); %in Millions
    end

    end
    fprintf(out_fid, ';\n');

    %equality constraint
    fprintf(out_fid, 'c1: ');
    for i=1:m
        fprintf(out_fid, 'x%d',i);
        if i~=m
            fprintf(out_fid, '+');
        end
    end
    fprintf(out_fid, '=%d;\n', no_solar_farms);

    %inequality constraints
    fprintf(out_fid, 'c2: ');
    for i=1:m
    if energy(i,1)~=0    
        if (energy(i,1)<0) && (i>1)
            fprintf(out_fid,' - ');
        elseif (energy(i,1)>=0) && (i>1)
            fprintf(out_fid,' + ');
        end
        fprintf(out_fid,'%.4f*x%d',energy(i,1),i);
    end

    end
    fprintf(out_fid, '>=%d;\n', Y);

    for i=1:m
        fprintf(out_fid, 'c%d: x%d>=0;\n', (2*i)+1, i);
        fprintf(out_fid, 'c%d: x%d<=1;\n', (2*i)+2, i);
    end
    %integer constraint
    fprintf(out_fid, 'int ');
    for i=1:m
        fprintf(out_fid, 'x%d',i);
        if i~=m
            fprintf(out_fid, ',');
        end
    end
    fprintf(out_fid, ';\n');

    fclose(out_fid);
end
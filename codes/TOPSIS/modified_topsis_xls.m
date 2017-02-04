function modified_topsis_xls(infile, outfile, installcost_fname)
    %AUTHOR: BORJA, Shiela Kathleen L.
    %DATE: AUGUST 27, 2016

    %*****************Load Criteria Values*******************

    %criteria max_min flag
    %0=min
    %1=max
    criteria_min_max_flag=[0,1,0,1,0,0];

    %initialize the value for number of solar farms to be installed
    no_solar_farms = 3;

    %number of criteria
    NUM_CRITERIA=6;

    %initialize value for efficiency of PV modules-based from SW 245-255 poly
    %series/pro-series
    mu_PV=0.15;
    %initialize value for efficiency of inverters-based from SMA 5000TL-21
    mu_inv=0.97;

    O_and_M=15162; %PHP 15,162,000 - Chinese O&M for 20 years/ 1 MW from OCAMPO
    %************************

    %fileID for the installation cost csv file
    installcost_fid = fopen(installcost_fname,'rt');

    %read input file
    %mat is the matrix containing the numerical data from the csv file
    mat =  xlsread(infile);
    % count the number of feasible installation sites
    r = size(mat(:, 1));
    
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
    
    %initialize number of alternatives
    NUM_ALTERNATIVES = r(1);
    
    %initialize matrix which will contain the standardized criterion values
    STD_CRITERIA=zeros(r(1), NUM_CRITERIA);

    %initialize matrix for min and max criteria values
    MINMAX_CRITERIA=zeros(NUM_CRITERIA,2);

    
    %installation cost
    [data]=textscan(installcost_fid, '%d %f', 'headerlines', 1, 'delimiter', ',', 'TreatAsEmpty', 'NA', 'EmptyValue', NaN);
    mat = {data{1},data{2}};
    r=size(data{1});
    fclose(installcost_fid);

    %initialize matrix B which contains the installation cost for each feasible location
    B=zeros(r(1),2);
    [m,n]=size(B);

    %store values to matrix
    for i=1:m
       for j=1:n
            B(i,j)=mat{1,j}(i,1);
       end
       %fprintf('id=%d, installation_cost=PHP %f M\n', B(i,1),B(i,2));
    end
    %initialize matrix C which contains the maintenance cost for each feasible location
    C=zeros(r(1),1);
    m=size(C);

    for i=1:m(1)
        C(i,1)=(energy(i,1)*O_and_M)/1000;
        %fprintf('maintenance cost %d:%f M\n',i,C(i,1));
    end

    %*******************CREATE CRITERIA MATRIX*********************************
    CRITERIA_MAT=[A(:,4),A(:,5),A(:,6),energy,B(:,2),C];

    %***********Standardization of Criteria values******************************
    %determine the minimum and maximum values for each criterion
    for i=1:NUM_CRITERIA
         MINMAX_CRITERIA(i,1)=min(CRITERIA_MAT(:,i)); %MINIMUM CRITERIA VALUE
         MINMAX_CRITERIA(i,2)=max(CRITERIA_MAT(:,i)); %MAXIMUM CRITERIA VALUE
    end
    %determine the standardized value of each criterion
    %Maximum Score Linear scale Transformation:x_ij=x_ij/x_maxj,x_ij=1-(x_ij/x_maxj)
    %STD_CRITERIA

    for i=1:NUM_CRITERIA
        if criteria_min_max_flag(1,i)==1 %criterion is maximized
            STD_CRITERIA(:,i)=CRITERIA_MAT(:,i)./MINMAX_CRITERIA(i,2);
        else %criterion is minimized
            STD_CRITERIA(:,i)=1-(CRITERIA_MAT(:,i)./MINMAX_CRITERIA(i,2));
        end
    end

    %*************************Determination of Criteria Weights****************
    %Pre-computed AHP weights (Linear | Balanced)
    %Distance From Road=0.0961 | 0.1037
    %Distance From Built-up Area=0.099 | 0.1003
    %Distance From Transmission Line=0.1977 | 0.177
    %Total Energy Produced=0.4393 | 0.4219
    %Total Installation Cost=0.1134 | 0.1266
    %Total Maintenance Cost=0.0545 | 0.0706

    %AHP_weights=[0.081,0.123,0.164,0.365,0.184,0.083]; %Consolidated-Linear
    %AHP_weights=[0.106,0.119,0.17,0.319,0.193,0.093]; %Consolidated-Balanced
    %AHP_weights=[0.04,0.03,0.04,0.41,0.34,0.14]; %Sir Bax
    %AHP_weights=[0.10,0.24,0.42,0.17,0.05,0.02]; %Dr. Sanchez-Lozano
    AHP_weights=[0.0961,0.099,0.1977,0.4393,0.1134,0.0545]; %Consolidated-Linear-Final
    %AHP_weights=[0.1037,0.1003,0.177,0.4219,0.1266,0.0706];%Consolidated-Balanced-Final
    %**************************************************************************

    %*****************************TOPSIS METHOD********************************
    %The selected alternative should have the shortest distance to the positive
    %ideal solution and the farthest distance from the negative ideal solution

    WEIGHTED_CRI_MAT=zeros(NUM_ALTERNATIVES,NUM_CRITERIA);
    %Create a weighted Criteria Matrix
    for i=1:NUM_CRITERIA
        WEIGHTED_CRI_MAT(:,i)=STD_CRITERIA(:,i).*AHP_weights(1,i);
    end

    %determine the minimum and maximum values for each weighted standardized criterion
    for i=1:NUM_CRITERIA
         MINMAX_CRITERIA(i,1)=min(WEIGHTED_CRI_MAT(:,i));
         MINMAX_CRITERIA(i,2)=max(WEIGHTED_CRI_MAT(:,i));
    end

    %positive ideal solution: maximum value if maximization, minimum value if minimization
    %negative ideal solution: minimum value if maximization, maximum value if minimization

    PIS=zeros(1,NUM_CRITERIA); %Positive Ideal Solution
    NIS=zeros(1,NUM_CRITERIA); %Negative Ideal Solution

    for i=1:NUM_CRITERIA
        if criteria_min_max_flag(1,i)==1 %criterion is maximized
            PIS(1,i)=MINMAX_CRITERIA(i,2); %MAX
            NIS(1,i)=MINMAX_CRITERIA(i,1); %MIN
        else %criterion is minimized
            PIS(1,i)=MINMAX_CRITERIA(i,1); %MIN
            NIS(1,i)=MINMAX_CRITERIA(i,2); %MAX
        end
    end

    %Euclidean distance approach was used to evaluate the relative closeness of
    %the alternatives to the ideal solution
    %distance of the ith alternative from the positive ideal solution
    %s_i+={Sum from j=1 to n (v_ij-v_+j)^2}^0.5
    %distance of the ith alternative from the negative ideal solution
    %s_i-={Sum from j=1 to n (v_ij-v_-j)^2}^0.5
    %relative closeness to the ideal point
    %ci+=s_i-/(s_i+ + s_i-)
    %where v_ij=criterion_weight*standardized_criterion
    %v_+j=ideal value
    %v_-j=ideal value

    %contains the relative closeness to the ideal point of each alternative
    CIPLUS = zeros(NUM_ALTERNATIVES,1);

    for i=1:NUM_ALTERNATIVES
        temp_plus=0;
        temp_minus=0;
        for j=1:NUM_CRITERIA
            temp_plus=temp_plus+((WEIGHTED_CRI_MAT(i,j)-PIS(1,j))^2);
            temp_minus=temp_minus+((WEIGHTED_CRI_MAT(i,j)-NIS(1,j))^2);
        end
        S_IPLUS=temp_plus^(0.5);
        S_IMINUS=temp_minus^(0.5);
        CIPLUS(i,1)=S_IMINUS/(S_IPLUS+S_IMINUS);
    end

    %determine the locations selected
    tblA = table(A(:,1),CIPLUS,A(:,3),CRITERIA_MAT(:,1),CRITERIA_MAT(:,2),CRITERIA_MAT(:,3),CRITERIA_MAT(:,4),CRITERIA_MAT(:,5),CRITERIA_MAT(:,6),'VariableNames',{'LOCATION_CODE','C_iPLUS','AREA_ACRES','DISTANCE_FROM_ROADS','DISTANCE_FROM_BUILT_UP_AREAS','DISTANCE_FROM_TRANSMISSION_LINES','ENERGY_PRODUCED','INSTALLATION_COST','MAINTENANCE_COST'});
    [tblB, ~] =sortrows(tblA,'C_iPLUS','descend');
    %printf table to file

    writetable(tblB(1:no_solar_farms,:),outfile,'WriteRowNames',true);

    %create a file containing the criteria values
    tblC = table(A(:,1),A(:,3),CRITERIA_MAT(:,1),CRITERIA_MAT(:,2),CRITERIA_MAT(:,3),CRITERIA_MAT(:,4),CRITERIA_MAT(:,5),CRITERIA_MAT(:,6),'VariableNames',{'LOCATION_CODE','AREA_ACRES','DISTANCE_FROM_ROADS','DISTANCE_FROM_BUILT_UP_AREAS','DISTANCE_FROM_TRANSMISSION_LINES','ENERGY_PRODUCED','INSTALLATION_COST','MAINTENANCE_COST'});
    writetable(tblC,'feasible_locations_list.csv','WriteRowNames',true);
end
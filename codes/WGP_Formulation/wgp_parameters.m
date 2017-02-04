%DESCRIPTION: Computes for the normalized AHP weights for the WGP formulation
%INPUTS:num_solar_farm-number of solar farms to be installed
%       Y-target total energy from the solar farm installations
%       TC-installation cost budget
%       TMC-20 year maintenance cost budget
%       AHP_weights-[Distance from Roads;Distance from BU Areas;Distance 
%                   from Transmission Lines;Total Energy;Total Installation
%                   Cost;Total Maintenance Cost]
function wgp_parameters(num_solar_farm, Y, TC, TMC, AHP_weights)

%define constants
NUM_CRITERIA=6;
IDEAL_D_FRM_TL=3000; %meters
IDEAL_D_FRM_ROAD=1000; %meters
IDEAL_D_FRM_BA=500; %meters

%compute for total distances
TOTAL_DIST_FRM_ROAD=num_solar_farm*IDEAL_D_FRM_ROAD;
TOTAL_DIST_FRM_BA=num_solar_farm*IDEAL_D_FRM_BA;
TOTAL_DIST_FRM_TL=num_solar_farm*IDEAL_D_FRM_TL;

%DEFINE LEVEL
LEVEL=[Y;TOTAL_DIST_FRM_TL;TOTAL_DIST_FRM_ROAD;TOTAL_DIST_FRM_BA;TC;TMC];

%DEFINE NORMALIZED WGP WEIGHTS

WGP_weights=zeros(6,1);

for i=1:NUM_CRITERIA
    WGP_weights(i,1)=(AHP_weights(i,1)/LEVEL(i,1))*100;
end
%create a file containing the parameter values
tblC = table(LEVEL,AHP_weights,WGP_weights,'VariableNames',{'LEVEL','AHP_WEIGHTS','WGP_WEIGHTS'});
writetable(tblC,'wgp_parameters_list.csv','WriteRowNames',true);

end
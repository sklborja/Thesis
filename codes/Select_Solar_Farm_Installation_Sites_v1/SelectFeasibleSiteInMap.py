#SelectFeasibleSiteInMap.py
#AUTHOR: Shiela Kathleen Lanuzo Borja
#Usage: SelectFeasibleSiteInMap <Land_Type> <Land_Cover> <Protected_Areas> <Area_of_Interest> <Solar_Irradiation> <Aspect> <Slope> <Geographical_Latitude_Condition> <Built-Up_Areas> <Transmission_Lines> <Roads> <FINAL_OUTPUT_FILE> 

# Import arcpy module
import arcpy
from arcpy import env
from arcpy.sa import *
import os
#Create the Geoprocessor
import arcgisscripting
gp = arcgisscripting.create()
GDB = env.scratchGDB

#enable overwriting output files
env.overwriteOutput = True

# Script arguments
Land_Type = arcpy.GetParameterAsText(0)

Land_Cover = arcpy.GetParameterAsText(1)

Protected_Areas = arcpy.GetParameterAsText(2)

Area_of_Interest = arcpy.GetParameterAsText(3)

Solar_Irradiation = arcpy.GetParameterAsText(4)

Aspect = arcpy.GetParameterAsText(5)

Slope = arcpy.GetParameterAsText(6)

Geographical_Latitude_Condition = arcpy.GetParameterAsText(7)
if Geographical_Latitude_Condition == '#' or not Geographical_Latitude_Condition:
    Geographical_Latitude_Condition = "Value >=12" # provide a default value if unspecified

BuiltUp_Areas = arcpy.GetParameterAsText(8)

Transmission_Lines = arcpy.GetParameterAsText(9)

Roads = arcpy.GetParameterAsText(10)

FINAL_OUTPUT_FILE = arcpy.GetParameterAsText(11)
if FINAL_OUTPUT_FILE == '#' or not FINAL_OUTPUT_FILE:
    FINAL_OUTPUT_FILE = "C:\\Users\\csv_data.xls" # provide a default value if unspecified
# Local variables:
Infeasible_Land_Type = os.path.join(GDB, "inflt")
Infeasible_Land_Cover = os.path.join(GDB, "inflc")
Buffered_Roads = os.path.join(GDB, "buffroads")
Infeasible_Sites = os.path.join(GDB, "infsites")
Initial_Feasible_Locations = os.path.join(GDB, "initfeas")
Solar_Irradiation_values_of_Feasible_Sites = os.path.join(GDB, "solirrfeas")
Flat_and_South_facing_Areas = os.path.join(GDB, "flatsouth")
Slope_of_Flat_and_South_Facing_Areas = os.path.join(GDB, "slopeflatsouth")
Slope_Greater_Than_Geographical_Latitude = os.path.join(GDB, "slopeglat")
Solar_Irradiation_values_of_Feasible_sites_with_slope_greater_than_geographical_latitude = os.path.join(GDB, "solirrslopeglat")
Feasible_Locations_Land_Areas = os.path.join(GDB, "feaslandarea")
aggregated_polygons = os.path.join(GDB, "aggpoly")
aggregated_polygons_table = os.path.join("aggpolytab")
sol_slp_polya = os.path.join(GDB, "solslpploya")
Feasible_Sites_Point = os.path.join(GDB, "feaspoints")
average_solar_irradiation = os.path.join(GDB, "avesolarirrad")
Average_Solar_Irradiation_Values_on_Feasible_Sites = os.path.join(GDB, "avesolirronsites")
Nearest_Roads = os.path.join(GDB, "nearestroads")
Nearest_Trans_Lines = os.path.join(GDB, "nearesttl")
Nearest_BuiltUp_Areas = os.path.join(GDB, "nearestbua")

#Geoprocessing
# Process: Select Infeasible Land Type
arcpy.Select_analysis(Land_Type, Infeasible_Land_Type, "\"CODE\" = '5.4' OR \"CODE\" = 'BU' OR \"CODE\" = 'RIVER' OR \"CODE\" = '1.1' OR \"CODE\" = '2.1'")

# Process: Select Infeasible Land Cover
arcpy.Select_analysis(Land_Cover, Infeasible_Land_Cover, "\"CODE\" = 'Ic' OR \"CODE\" = 'B' OR \"CODE\" = 'Fdc' OR \"CODE\" = 'Ipc' OR \"CODE\" = 'C' OR \"CODE\" = 'Imc' OR \"CODE\" = 'Imo' OR \"CODE\" = 'Ifm' OR \"CODE\" = 'Fm' OR \"CODE\" = 'Fy' OR \"CODE\" = 'Fdo' OR \"CODE\" = 'Nr' OR \"CODE\" = 'S'")

# Process: Buffer both sides of the road
arcpy.Buffer_analysis(Roads, Buffered_Roads, "50 Meters", "FULL", "ROUND", "ALL", "", "PLANAR")

# Process: Union of Infeasible Sites
arcpy.Union_analysis([Infeasible_Land_Type, Infeasible_Land_Cover, Buffered_Roads, Protected_Areas], Infeasible_Sites, "ALL", "", "GAPS")

# Process: Remove Infeasible Sites
arcpy.Erase_analysis(Area_of_Interest, Infeasible_Sites, Initial_Feasible_Locations, "")

# Process: Determine Solar Irradiation values on Feasible Sites
arcpy.gp.ExtractByMask_sa(Solar_Irradiation, Initial_Feasible_Locations, Solar_Irradiation_values_of_Feasible_Sites)

# Process: Select Flat and South-facing Areas
arcpy.gp.ExtractByAttributes_sa(Aspect, "Value = -1 OR (Value >=112.5 AND Value <= 247.5)", Flat_and_South_facing_Areas)

# Process: Determine Slope of Flat and South-Facing Areas
arcpy.gp.ExtractByMask_sa(Slope, Flat_and_South_facing_Areas, Slope_of_Flat_and_South_Facing_Areas)

# Process: Determine Flat and South facing locations with slope greater than geographical latitude
arcpy.gp.ExtractByAttributes_sa(Slope_of_Flat_and_South_Facing_Areas, Geographical_Latitude_Condition, Slope_Greater_Than_Geographical_Latitude)

# Process: Remove Solar irradiation values of infeasible locations
arcpy.gp.ExtractByMask_sa(Solar_Irradiation_values_of_Feasible_Sites, Slope_Greater_Than_Geographical_Latitude, Solar_Irradiation_values_of_Feasible_sites_with_slope_greater_than_geographical_latitude)

# Process: Convert to Integer
Integer_Solar_Irradiation_values = Int(Solar_Irradiation_values_of_Feasible_sites_with_slope_greater_than_geographical_latitude)
Integer_Solar_Irradiation_values.save(os.path.join(GDB, "intsolirr"))

# Process: Divide into Land Areas
arcpy.RasterToPolygon_conversion(Integer_Solar_Irradiation_values, Feasible_Locations_Land_Areas, "NO_SIMPLIFY", "Value")

# Process: Aggregate Polygons
arcpy.AggregatePolygons_cartography(Feasible_Locations_Land_Areas, aggregated_polygons, "1 Meters", "8.9 Acres", "0 SquareMeters", "NON_ORTHOGONAL", "", aggregated_polygons_table)

# Process: Add F_AREA Field
arcpy.AddField_management(aggregated_polygons, "F_AREA", "DOUBLE", "", "", "", "", "NULLABLE", "NON_REQUIRED", "")

# Process: Calculate Field
arcpy.CalculateField_management(aggregated_polygons, "F_AREA", "!shape.area@acres!", "PYTHON", "")

# Process: Feature To Point
arcpy.FeatureToPoint_management(aggregated_polygons, Feasible_Sites_Point, "INSIDE")

# Process: Extract by Mask
arcpy.gp.ExtractByMask_sa(Solar_Irradiation_values_of_Feasible_sites_with_slope_greater_than_geographical_latitude, aggregated_polygons, sol_slp_polya)

# Process: Zonal Statistics
arcpy.gp.ZonalStatistics_sa(aggregated_polygons, "OBJECTID" , sol_slp_polya, average_solar_irradiation, "MEAN", "DATA")

# Process: Extract Values to Points
arcpy.gp.ExtractValuesToPoints_sa(Feasible_Sites_Point, average_solar_irradiation, Average_Solar_Irradiation_Values_on_Feasible_Sites, "NONE", "ALL")
#arcpy.gp.MakeFeatureLayer(os.path.join(GDB, "avesolirronsites"), "tempf")

# Process: Generate Near Table - Roads
arcpy.GenerateNearTable_analysis( Average_Solar_Irradiation_Values_on_Feasible_Sites, Roads , Nearest_Roads, "", "NO_LOCATION", "NO_ANGLE", "CLOSEST", "0", "PLANAR")

# Process: Join Nearest Roads
arcpy.JoinField_management(Average_Solar_Irradiation_Values_on_Feasible_Sites, "OBJECTID", Nearest_Roads, "OBJECTID", "IN_FID;NEAR_FID;NEAR_DIST")

# Process: Rename Road Distance Field
arcpy.AlterField_management(Average_Solar_Irradiation_Values_on_Feasible_Sites, "NEAR_DIST", "NEAR_DIST_FR_ROAD", "", "", "8", "NON_NULLABLE", "false")

# Process: Generate Near Table - Trans Lines
arcpy.GenerateNearTable_analysis(Average_Solar_Irradiation_Values_on_Feasible_Sites, Transmission_Lines, Nearest_Trans_Lines, "", "NO_LOCATION", "NO_ANGLE", "CLOSEST", "0", "PLANAR")

# Process: Join Nearest Trans Lines
arcpy.JoinField_management(Average_Solar_Irradiation_Values_on_Feasible_Sites, "OBJECTID", Nearest_Trans_Lines, "OBJECTID", "IN_FID;NEAR_FID;NEAR_DIST")

# Process: Rename Trans Lines Distance Field
arcpy.AlterField_management(Average_Solar_Irradiation_Values_on_Feasible_Sites, "NEAR_DIST", "NEAR_DIST_FROM_TRANS_LINES", "", "", "8", "NON_NULLABLE", "false")

# Process: Generate Near Table - BU Areas
arcpy.GenerateNearTable_analysis(Average_Solar_Irradiation_Values_on_Feasible_Sites, BuiltUp_Areas, Nearest_BuiltUp_Areas, "", "NO_LOCATION", "NO_ANGLE", "CLOSEST", "0", "PLANAR")

# Process: Join Nearest BU Areas
arcpy.JoinField_management(Average_Solar_Irradiation_Values_on_Feasible_Sites, "OBJECTID", Nearest_BuiltUp_Areas, "OBJECTID", "IN_FID;NEAR_FID;NEAR_DIST")

# Process: Rename BU Areas Distance Field
arcpy.AlterField_management(Average_Solar_Irradiation_Values_on_Feasible_Sites, "NEAR_DIST", "NEAR_DIST_FROM_BU_AREAS", "", "", "8", "NON_NULLABLE", "false")

# Process: Table To Excel
arcpy.TableToExcel_conversion(Average_Solar_Irradiation_Values_on_Feasible_Sites, FINAL_OUTPUT_FILE, "NAME", "CODE")

#Set output Parameters
arcpy.SetParameterAsText(11, FINAL_OUTPUT_FILE)
arcpy.SetParameterAsText(12, aggregated_polygons)
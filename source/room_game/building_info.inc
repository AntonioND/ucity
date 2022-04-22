;###############################################################################
;
;    µCity - City building game for Game Boy Color.
;    Copyright (c) 2017-2018 Antonio Niño Díaz (AntonioND/SkyLyrac)
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
;    Contact: antonio_nd@outlook.com
;
;###############################################################################

    IF !DEF(BUILDING_INFO_INC)
    DEF BUILDING_INFO_INC = 1

;###############################################################################

; Array of pointers to each building information
    EXPORT BUILDING_INFO_POINTERS_ARRAY
BUILDING_INFO_POINTERS_ARRAY_ELEMENT_SIZE EQU 4

; Index of every building
B_Residential    EQU 0
B_Commercial     EQU 1
B_Industrial     EQU 2

B_PoliceDept     EQU 3
B_FireDept       EQU 4
B_Hospital       EQU 5

B_ParkSmall      EQU 6
B_ParkBig        EQU 7
B_Stadium        EQU 8

B_School         EQU 9
B_HighSchool     EQU 10
B_University     EQU 11

B_Museum         EQU 12
B_Library        EQU 13

B_TrainStation   EQU 14
B_Airport        EQU 15

B_PowerPlantCoal    EQU 16
B_PowerPlantOil     EQU 17
B_PowerPlantWind    EQU 18
B_PowerPlantSolar   EQU 19
B_PowerPlantNuclear EQU 20
B_PowerPlantFusion  EQU 21

; Number of buildings. Everything past this are special "meta buildings"
B_BuildingMax    EQU 22

B_None           EQU 22 ; Size is 1x1, which is useful, but it doesn't exist.

B_Road           EQU 23
B_Train          EQU 24
B_PowerLines     EQU 25
B_Port           EQU 26

B_MetabuildingMax EQU 26

B_ResidentialS1A EQU 30
B_ResidentialS1B EQU 31
B_ResidentialS1C EQU 32
B_ResidentialS1D EQU 33
B_ResidentialS2A EQU 34
B_ResidentialS2B EQU 35
B_ResidentialS2C EQU 36
B_ResidentialS2D EQU 37
B_ResidentialS3A EQU 38
B_ResidentialS3B EQU 39
B_ResidentialS3C EQU 40
B_ResidentialS3D EQU 41

B_CommercialS1A EQU 42
B_CommercialS1B EQU 43
B_CommercialS1C EQU 44
B_CommercialS1D EQU 45
B_CommercialS2A EQU 46
B_CommercialS2B EQU 47
B_CommercialS2C EQU 48
B_CommercialS2D EQU 49
B_CommercialS3A EQU 50
B_CommercialS3B EQU 51
B_CommercialS3C EQU 52
B_CommercialS3D EQU 53

B_IndustrialS1A EQU 54
B_IndustrialS1B EQU 55
B_IndustrialS1C EQU 56
B_IndustrialS1D EQU 57
B_IndustrialS2A EQU 58
B_IndustrialS2B EQU 59
B_IndustrialS2C EQU 60
B_IndustrialS2D EQU 61
B_IndustrialS3A EQU 62
B_IndustrialS3B EQU 63
B_IndustrialS3C EQU 64
B_IndustrialS3D EQU 65

B_RadiationGround EQU 66
B_RadiationWater  EQU 67

B_Delete         EQU 255 ; Special type

;###############################################################################

    ENDC ; BUILDING_INFO_INC

;###############################################################################

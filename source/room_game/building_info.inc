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
    DEF BUILDING_INFO_POINTERS_ARRAY_ELEMENT_SIZE EQU 4

    ; Index of every building
    DEF B_Residential    EQU 0
    DEF B_Commercial     EQU 1
    DEF B_Industrial     EQU 2

    DEF B_PoliceDept     EQU 3
    DEF B_FireDept       EQU 4
    DEF B_Hospital       EQU 5

    DEF B_ParkSmall      EQU 6
    DEF B_ParkBig        EQU 7
    DEF B_Stadium        EQU 8

    DEF B_School         EQU 9
    DEF B_HighSchool     EQU 10
    DEF B_University     EQU 11

    DEF B_Museum         EQU 12
    DEF B_Library        EQU 13

    DEF B_TrainStation   EQU 14
    DEF B_Airport        EQU 15

    DEF B_PowerPlantCoal    EQU 16
    DEF B_PowerPlantOil     EQU 17
    DEF B_PowerPlantWind    EQU 18
    DEF B_PowerPlantSolar   EQU 19
    DEF B_PowerPlantNuclear EQU 20
    DEF B_PowerPlantFusion  EQU 21

    ; Number of buildings. Everything past this are special "meta buildings"
    DEF B_BuildingMax    EQU 22

    DEF B_None           EQU 22 ; Size is 1x1, which is useful, but it doesn't exist.

    DEF B_Road           EQU 23
    DEF B_Train          EQU 24
    DEF B_PowerLines     EQU 25
    DEF B_Port           EQU 26

    DEF B_MetabuildingMax EQU 26

    DEF B_ResidentialS1A EQU 30
    DEF B_ResidentialS1B EQU 31
    DEF B_ResidentialS1C EQU 32
    DEF B_ResidentialS1D EQU 33
    DEF B_ResidentialS2A EQU 34
    DEF B_ResidentialS2B EQU 35
    DEF B_ResidentialS2C EQU 36
    DEF B_ResidentialS2D EQU 37
    DEF B_ResidentialS3A EQU 38
    DEF B_ResidentialS3B EQU 39
    DEF B_ResidentialS3C EQU 40
    DEF B_ResidentialS3D EQU 41

    DEF B_CommercialS1A EQU 42
    DEF B_CommercialS1B EQU 43
    DEF B_CommercialS1C EQU 44
    DEF B_CommercialS1D EQU 45
    DEF B_CommercialS2A EQU 46
    DEF B_CommercialS2B EQU 47
    DEF B_CommercialS2C EQU 48
    DEF B_CommercialS2D EQU 49
    DEF B_CommercialS3A EQU 50
    DEF B_CommercialS3B EQU 51
    DEF B_CommercialS3C EQU 52
    DEF B_CommercialS3D EQU 53

    DEF B_IndustrialS1A EQU 54
    DEF B_IndustrialS1B EQU 55
    DEF B_IndustrialS1C EQU 56
    DEF B_IndustrialS1D EQU 57
    DEF B_IndustrialS2A EQU 58
    DEF B_IndustrialS2B EQU 59
    DEF B_IndustrialS2C EQU 60
    DEF B_IndustrialS2D EQU 61
    DEF B_IndustrialS3A EQU 62
    DEF B_IndustrialS3B EQU 63
    DEF B_IndustrialS3C EQU 64
    DEF B_IndustrialS3D EQU 65

    DEF B_RadiationGround EQU 66
    DEF B_RadiationWater  EQU 67

    DEF B_Delete         EQU 255 ; Special type

;###############################################################################

    ENDC ; BUILDING_INFO_INC

;###############################################################################

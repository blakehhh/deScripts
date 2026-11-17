// Control Types
#define CT_STATIC           0
#define CT_BUTTON           1
#define CT_EDIT             2
#define CT_LISTBOX          5
#define CT_STRUCTURED_TEXT  13

// Static Styles
#define ST_LEFT             0x00
#define ST_RIGHT            0x01
#define ST_CENTER           0x02
#define ST_VCENTER          0x0c
#define ST_PICTURE          48
#define ST_BACKGROUND       80

// Dialog Dimensions (Centered)
#define LOCKER_W 0.74
#define LOCKER_H 0.48
#define LOCKER_X (safezoneX + (safezoneW - LOCKER_W) / 2)
#define LOCKER_Y (safezoneY + (safezoneH - LOCKER_H) / 2)
#define TITLE_H  0.038

// Base Classes
class deScripts_RscText {
    access = 0;
    type = CT_STATIC;
    idc = -1;
    style = ST_LEFT;
    colorBackground[] = {0, 0, 0, 0};
    colorText[] = {1, 1, 1, 1};
    colorShadow[] = {0, 0, 0, 0.5};
    font = "RobotoCondensed";
    sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    linespacing = 1;
    shadow = 1;
    text = "";
    fixedWidth = 0;
    x = 0;
    y = 0;
    h = 0.037;
    w = 0.3;
};

class deScripts_RscPicture: deScripts_RscText {
    style = ST_PICTURE;
    colorBackground[] = {0, 0, 0, 0};
    colorText[] = {1, 1, 1, 1};
    shadow = 0;
};

class deScripts_RscStructuredText {
    access = 0;
    type = CT_STRUCTURED_TEXT;
    idc = -1;
    style = 0;
    colorText[] = {1, 1, 1, 1};
    class Attributes {
        font = "RobotoCondensed";
        color = "#ffffff";
        colorLink = "#D09B43";
        align = "left";
        shadow = 1;
    };
    x = 0;
    y = 0;
    h = 0.035;
    w = 0.1;
    text = "";
    size = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    shadow = 1;
};

class deScripts_RscButton {
    access = 0;
    type = CT_BUTTON;
    text = "";
    colorText[] = {1, 1, 1, 1};
    colorDisabled[] = {0.5, 0.5, 0.5, 0.6};
    colorBackground[] = {0.18, 0.22, 0.28, 1};
    colorBackgroundDisabled[] = {0.12, 0.14, 0.17, 0.8};
    colorBackgroundActive[] = {0.26, 0.32, 0.40, 1};
    colorFocused[] = {0.26, 0.32, 0.40, 1};
    colorShadow[] = {0, 0, 0, 0};
    colorBorder[] = {0, 0, 0, 1};
    soundEnter[] = {"\A3\ui_f\data\sound\RscButton\soundEnter", 0.09, 1};
    soundPush[] = {"\A3\ui_f\data\sound\RscButton\soundPush", 0.09, 1};
    soundClick[] = {"\A3\ui_f\data\sound\RscButton\soundClick", 0.09, 1};
    soundEscape[] = {"\A3\ui_f\data\sound\RscButton\soundEscape", 0.09, 1};
    style = ST_CENTER + ST_VCENTER;
    x = 0;
    y = 0;
    w = 0.095589;
    h = 0.039216;
    shadow = 1;
    font = "RobotoCondensed";
    sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.95)";
    offsetX = 0;
    offsetY = 0;
    offsetPressedX = 0.001;
    offsetPressedY = 0.001;
    borderSize = 0;
};

class deScripts_RscButtonAccent: deScripts_RscButton {
    colorBackground[] = {0.75, 0.55, 0.08, 0.95};
    colorBackgroundActive[] = {0.90, 0.70, 0.15, 1.0};
    colorFocused[] = {0.90, 0.70, 0.15, 1.0};
    font = "RobotoCondensedBold";
    sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.05)";
};

class deScripts_RscButtonDanger: deScripts_RscButton {
    colorBackground[] = {0.55, 0.15, 0.15, 0.9};
    colorBackgroundActive[] = {0.75, 0.20, 0.20, 1.0};
    colorFocused[] = {0.75, 0.20, 0.20, 1.0};
};

class deScripts_RscButtonRole: deScripts_RscButton {
    colorBackground[] = {0, 0, 0, 0};
    colorBackgroundDisabled[] = {0, 0, 0, 0};
    colorBackgroundActive[] = {1, 1, 1, 0.15};
    colorFocused[] = {0, 0, 0, 0};
    colorShadow[] = {0, 0, 0, 0};
    borderSize = 0;
};

class deScripts_RscListBox {
    access = 0;
    type = CT_LISTBOX;
    style = 16;
    font = "RobotoCondensed";
    sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.95)";
    rowHeight = 0.035;
    colorText[] = {1, 1, 1, 1};
    colorDisabled[] = {0.5, 0.5, 0.5, 0.6};
    colorScrollbar[] = {0.95, 0.75, 0.15, 1};
    colorSelect[] = {1, 1, 1, 1};
    colorSelect2[] = {1, 1, 1, 1};
    colorSelectBackground[] = {0.75, 0.55, 0.08, 0.95};
    colorSelectBackground2[] = {0.75, 0.55, 0.08, 0.95};
    colorBackground[] = {0.10, 0.12, 0.15, 0.98};
    soundSelect[] = {"\A3\ui_f\data\sound\RscListbox\soundSelect", 0.09, 1};
    autoScrollSpeed = -1;
    autoScrollDelay = 5;
    autoScrollRewind = 0;
    arrowEmpty = "#(argb,8,8,3)color(1,1,1,1)";
    arrowFull = "#(argb,8,8,3)color(1,1,1,1)";
    colorPicture[] = {1, 1, 1, 1};
    colorPictureSelected[] = {1, 1, 1, 1};
    colorPictureDisabled[] = {1, 1, 1, 0.5};
    maxHistoryDelay = 1;
    period = 1.2;
    class ListScrollBar {
        color[] = {1, 1, 1, 0.6};
        colorActive[] = {1, 1, 1, 1};
        colorDisabled[] = {1, 1, 1, 0.3};
        thumb = "\A3\ui_f\data\gui\cfg\scrollbar\thumb_ca.paa";
        arrowEmpty = "\A3\ui_f\data\gui\cfg\scrollbar\arrowEmpty_ca.paa";
        arrowFull = "\A3\ui_f\data\gui\cfg\scrollbar\arrowFull_ca.paa";
        border = "\A3\ui_f\data\gui\cfg\scrollbar\border_ca.paa";
    };
};

class deScripts_RscEdit {
    access = 0;
    type = CT_EDIT;
    style = 0x00;
    font = "RobotoCondensed";
    sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.95)";
    colorText[] = {1, 1, 1, 1};
    colorDisabled[] = {0.5, 0.5, 0.5, 0.6};
    colorSelection[] = {0.75, 0.55, 0.08, 0.7};
    colorBackground[] = {0.06, 0.08, 0.10, 1};
    autocomplete = "";
    text = "";
    shadow = 0;
    canModify = 1;
};

class deScripts_RscLoadoutLocker {
    idd = 19100;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "['onLoad', _this] call deScripts_fnc_loadoutLocker_ui;";

    class ControlsBackground {
        class MainBackground: deScripts_RscText {
            style = ST_BACKGROUND;
            colorBackground[] = {0.11, 0.13, 0.16, 0.95};
            x = LOCKER_X;
            y = LOCKER_Y;
            w = LOCKER_W;
            h = LOCKER_H;
        };

        // Column 1 (Medical Status) Backgrounds
        class MedicalHeader: deScripts_RscText {
            style = ST_LEFT + ST_VCENTER;
            colorBackground[] = {0.14, 0.17, 0.22, 1.0};
            colorText[] = {0.95, 0.75, 0.15, 1.0};
            font = "RobotoCondensedBold";
            sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.95)";
            text = " MEDICAL STATUS";
            x = LOCKER_X + 0.016;
            y = LOCKER_Y + 0.048;
            w = 0.228;
            h = 0.028;
        };

        class MedicalPanel: deScripts_RscText {
            style = ST_BACKGROUND;
            colorBackground[] = {0.14, 0.17, 0.22, 0.5};
            x = LOCKER_X + 0.016;
            y = LOCKER_Y + 0.076;
            w = 0.228;
            h = 0.250;
        };

        // Column 2 (Presets) Backgrounds
        class PresetsHeader: deScripts_RscText {
            style = ST_LEFT + ST_VCENTER;
            colorBackground[] = {0.14, 0.17, 0.22, 1.0};
            colorText[] = {0.95, 0.75, 0.15, 1.0};
            font = "RobotoCondensedBold";
            sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.95)";
            text = " LOADOUT PRESETS";
            x = LOCKER_X + 0.256;
            y = LOCKER_Y + 0.048;
            w = 0.228;
            h = 0.028;
        };

        class PresetsPanel: deScripts_RscText {
            style = ST_BACKGROUND;
            colorBackground[] = {0.14, 0.17, 0.22, 0.5};
            x = LOCKER_X + 0.256;
            y = LOCKER_Y + 0.076;
            w = 0.228;
            h = 0.250;
        };

        // Column 3 (Roles) Backgrounds
        class RolesHeader: deScripts_RscText {
            style = ST_LEFT + ST_VCENTER;
            colorBackground[] = {0.14, 0.17, 0.22, 1.0};
            colorText[] = {0.95, 0.75, 0.15, 1.0};
            font = "RobotoCondensedBold";
            sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.95)";
            text = " SPECIALTY ROLES";
            x = LOCKER_X + 0.496;
            y = LOCKER_Y + 0.048;
            w = 0.228;
            h = 0.028;
        };

        class RolesPanel: deScripts_RscText {
            style = ST_BACKGROUND;
            colorBackground[] = {0.14, 0.17, 0.22, 0.5};
            x = LOCKER_X + 0.496;
            y = LOCKER_Y + 0.076;
            w = 0.228;
            h = 0.250;
        };

        // Bottom Maintenance Backgrounds
        class MaintenanceHeader: deScripts_RscText {
            style = ST_LEFT + ST_VCENTER;
            colorBackground[] = {0.14, 0.17, 0.22, 1.0};
            colorText[] = {0.95, 0.75, 0.15, 1.0};
            font = "RobotoCondensedBold";
            sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.95)";
            text = " FIELD MAINTENANCE & MANAGEMENT";
            x = LOCKER_X + 0.016;
            y = LOCKER_Y + 0.338;
            w = LOCKER_W - 0.032;
            h = 0.028;
        };

        class MaintenancePanel: deScripts_RscText {
            style = ST_BACKGROUND;
            colorBackground[] = {0.14, 0.17, 0.22, 0.5};
            x = LOCKER_X + 0.016;
            y = LOCKER_Y + 0.366;
            w = LOCKER_W - 0.032;
            h = 0.098;
        };
    };

    class Controls {
        class TitleBar: deScripts_RscText {
            idc = 19101;
            style = ST_LEFT + ST_VCENTER;
            colorBackground[] = {0.08, 0.10, 0.12, 1.0};
            colorText[] = {0.95, 0.75, 0.15, 1.0};
            font = "RobotoCondensedBold";
            sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.05)";
            text = " PERSONAL LOADOUT LOCKER";
            x = LOCKER_X;
            y = LOCKER_Y;
            w = LOCKER_W - TITLE_H;
            h = TITLE_H;
        };

        class CloseBtn: deScripts_RscButton {
            idc = 2;
            shortcuts[] = {0x00050000 + 1};
            text = "X";
            style = ST_CENTER + ST_VCENTER;
            colorBackground[] = {0.55, 0.15, 0.15, 0.9};
            colorBackgroundActive[] = {0.85, 0.20, 0.20, 1.0};
            font = "RobotoCondensedBold";
            x = LOCKER_X + LOCKER_W - TITLE_H;
            y = LOCKER_Y;
            w = TITLE_H;
            h = TITLE_H;
            action = "closeDialog 0;";
        };

        // Column 1 (Medical Triage Silhouette) Controls
        class BodyBackground: deScripts_RscPicture {
            idc = 19200;
            text = "\z\ace\addons\medical_gui\data\body_image\background.paa";
            x = LOCKER_X + 0.0675;
            y = LOCKER_Y + 0.082;
            w = 0.125;
            h = 0.200;
        };

        class BodyHead: deScripts_RscPicture {
            idc = 19201;
            text = "\z\ace\addons\medical_gui\data\body_image\head.paa";
            x = LOCKER_X + 0.0675;
            y = LOCKER_Y + 0.082;
            w = 0.125;
            h = 0.200;
        };

        class BodyTorso: deScripts_RscPicture {
            idc = 19202;
            text = "\z\ace\addons\medical_gui\data\body_image\torso.paa";
            x = LOCKER_X + 0.0675;
            y = LOCKER_Y + 0.082;
            w = 0.125;
            h = 0.200;
        };

        class BodyArmLeft: deScripts_RscPicture {
            idc = 19203;
            text = "\z\ace\addons\medical_gui\data\body_image\arm_left.paa";
            x = LOCKER_X + 0.0675;
            y = LOCKER_Y + 0.082;
            w = 0.125;
            h = 0.200;
        };

        class BodyArmRight: deScripts_RscPicture {
            idc = 19204;
            text = "\z\ace\addons\medical_gui\data\body_image\arm_right.paa";
            x = LOCKER_X + 0.0675;
            y = LOCKER_Y + 0.082;
            w = 0.125;
            h = 0.200;
        };

        class BodyLegLeft: deScripts_RscPicture {
            idc = 19205;
            text = "\z\ace\addons\medical_gui\data\body_image\leg_left.paa";
            x = LOCKER_X + 0.0675;
            y = LOCKER_Y + 0.082;
            w = 0.125;
            h = 0.200;
        };

        class BodyLegRight: deScripts_RscPicture {
            idc = 19206;
            text = "\z\ace\addons\medical_gui\data\body_image\leg_right.paa";
            x = LOCKER_X + 0.0675;
            y = LOCKER_Y + 0.082;
            w = 0.125;
            h = 0.200;
        };

        class MedicalStatusText: deScripts_RscStructuredText {
            idc = 19210;
            x = LOCKER_X + 0.021;
            y = LOCKER_Y + 0.276;
            w = 0.218;
            h = 0.032;
            size = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.90)";
            class Attributes {
                font = "RobotoCondensed";
                color = "#ffffff";
                colorLink = "#D09B43";
                align = "center";
                shadow = 1;
            };
        };

        // Field Rations Icons (Top-Right of Medical Panel)
        class ThirstStatus: deScripts_RscPicture {
            idc = 19220;
            text = "\z\ace\addons\field_rations\ui\icon_hud_thirststatus.paa";
            tooltip = "Thirst";
            x = LOCKER_X + 0.180;
            y = LOCKER_Y + 0.090;
            w = 0.022;
            h = 0.028;
        };

        class HungerStatus: deScripts_RscPicture {
            idc = 19221;
            text = "\z\ace\addons\field_rations\ui\icon_hud_hungerstatus.paa";
            tooltip = "Hunger";
            x = LOCKER_X + 0.206;
            y = LOCKER_Y + 0.090;
            w = 0.022;
            h = 0.028;
        };

        // Column 2 (Loadouts) Controls
        class BtnCombatKit: deScripts_RscButton {
            idc = 19110;
            text = "Preset 1";
            x = LOCKER_X + 0.266;
            y = LOCKER_Y + 0.086;
            w = 0.168;
            h = 0.034;
            action = "['equipSlot', [0]] call deScripts_fnc_loadoutLocker_ui;";
        };
        class BgSetSlot0: deScripts_RscText {
            idc = -1;
            style = ST_BACKGROUND;
            colorBackground[] = {0.18, 0.22, 0.28, 1};
            x = LOCKER_X + 0.438;
            y = LOCKER_Y + 0.086;
            w = 0.036;
            h = 0.034;
        };
        class IconSetSlot0: deScripts_RscPicture {
            idc = -1;
            text = "\a3\ui_f\data\GUI\Rsc\RscDisplayArcadeMap\icon_config_ca.paa";
            x = LOCKER_X + 0.447;
            y = LOCKER_Y + 0.091;
            w = 0.018;
            h = 0.024;
        };
        class BtnSetSlot0: deScripts_RscButtonRole {
            idc = 19114;
            text = "";
            tooltip = "Change assigned ACE Arsenal preset for Slot 1";
            x = LOCKER_X + 0.438;
            y = LOCKER_Y + 0.086;
            w = 0.036;
            h = 0.034;
            action = "['openPicker', [0]] call deScripts_fnc_loadoutLocker_ui;";
        };

        class BtnReconKit: deScripts_RscButton {
            idc = 19111;
            text = "Preset 2";
            x = LOCKER_X + 0.266;
            y = LOCKER_Y + 0.126;
            w = 0.168;
            h = 0.034;
            action = "['equipSlot', [1]] call deScripts_fnc_loadoutLocker_ui;";
        };
        class BgSetSlot1: deScripts_RscText {
            idc = -1;
            style = ST_BACKGROUND;
            colorBackground[] = {0.18, 0.22, 0.28, 1};
            x = LOCKER_X + 0.438;
            y = LOCKER_Y + 0.126;
            w = 0.036;
            h = 0.034;
        };
        class IconSetSlot1: deScripts_RscPicture {
            idc = -1;
            text = "\a3\ui_f\data\GUI\Rsc\RscDisplayArcadeMap\icon_config_ca.paa";
            x = LOCKER_X + 0.447;
            y = LOCKER_Y + 0.131;
            w = 0.018;
            h = 0.024;
        };
        class BtnSetSlot1: deScripts_RscButtonRole {
            idc = 19115;
            text = "";
            tooltip = "Change assigned ACE Arsenal preset for Slot 2";
            x = LOCKER_X + 0.438;
            y = LOCKER_Y + 0.126;
            w = 0.036;
            h = 0.034;
            action = "['openPicker', [1]] call deScripts_fnc_loadoutLocker_ui;";
        };

        class BtnCasualKit: deScripts_RscButton {
            idc = 19112;
            text = "Preset 3";
            x = LOCKER_X + 0.266;
            y = LOCKER_Y + 0.166;
            w = 0.168;
            h = 0.034;
            action = "['equipSlot', [2]] call deScripts_fnc_loadoutLocker_ui;";
        };
        class BgSetSlot2: deScripts_RscText {
            idc = -1;
            style = ST_BACKGROUND;
            colorBackground[] = {0.18, 0.22, 0.28, 1};
            x = LOCKER_X + 0.438;
            y = LOCKER_Y + 0.166;
            w = 0.036;
            h = 0.034;
        };
        class IconSetSlot2: deScripts_RscPicture {
            idc = -1;
            text = "\a3\ui_f\data\GUI\Rsc\RscDisplayArcadeMap\icon_config_ca.paa";
            x = LOCKER_X + 0.447;
            y = LOCKER_Y + 0.171;
            w = 0.018;
            h = 0.024;
        };
        class BtnSetSlot2: deScripts_RscButtonRole {
            idc = 19116;
            text = "";
            tooltip = "Change assigned ACE Arsenal preset for Slot 3";
            x = LOCKER_X + 0.438;
            y = LOCKER_Y + 0.166;
            w = 0.036;
            h = 0.034;
            action = "['openPicker', [2]] call deScripts_fnc_loadoutLocker_ui;";
        };

        class BtnSlot4: deScripts_RscButton {
            idc = 19117;
            text = "Preset 4";
            x = LOCKER_X + 0.266;
            y = LOCKER_Y + 0.206;
            w = 0.168;
            h = 0.034;
            action = "['equipSlot', [3]] call deScripts_fnc_loadoutLocker_ui;";
        };
        class BgSetSlot3: deScripts_RscText {
            idc = -1;
            style = ST_BACKGROUND;
            colorBackground[] = {0.18, 0.22, 0.28, 1};
            x = LOCKER_X + 0.438;
            y = LOCKER_Y + 0.206;
            w = 0.036;
            h = 0.034;
        };
        class IconSetSlot3: deScripts_RscPicture {
            idc = -1;
            text = "\a3\ui_f\data\GUI\Rsc\RscDisplayArcadeMap\icon_config_ca.paa";
            x = LOCKER_X + 0.447;
            y = LOCKER_Y + 0.211;
            w = 0.018;
            h = 0.024;
        };
        class BtnSetSlot3: deScripts_RscButtonRole {
            idc = 19118;
            text = "";
            tooltip = "Change assigned ACE Arsenal preset for Slot 4";
            x = LOCKER_X + 0.438;
            y = LOCKER_Y + 0.206;
            w = 0.036;
            h = 0.034;
            action = "['openPicker', [3]] call deScripts_fnc_loadoutLocker_ui;";
        };

        class BtnArsenal: deScripts_RscButtonAccent {
            idc = 19113;
            text = "OPEN TFG ARSENAL";
            x = LOCKER_X + 0.266;
            y = LOCKER_Y + 0.254;
            w = 0.208;
            h = 0.056;
            action = "['openArsenal'] call deScripts_fnc_loadoutLocker_ui;";
        };

        // Column 3 (Roles) Controls
        class BgRoleCLS: deScripts_RscText {
            idc = 19125;
            style = ST_BACKGROUND;
            colorBackground[] = {0.18, 0.22, 0.28, 1};
            x = LOCKER_X + 0.506;
            y = LOCKER_Y + 0.088;
            w = 0.208;
            h = 0.038;
        };
        class BtnRoleCLS: deScripts_RscButtonRole {
            idc = 19120;
            text = "Combat Lifesaver (CLS)";
            x = LOCKER_X + 0.506;
            y = LOCKER_Y + 0.088;
            w = 0.208;
            h = 0.038;
            action = "['setRole', ['CLS']] call deScripts_fnc_loadoutLocker_ui;";
        };

        class BgRoleMedic: deScripts_RscText {
            idc = 19126;
            style = ST_BACKGROUND;
            colorBackground[] = {0.18, 0.22, 0.28, 1};
            x = LOCKER_X + 0.506;
            y = LOCKER_Y + 0.132;
            w = 0.208;
            h = 0.038;
        };
        class BtnRoleMedic: deScripts_RscButtonRole {
            idc = 19121;
            text = "Medic / Doctor";
            x = LOCKER_X + 0.506;
            y = LOCKER_Y + 0.132;
            w = 0.208;
            h = 0.038;
            action = "['setRole', ['Medic']] call deScripts_fnc_loadoutLocker_ui;";
        };

        class BgRoleEngineer: deScripts_RscText {
            idc = 19127;
            style = ST_BACKGROUND;
            colorBackground[] = {0.18, 0.22, 0.28, 1};
            x = LOCKER_X + 0.506;
            y = LOCKER_Y + 0.176;
            w = 0.208;
            h = 0.038;
        };
        class BtnRoleEngineer: deScripts_RscButtonRole {
            idc = 19122;
            text = "Advanced Engineer";
            x = LOCKER_X + 0.506;
            y = LOCKER_Y + 0.176;
            w = 0.208;
            h = 0.038;
            action = "['setRole', ['Engineer']] call deScripts_fnc_loadoutLocker_ui;";
        };

        class BgRoleEOD: deScripts_RscText {
            idc = 19128;
            style = ST_BACKGROUND;
            colorBackground[] = {0.18, 0.22, 0.28, 1};
            x = LOCKER_X + 0.506;
            y = LOCKER_Y + 0.220;
            w = 0.208;
            h = 0.038;
        };
        class BtnRoleEOD: deScripts_RscButtonRole {
            idc = 19123;
            text = "EOD Specialist";
            x = LOCKER_X + 0.506;
            y = LOCKER_Y + 0.220;
            w = 0.208;
            h = 0.038;
            action = "['setRole', ['EOD']] call deScripts_fnc_loadoutLocker_ui;";
        };

        class BtnRoleClear: deScripts_RscButton {
            idc = 19124;
            text = "Remove All Roles";
            x = LOCKER_X + 0.506;
            y = LOCKER_Y + 0.270;
            w = 0.208;
            h = 0.038;
            action = "['setRole', ['clearAll']] call deScripts_fnc_loadoutLocker_ui;";
        };

        // Bottom Maintenance Controls
        class BtnHeal: deScripts_RscButton {
            idc = 19130;
            text = "Full Treatment";
            x = LOCKER_X + 0.026;
            y = LOCKER_Y + 0.386;
            w = 0.220;
            h = 0.058;
            action = "['heal'] call deScripts_fnc_loadoutLocker_ui;";
        };

        class BtnEatDrink: deScripts_RscButton {
            idc = 19131;
            text = "Eat & Drink";
            x = LOCKER_X + 0.260;
            y = LOCKER_Y + 0.386;
            w = 0.220;
            h = 0.058;
            action = "['eatAndDrink'] call deScripts_fnc_loadoutLocker_ui;";
        };

        class BtnAbandon: deScripts_RscButtonDanger {
            idc = 19140;
            text = "Abandon Locker";
            x = LOCKER_X + 0.494;
            y = LOCKER_Y + 0.386;
            w = 0.220;
            h = 0.058;
            action = "['abandonLocker'] call deScripts_fnc_loadoutLocker_ui;";
        };

        // Preset Picker Overlay (Hidden by default)
        class PresetPickerBg: deScripts_RscText {
            idc = 19180;
            style = ST_BACKGROUND;
            colorBackground[] = {0.08, 0.10, 0.13, 0.98};
            x = LOCKER_X + 0.14;
            y = LOCKER_Y + 0.048;
            w = 0.46;
            h = 0.415;
        };
        class PresetPickerTitle: deScripts_RscText {
            idc = 19181;
            style = ST_LEFT + ST_VCENTER;
            colorBackground[] = {0.14, 0.17, 0.22, 1.0};
            colorText[] = {0.95, 0.75, 0.15, 1.0};
            font = "RobotoCondensedBold";
            text = " SELECT ACE ARSENAL PRESET";
            x = LOCKER_X + 0.14;
            y = LOCKER_Y + 0.048;
            w = 0.46;
            h = 0.032;
        };
        class PresetPickerSearch: deScripts_RscEdit {
            idc = 19184;
            tooltip = "Type to filter presets...";
            x = LOCKER_X + 0.15;
            y = LOCKER_Y + 0.088;
            w = 0.44;
            h = 0.030;
            onKeyUp = "['filterPicker'] call deScripts_fnc_loadoutLocker_ui;";
        };
        class PresetPickerList: deScripts_RscListBox {
            idc = 19182;
            x = LOCKER_X + 0.15;
            y = LOCKER_Y + 0.124;
            w = 0.44;
            h = 0.285;
            onLBSelChanged = "['selectPreset', _this] call deScripts_fnc_loadoutLocker_ui;";
        };
        class PresetPickerCancel: deScripts_RscButtonDanger {
            idc = 19183;
            text = "Cancel";
            x = LOCKER_X + 0.29;
            y = LOCKER_Y + 0.418;
            w = 0.16;
            h = 0.036;
            action = "['closePicker'] call deScripts_fnc_loadoutLocker_ui;";
        };
    };
};

#include "..\script_component.hpp";
/*
 * Author: CPL.Brostrom.A and SGT.Argus.J
 * This function write a diary record.
 *
 * Arguments:
 * None
 *
 * Example:
 *  call deScripts_fnc_Doc_CFF
 *
 */

player createDiaryRecord["Chklists",
    ["CALL FOR FIRE",
        "
<img image='deScripts\Data\Images\CFF.jpg' width='367' height='587'/>
        "
    ]
];

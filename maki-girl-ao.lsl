// TODO: add typing animation

list ground_sits = [
    "BLAOeilGSit01_4;feet wiggle",
    "BLAOeilGSit02_4;legs side",
    "BLAOomiGSit03_4;squatting",
    "BLAOeilGSit03_4;sleeping"
];

list ledge_sits = [
    "BLAOeilSit03_4;neutral",
    "BLAOeilSit01_4;side legs",
    "BLAOeilSit02_4;leaning in"
];

float time_between_stands = 30;

list stand_anims = [
    "BLAOeilStand02_3",
    "BLAOeilStand04_3",
    "BLAOeilStand05_3",
    "BLAOeilStand06_3",
    "BLAOeilStand07_3",
    "BLAOeilStand08_3",
    "BLAOeilStand09_3",
    "BLAOomiST01_3",
    "BLAOomiST02_3",
    "BLAOomiST03_3",
    "BLAOomiST04_3",
    "BLAOomiST05_3",
    "BLAOomiST07_3",
    "BLAOomiST08_3",
    "BLAOomiST10_3"
];

integer enabled = TRUE;

integer current_ground_sit;
integer current_ledge_sit;
integer current_stand = -1;

string current_menu;
integer dialog_channel;
integer dialog_listener = -1;
float time_since_last_dialog;

string pair_get_key(string pair) {
    integer delim_index = llSubStringIndex(pair, ";");
    if (delim_index == -1) {
        llOwnerSay("failed to find delim in: " + pair);
        return "";
    }
    return llGetSubString(pair, 0, delim_index - 1);
}

string pair_get_value(string pair) {
    integer delim_index = llSubStringIndex(pair, ";");
    if (delim_index == -1) {
        llOwnerSay("failed to find delim in: " + pair);
        return "";
    }
    return llDeleteSubString(pair, 0, delim_index);
}

list map_get_values(list map_list) {
    list output;
    integer index;
    integer length = llGetListLength(map_list);
    for (; index < length; index++) {
        output += pair_get_value(llList2String(map_list, index));
    }
    return output;
}

integer map_get_index_from_value(list map_list, string value) {
    integer index;
    integer length = llGetListLength(map_list);
    for (; index < length; index++) {
        string needle = pair_get_value(llList2String(map_list, index));
        if (needle == value) {
            return index;
        }
    }
    return -1;
}

update_sitting() {
    llSetAnimationOverride(
        "Sitting",
        pair_get_key(llList2String(ledge_sits, current_ledge_sit))
    );
    llSetAnimationOverride(
        "Sitting on Ground",
        pair_get_key(llList2String(ground_sits, current_ground_sit))
    );
}

next_stand() {
    integer new_stand = (integer)llFrand(llGetListLength(stand_anims));
    if (new_stand == current_stand) {
        next_stand();
        return;
    }

    current_stand = new_stand;

    llSetAnimationOverride(
        "Standing", llList2String(stand_anims, current_stand)
    );
}

set() {
    enabled = TRUE;
    
    // https://wiki.secondlife.com/wiki/LlSetAnimationOverride
    llSetAnimationOverride("Crouching", "BLAOomiCrouching01_4");
    llSetAnimationOverride("CrouchWalking", "BLAOomiCrouchingWalk01_4");
    llSetAnimationOverride("Falling Down", "BLAOomiFall01_4");
    llSetAnimationOverride("Flying", "BLAOomiFly01_4");
    llSetAnimationOverride("FlyingSlow", "BLAOomiFly01_4"); // between hovering and forward flight
    llSetAnimationOverride("Hovering", "BLAOomiHover01_4");
    llSetAnimationOverride("Hovering Down", "BLAOomiFlyDown01_4");
    llSetAnimationOverride("Hovering Up", "BLAOomiFlyUp01_4");
    llSetAnimationOverride("Jumping", "BLAOomiJump01_4");
    llSetAnimationOverride("Landing", "BLAOomiLand01_4");
    llSetAnimationOverride("PreJumping", "BLAOomiPreJump01_4");
    llSetAnimationOverride("Running", "BLAOeilRun01_4");
    update_sitting();
    next_stand();
    llSetAnimationOverride("Standing Up", "BLAOomiStandup01_4"); // big fall
    llSetAnimationOverride("Striding", "BLAOomiFly01_4"); // when stuck
    llSetAnimationOverride("Soft Landing", "BLAOomiLand01_4");
    llSetAnimationOverride("Taking Off", "BLAOomiFlyUp01_4");
    llSetAnimationOverride("Turning Left", "BLAOeilTurnL01_4");
    llSetAnimationOverride("Turning Right", "BLAOeilTurnR01_4");
    // llSetAnimationOverride("Walking", "BLAOomiWalk02_4");
    llSetAnimationOverride("Walking", "BLAOomiWalk04_4"); // cute hands but slouched back
}

unset() {
    enabled = FALSE;
    llResetAnimationOverride("ALL");
}

update_ui() {
    if (enabled) {
        llSetLinkPrimitiveParamsFast(1, [
            PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.7,
            PRIM_TEXTURE, ALL_SIDES, "70621819-40a6-84ee-8484-7749a6ef099e",
            <1,1,1>, <0,0,0>, 0
        ]);
    } else {
        llSetLinkPrimitiveParamsFast(1, [
            PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.7,
            PRIM_TEXTURE, ALL_SIDES, "4ea9d875-8a1f-0cd7-8316-074019003927",
            <1,1,1>, <0,0,0>, 0
        ]);
    }
}

prepare_dialog(string menu) {
    current_menu = menu;
    // we're not using llGetTime for anything else, so might as well reset
    time_since_last_dialog = llGetAndResetTime();
    if (dialog_listener == -1) {
        dialog_listener = llListen(dialog_channel, "", llGetOwner(), "");
    }
}

end_dialog() {
    current_menu = "";
    if (dialog_listener > -1) {
        llListenRemove(dialog_listener);
        dialog_listener = -1;
    }
}

default
{
    state_entry() {
        llRequestPermissions(llGetOwner(), PERMISSION_OVERRIDE_ANIMATIONS);
        llSetTimerEvent(time_between_stands);
        
        // generate dialog channel. recommended by the wiki
        dialog_channel = -1 - (integer)("0x" + llGetSubString((string)llGetKey(), -7, -1));
        
        update_ui();
    }

    attach(key id) {
        if (id) {
            llRequestPermissions(id , PERMISSION_OVERRIDE_ANIMATIONS);
        } else if (llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
            // when detaching
            unset();
        }
    }

    run_time_permissions(integer perms) {
        if (perms & PERMISSION_OVERRIDE_ANIMATIONS) {
            if (enabled) {
                set();
            }
        }
    }

    timer() {
        if (
            dialog_listener > -1 &&
            llGetTime() >= time_since_last_dialog + 59
        ) {
            end_dialog();
            // llOwnerSay("been more than a minute. stop listening");
        }

        if (!enabled) {
            return;
        }

        next_stand();
    }

    touch_start(integer num_detected) {
        integer link = llDetectedLinkNumber(0);
        if (link == 1) {
            if (enabled) {
                unset();
            } else {
                set();
            }
            update_ui();
        } else if (link == 2) {
            prepare_dialog("home");
            llDialog(
                llGetOwner(), "what would you like?", 
                ["ground sit", "ledge sit", "next stand"],
                dialog_channel
            );
        }
    }
    
    listen(integer chan, string name, key id, string msg) {
        if (current_menu == "home") {
            if (msg == "ground sit") {
                prepare_dialog("ground sit");
                llDialog(
                    llGetOwner(), "which ground sit?", 
                    map_get_values(ground_sits), dialog_channel
                );
            } else if (msg == "ledge sit") {
                prepare_dialog("ledge sit");
                llDialog(
                    llGetOwner(), "which ledge sit?", 
                    map_get_values(ledge_sits), dialog_channel
                );
            } else if (msg == "next stand") {
                next_stand();
                llSetTimerEvent(time_between_stands); // reset timer
            }
        } else if (current_menu == "ground sit") {
            integer index = map_get_index_from_value(ground_sits, msg);
            if (index == -1) {
                llOwnerSay("failed to find: " + msg);
                return;
            }
            current_ground_sit = index;
            update_sitting();
            end_dialog();
        } else if (current_menu == "ledge sit") {
            integer index = map_get_index_from_value(ledge_sits, msg);
            if (index == -1) {
                llOwnerSay("failed to find: " + msg);
                return;
            }
            current_ledge_sit = index;
            update_sitting();
            end_dialog();
        }
    }
}
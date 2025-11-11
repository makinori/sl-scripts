// TODO: add typing animation

list GROUND_SITS = [
    "BLAOeilGSit01_4;feet wiggle",
    "BLAOeilGSit02_4;legs side",
    "BLAOomiGSit03_4;squatting",
    "BLAOeilGSit03_4;sleeping"
];

list LEDGE_SITS = [
    "BLAOeilSit03_4;neutral",
    "BLAOeilSit01_4;side legs",
    "BLAOeilSit02_4;leaning in"
];

float TIME_BETWEEN_STANDS = 30;

list STAND_ANIMS = [
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

integer currentGroundSit;
integer currentLedgeSit;
integer currentStand = -1;

string currentMenu;
integer dialogChannel;
integer dialogListener = -1;
float timeSinceLastDialog;

string pairGetKey(string pair) {
    integer delimIndex = llSubStringIndex(pair, ";");
    if (delimIndex == -1) {
        llOwnerSay("failed to find delim in: " + pair);
        return "";
    }
    return llGetSubString(pair, 0, delimIndex - 1);
}

string pairGetValue(string pair) {
    integer delimIndex = llSubStringIndex(pair, ";");
    if (delimIndex == -1) {
        llOwnerSay("failed to find delim in: " + pair);
        return "";
    }
    return llDeleteSubString(pair, 0, delimIndex);
}

list mapGetValues(list mapList) {
    list output;
    integer index;
    integer length = llGetListLength(mapList);
    for (; index < length; index++) {
        output += pairGetValue(llList2String(mapList, index));
    }
    return output;
}

integer mapGetIndexFromValue(list mapList, string value) {
    integer index;
    integer length = llGetListLength(mapList);
    for (; index < length; index++) {
        string needle = pairGetValue(llList2String(mapList, index));
        if (needle == value) {
            return index;
        }
    }
    return -1;
}

updateSitting() {
    llSetAnimationOverride(
        "Sitting",
        pairGetKey(llList2String(LEDGE_SITS, currentLedgeSit))
    );
    llSetAnimationOverride(
        "Sitting on Ground",
        pairGetKey(llList2String(GROUND_SITS, currentGroundSit))
    );
}

nextStand() {
    integer newStand = (integer)llFrand(llGetListLength(STAND_ANIMS));
    if (newStand == currentStand) {
        nextStand();
        return;
    }

    currentStand = newStand;

    llSetAnimationOverride(
        "Standing", llList2String(STAND_ANIMS, currentStand)
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
    updateSitting();
    nextStand();
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

updateUI() {
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

prepareDialog(string menu) {
    currentMenu = menu;
    // we're not using llGetTime for anything else, so might as well reset
    timeSinceLastDialog = llGetAndResetTime();
    if (dialogListener == -1) {
        dialogListener = llListen(dialogChannel, "", llGetOwner(), "");
    }
}

endDialog() {
    currentMenu = "";
    if (dialogListener > -1) {
        llListenRemove(dialogListener);
        dialogListener = -1;
    }
}

default
{
    state_entry() {
        llRequestPermissions(llGetOwner(), PERMISSION_OVERRIDE_ANIMATIONS);
        llSetTimerEvent(TIME_BETWEEN_STANDS);
        
        // generate dialog channel. recommended by the wiki
        dialogChannel = -1 - (integer)("0x" + llGetSubString((string)llGetKey(), -7, -1));
        
        updateUI();
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
            dialogListener > -1 &&
            llGetTime() >= timeSinceLastDialog + 59
        ) {
            endDialog();
            // llOwnerSay("been more than a minute. stop listening");
        }

        if (!enabled) {
            return;
        }

        nextStand();
    }

    touch_start(integer num_detected) {
        integer link = llDetectedLinkNumber(0);
        if (link == 1) {
            if (enabled) {
                unset();
            } else {
                set();
            }
            updateUI();
        } else if (link == 2) {
            prepareDialog("home");
            llDialog(
                llGetOwner(), "what would you like?", 
                ["ground sit", "ledge sit", "next stand"],
                dialogChannel
            );
        }
    }
    
    listen(integer chan, string name, key id, string msg) {
        if (currentMenu == "home") {
            if (msg == "ground sit") {
                prepareDialog("ground sit");
                llDialog(
                    llGetOwner(), "which ground sit?", 
                    mapGetValues(GROUND_SITS), dialogChannel
                );
            } else if (msg == "ledge sit") {
                prepareDialog("ledge sit");
                llDialog(
                    llGetOwner(), "which ledge sit?", 
                    mapGetValues(LEDGE_SITS), dialogChannel
                );
            } else if (msg == "next stand") {
                nextStand();
                llSetTimerEvent(TIME_BETWEEN_STANDS); // reset timer
            }
        } else if (currentMenu == "ground sit") {
            integer index = mapGetIndexFromValue(GROUND_SITS, msg);
            if (index == -1) {
                llOwnerSay("failed to find: " + msg);
                return;
            }
            currentGroundSit = index;
            updateSitting();
            endDialog();
        } else if (currentMenu == "ledge sit") {
            integer index = mapGetIndexFromValue(LEDGE_SITS, msg);
            if (index == -1) {
                llOwnerSay("failed to find: " + msg);
                return;
            }
            currentLedgeSit = index;
            updateSitting();
            endDialog();
        }
    }
}
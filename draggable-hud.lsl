// script is just an example for reference

// add a new linked cube named Handle
// position and scale it on-top of your button
// should be transparent but give it some transparency for testing
// it will scale really large so that touch() can get mouse position

string HANDLE_NAME = "Handle";

integer handleLink;
vector handleSizeBeforeDrag;

vector primStartPos;
vector touchStartPos;

integer isDragging;
integer didDrag;

startDrag() {
    handleSizeBeforeDrag = llList2Vector(
        llGetLinkPrimitiveParams(handleLink, [PRIM_SIZE]), 0
    );
        
    primStartPos = llGetLocalPos();
    touchStartPos = llDetectedTouchPos(0);

    // make big
    llSetLinkPrimitiveParamsFast(handleLink, [
        PRIM_SIZE, <handleSizeBeforeDrag.x, 16, 16>
    ]);

    isDragging = TRUE;
    didDrag = FALSE;
}

stopDrag() {
    llSetLinkPrimitiveParamsFast(handleLink, [
        PRIM_SIZE, handleSizeBeforeDrag
    ]);

    isDragging = FALSE;
}

updateDrag() {
    if (isDragging == FALSE) {
        return;
    }

    vector touchPos = llDetectedTouchPos(0);
    if (touchPos == ZERO_VECTOR) {
        return; // sometimes happens
    }
    
    vector touchOffset = touchPos - touchStartPos;

    llSetLinkPrimitiveParamsFast(LINK_THIS, [
        PRIM_POS_LOCAL, primStartPos + touchOffset
    ]);

    didDrag = TRUE;
}

integer gethandleLinkByName(string name) {
    integer i = llGetNumberOfPrims();
    for (; i >= 0; --i) {
        if (llGetLinkName(i) == name) {
            return i;
        }
    }
    return -1;
}

default {
    touch_start(integer n) {
        integer link = llDetectedLinkNumber(0);
        if (llGetLinkName(link) != HANDLE_NAME) {
            return;
        }
        handleLink = link;
        startDrag(); // even if its just a click
        llResetTime(); // gives us some time to register a click
    }

    touch_end(integer n) {
        stopDrag();

        if (didDrag) {
            return;
        }

        llOwnerSay("clicked");
    }

    touch(integer n)
    {
        // wait 200ms before we start updating in case the user clicks
        if (llGetTime() < 0.2) {
            return;
        }

        updateDrag();
    }
}
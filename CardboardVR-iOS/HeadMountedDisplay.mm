//
//  HeadMountedDisplay.cpp
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-26.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "HeadMountedDisplay.h"

HeadMountedDisplay::HeadMountedDisplay(UIScreen *screen)
{
    this->screen = new ScreenParams(screen);
    this->cardboard = new CardboardDeviceParams();
}

HeadMountedDisplay::HeadMountedDisplay(HeadMountedDisplay *hmd)
{
    this->screen = new ScreenParams(hmd->getScreen());
    this->cardboard = new CardboardDeviceParams(hmd->getCardboard());
}

HeadMountedDisplay::~HeadMountedDisplay()
{
    delete this->screen;
    delete this->cardboard;
}

void HeadMountedDisplay::setScreen(ScreenParams* screen)
{
    if (this->screen != nullptr) {
        delete this->screen;
    }
    this->screen = new ScreenParams(screen);
}

ScreenParams* HeadMountedDisplay::getScreen()
{
    return this->screen;
}

void HeadMountedDisplay::setCardboard(CardboardDeviceParams *cardboard)
{
    if (this->cardboard != nullptr) {
        delete this->cardboard;
    }
    this->cardboard = new CardboardDeviceParams(cardboard);
}

CardboardDeviceParams* HeadMountedDisplay::getCardboard()
{
    return this->cardboard;
}

bool HeadMountedDisplay::equals(HeadMountedDisplay *other)
{
    if (other == nullptr) {
        return false;
    }
    if (other == this) {
        return true;
    }
    return this->getScreen()->equals(other->getScreen()) && this->cardboard->equals(other->cardboard);
}

//Check all equals
//check delete decon
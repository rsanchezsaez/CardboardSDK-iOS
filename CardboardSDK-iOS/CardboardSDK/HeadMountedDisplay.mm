//
//  HeadMountedDisplay.cpp
//  CardboardSDK-iOS
//
//

#include "HeadMountedDisplay.h"

HeadMountedDisplay::HeadMountedDisplay(UIScreen *screen)
{
    _screen = new ScreenParams(screen);
    _cardboard = new CardboardDeviceParams();
}

HeadMountedDisplay::HeadMountedDisplay(HeadMountedDisplay *hmd)
{
    _screen = new ScreenParams(hmd->getScreen());
    _cardboard = new CardboardDeviceParams(hmd->getCardboard());
}

HeadMountedDisplay::~HeadMountedDisplay()
{
    delete _screen;
    delete _cardboard;
}

void HeadMountedDisplay::setScreen(ScreenParams* screen)
{
    if (_screen != nullptr) {
        delete _screen;
    }
    _screen = new ScreenParams(screen);
}

ScreenParams* HeadMountedDisplay::getScreen()
{
    return _screen;
}

void HeadMountedDisplay::setCardboard(CardboardDeviceParams *cardboard)
{
    if (_cardboard != nullptr) {
        delete _cardboard;
    }
    _cardboard = new CardboardDeviceParams(cardboard);
}

CardboardDeviceParams* HeadMountedDisplay::getCardboard()
{
    return _cardboard;
}

bool HeadMountedDisplay::equals(HeadMountedDisplay *other)
{
    if (other == nullptr) {
        return false;
    }
    if (other == this) {
        return true;
    }
    return getScreen()->equals(other->getScreen()) && _cardboard->equals(other->_cardboard);
}

//
//  HeadMountedDisplay.h
//  CardboardSDK-iOS
//
//

#ifndef __CardboardSDK_iOS__HeadMountedDisplay__
#define __CardboardSDK_iOS__HeadMountedDisplay__

#import <UIKit/UIKit.h>
#import "ScreenParams.h"
#import "CardboardDeviceParams.h"

class HeadMountedDisplay
{
  public:
    HeadMountedDisplay(UIScreen *screen);
    HeadMountedDisplay(HeadMountedDisplay *hmd);
    ~HeadMountedDisplay();
    
    void setScreen(ScreenParams* screen);
    ScreenParams* getScreen();
    
    void setCardboard(CardboardDeviceParams *cardboard);
    CardboardDeviceParams* getCardboard();
    
    bool equals(HeadMountedDisplay *other);

  private:
    ScreenParams *_screen;
    CardboardDeviceParams *_cardboard;
};

#endif 

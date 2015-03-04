#ifndef _TRAMPOLINE_UI_ACTIVITYINDICATOR_H_
#define _TRAMPOLINE_UI_ACTIVITYINDICATOR_H_

#import <UIKit/UIKit.h>


@interface ActivityIndicator : UIActivityIndicatorView {}
+ (ActivityIndicator*)Instance;
@end

void    ShowActivityIndicator(UIView* parent, int style);
void    ShowActivityIndicator(UIView* parent);
void    HideActivityIndicator();

#endif // _TRAMPOLINE_UI_ACTIVITYINDICATOR_H_

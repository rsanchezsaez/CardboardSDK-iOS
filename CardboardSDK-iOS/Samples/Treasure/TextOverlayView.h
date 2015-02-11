//
//  TextOverlayView.h
//
//  Created by Ricardo Sánchez-Sáez on 05/02/2015.
//

#include "CBDStereoGLView.h"


@interface TextOverlayView : CBDStereoGLView

- (void)updateTexturesIfNeeded;
- (void)showTitle:(NSString *)title
         messsage:(NSString *)message;
- (void)showTitle:(NSString *)title
         messsage:(NSString *)message
         duration:(NSTimeInterval)duration;

@end

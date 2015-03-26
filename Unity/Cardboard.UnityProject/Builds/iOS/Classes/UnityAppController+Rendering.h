#pragma once

#include "UnityAppController.h"


@interface UnityAppController (Rendering)

- (void)createDisplayLink;
- (void)repaintDisplayLink;

- (void)repaint;

- (void)selectRenderingAPI;
@property (readonly, nonatomic) UnityRenderingAPI	renderingAPI;

@end

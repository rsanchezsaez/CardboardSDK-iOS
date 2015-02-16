//
//  TextOverlayView.m
//  Seene
//
//  Created by Ricardo Sánchez-Sáez on 05/02/2015.
//  Copyright (c) 2015 Obvious Engine. All rights reserved.
//

#import "TextOverlayView.h"


@interface UIView (CBDConstraints)

- (void)addConstraintsWithVisualFormats:(NSArray *)formats
                                options:(NSLayoutFormatOptions)options
                                metrics:(NSDictionary *)metrics
                                  views:(NSDictionary *)views;

- (NSLayoutConstraint *)findConstraintToView:(UIView *)toView
                                        type:(NSLayoutAttribute)type;

@end


@implementation UIView (CBDConstraints)

- (void)addConstraintsWithVisualFormats:(NSArray *)formats
                                options:(NSLayoutFormatOptions)options
                                metrics:(NSDictionary *)metrics
                                  views:(NSDictionary *)views
{
    if ([formats count] > 0)
    {
        NSMutableArray *constraints = [NSMutableArray new];
        for (NSString *format in formats)
        {
            [constraints addObjectsFromArray:
             [NSLayoutConstraint constraintsWithVisualFormat:format
                                                     options:options
                                                     metrics:metrics
                                                       views:views]];
        }
        [self addConstraints:constraints];
    }
}

- (NSLayoutConstraint *)findConstraintToView:(UIView *)toView type:(NSLayoutAttribute)type
{
    NSLayoutConstraint *foundConstraint = nil;
    for (NSLayoutConstraint *constraint in self.constraints)
    {
        if ( (constraint.firstAttribute == type && [constraint.firstItem isEqual:toView])
            || (constraint.secondAttribute == type && [constraint.secondItem isEqual:toView]) )
        {
            foundConstraint = constraint;
            break;
        }
    }
    return foundConstraint;
}

@end



@interface TextOverlayView ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *messageLabel;

@property (nonatomic) NSLayoutConstraint *titleLabelLeading;
@property (nonatomic) NSLayoutConstraint *titleLabelTrailing;
@property (nonatomic) CGFloat titleLabelMargin;

@property (nonatomic) NSLayoutConstraint *messageLabelLeading;
@property (nonatomic) NSLayoutConstraint *messageLabelTrailing;
@property (nonatomic) CGFloat messageLabelMargin;

@property (nonatomic) BOOL texturesNeedUpdate;

@end


@implementation TextOverlayView

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)glContext lock:(NSRecursiveLock *)lock
{
    self = [super initWithFrame:frame context:glContext lock:lock];
    if (!self) { return nil; }
    
    self.titleLabel = [UILabel new];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textColor = [UIColor lightGrayColor];
    self.titleLabel.font = [self.titleLabel.font fontWithSize:15];
    
    self.messageLabel = [UILabel new];
    self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.textColor = [UIColor lightGrayColor];
    self.messageLabel.font = [self.messageLabel.font fontWithSize:10];

    [self addSubview:self.titleLabel];
    [self addSubview:self.messageLabel];

    [self addConstraintsWithVisualFormats:
     @[ @"V:|-topMargin-[titleLabel]-[messageLabel]",
        @"H:|-sideMargin-[titleLabel]-sideMargin-|",
        @"H:|-sideMargin-[messageLabel]-sideMargin-|" ]
                                  options:0
                                  metrics:@{ @"topMargin": @(120),
                                             @"sideMargin": @(52) }
                                    views:@{ @"messageLabel": self.messageLabel,
                                             @"titleLabel": self.titleLabel }];


    self.titleLabelLeading = [self findConstraintToView:self.titleLabel type:NSLayoutAttributeLeading];
    self.titleLabelTrailing = [self findConstraintToView:self.titleLabel type:NSLayoutAttributeTrailing];
    self.titleLabelMargin = self.titleLabelLeading.constant;

    self.messageLabelLeading = [self findConstraintToView:self.messageLabel type:NSLayoutAttributeLeading];
    self.messageLabelTrailing = [self findConstraintToView:self.messageLabel type:NSLayoutAttributeTrailing];
    self.messageLabelMargin = self.messageLabelLeading.constant;
    
    self.titleLabel.hidden = YES;
    self.messageLabel.hidden = YES;
    
    return self;
}

- (void)configureForEye:(CBDEyeType)eyeType
{
    CGFloat minDepthOffset = 0;
    CGFloat depthDelta = 0;
    
    if (eyeType != CBDEyeTypeMonocular)
    {
        minDepthOffset = -22.0f;
        depthDelta = -1.0f;
        // minDepthOffset = -26.0f;
        // depthDelta = -2.0f;
        if (eyeType == CBDEyeTypeRight)
        {
            minDepthOffset = -minDepthOffset;
            depthDelta = -depthDelta;
        }
    }
    
    CGFloat titleDepthOffset = minDepthOffset + depthDelta * 0.0f;
    CGFloat messageDepthOffset = minDepthOffset + depthDelta * 1.0f;

    self.titleLabelLeading.constant = self.titleLabelMargin + titleDepthOffset;
    self.titleLabelTrailing.constant = self.titleLabelMargin - titleDepthOffset;

    self.messageLabelLeading.constant = self.messageLabelMargin + messageDepthOffset;
    self.messageLabelTrailing.constant = self.messageLabelMargin - messageDepthOffset;
}

- (void)updateTexturesIfNeeded
{
    if (self.texturesNeedUpdate)
    {
        [self updateTextures];
        self.texturesNeedUpdate = NO;
    }
}

- (void)updateTextures
{
    [self configureForEye:CBDEyeTypeLeft];
    [self updateGLTextureForEye:CBDEyeTypeLeft];
    [self configureForEye:CBDEyeTypeRight];
    [self updateGLTextureForEye:CBDEyeTypeRight];
}

- (void)showTitle:(NSString *)title messsage:(NSString *)message
{
    [self showTitle:title messsage:message duration:6.0f];
}

- (void)showTitle:(NSString *)title messsage:(NSString *)message duration:(NSTimeInterval)duration
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        self.titleLabel.text = title;
        self.messageLabel.text = message;
        
        self.titleLabel.hidden = NO;
        self.messageLabel.hidden = NO;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(hideLabels)
                                                   object:nil];
        [self performSelector:@selector(hideLabels)
                   withObject:nil
                   afterDelay:duration];
        self.texturesNeedUpdate = YES;
    });
}

- (void)hideLabels
{
    self.titleLabel.hidden = YES;
    self.messageLabel.hidden = YES;
    self.texturesNeedUpdate = YES;
}

@end

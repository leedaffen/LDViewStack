//
//  LDViewStackView.m
//  Yoga
//
//  Created by Lee Daffen on 09/05/2013.
//  Copyright (c) 2013 Lee Daffen. All rights reserved.
//

#import "LDViewStackView.h"


const CGFloat kBorderWidth = 4.0f;
const CGFloat kShadowRadius = 2.0f;
const CGFloat kShadowOpacity = 0.35f;
const CGFloat kShadowOffsetX = 2.0f;
const CGFloat kShadowOffsetY = 2.0f;


float randomRotationAngle() {
    // provides random rotations over an arc -π/36rad to π/36rad (approx. 344 to 16 deg)
    Float32 angle = arc4random()/((pow(2, 32)-1)) * M_PI/36;
    Boolean neg = arc4random()%2<1? false : true;
    
    if (neg)
        angle = 0-angle;
    
    return angle;
}


@interface LDViewStackView()

@property (nonatomic, strong) CALayer *shadowLayer;

@end


@implementation LDViewStackView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        CGRect f = self.frame;
        f.size.width = f.size.width + (2*kBorderWidth);
        f.size.height = f.size.height + (2*kBorderWidth);
        f.origin.x = f.origin.x - kBorderWidth;
        f.origin.y = f.origin.y - kBorderWidth;
        self.frame = f;
        self.backgroundColor = [UIColor whiteColor];
        
        // apply random rotation transform
        self.rotationAngle = randomRotationAngle();
        self.transform = CGAffineTransformRotate(self.transform, self.rotationAngle);
        
        // add a shadow
        if (nil == self.shadowLayer) {
            self.shadowLayer = [CALayer layer];
            self.shadowLayer.frame = self.bounds;
            self.shadowLayer.backgroundColor = [[UIColor whiteColor] CGColor];
            self.shadowLayer.shouldRasterize = YES;
            self.shadowLayer.shadowColor = [[UIColor blackColor] CGColor];
            self.shadowLayer.shadowOffset = CGSizeMake(kShadowOffsetX, kShadowOffsetY);
            self.shadowLayer.shadowRadius = kShadowRadius;
            self.shadowLayer.shadowOpacity = kShadowOpacity;
            self.shadowLayer.shadowPath = CGPathCreateWithRect(self.bounds, nil);
            
            self.layer.masksToBounds = NO;
            [self.layer addSublayer:self.shadowLayer];
        }
        
        // add border
        self.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.layer.borderWidth = kBorderWidth;
    }
    return self;
}

- (void)setDisplayView:(UIView *)displayView {
    if (_displayView != displayView) {
        if (nil != _displayView)
            [self removeDisplayView];
        
        _displayView = displayView;
        CGRect f = _displayView.frame;
        f.origin.x = f.origin.x + kBorderWidth;
        f.origin.y = f.origin.y + kBorderWidth;
        _displayView.frame = f;
        
        [self addSubview:displayView];
    }
}

- (void)removeDisplayView {
    [_displayView removeFromSuperview];
    _displayView = nil;
}

@end


//
//  LDViewStack.m
//  View Stack
//
//  Created by Lee Daffen on 03/05/2013.
//  Copyright (c) 2013 Lee Daffen. All rights reserved.
//

#import "LDViewStack.h"


float randomRotationAngle() {
    // provides random rotations over an arc -π/24rad to π/24rad (approx. 336 to 24 deg)
    Float32 angle = arc4random()/((pow(2, 32)-1)) * M_PI/24;
    Boolean neg = arc4random()%2<1? false : true;
    
    if (neg)
        angle = 0-angle;
    
    return angle;
}


@interface LDViewStack()

@property (nonatomic, assign) NSUInteger countOfItems;
@property (nonatomic, strong) NSMutableArray *views;
@property (nonatomic, strong) NSMutableArray *recycledViews;

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, assign) NSUInteger indexOfTopView;
@property (nonatomic, assign) NSUInteger maxVisibleItems;
@property (nonatomic, assign) CGRect limitRect;

@property (nonatomic, strong) UIPanGestureRecognizer *pan;

@end


@implementation LDViewStack {
    BOOL _dragging;
    BOOL _animating;
}

- (void)initialise {
    self.userInteractionEnabled = YES;
    self.maxVisibleItems = 5;
    
    self.limitRect = CGRectInset(self.bounds, self.bounds.size.width*0.2f, self.bounds.size.height*0.2f);
    
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:self.pan];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self initialise];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self initialise];
    }
    return self;
}

- (UIView *)viewAtIndex:(NSUInteger)index {
    UIView *view = [self.dataSource viewStack:self viewAtIndex:index];
    
    view.layer.shouldRasterize = YES;
    
    // add shadow
    view.layer.shadowColor = UIColor.blackColor.CGColor;
    view.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
    view.layer.shadowOpacity = 0.35f;
    view.layer.shadowRadius = 3.0f;
    
    // add border
    view.layer.borderColor = UIColor.whiteColor.CGColor;
    view.layer.borderWidth = 5.0f;
    
    // apply random rotation transform
    view.transform = CGAffineTransformRotate(view.transform, randomRotationAngle());
    
    return view;
}

- (void)loadDataFromDataSource {
    
    NSUInteger viewCount = MAX(self.countOfItems, self.maxVisibleItems);
    
    self.countOfItems = [self.dataSource numberOfViewsInStack];
    self.views = [NSMutableArray arrayWithCapacity:viewCount];
    self.recycledViews = [NSMutableArray arrayWithCapacity:viewCount];
    
    for (int index=0; index<self.countOfItems; ++index) {
        UIView *view = [self viewAtIndex:index];
        
        if (index < self.maxVisibleItems) {
            [self.views addObject:view];
            [self insertSubview:view atIndex:0];
        } else {
            [self.views addObject:[NSNull null]];
        }
    }
    
    if (self.views.count >= 1) {
        self.topView = self.views[0];
        self.indexOfTopView = 0;
    }
}

- (void)initialiseWithNewDataSource {
    if (nil != self.views) {
        [self.views makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.views removeAllObjects];
        [self.recycledViews removeAllObjects];
    }
    
    [self loadDataFromDataSource];
}

- (CGPoint)bestAnimationPoint {
    CGPoint currentPoint = self.topView.center;
    CGFloat viewWidth = self.topView.bounds.size.width;
    
    CGFloat xIdeal = (currentPoint.x <= self.bounds.size.width/2) ? 0-(viewWidth/2) : self.bounds.size.width+(viewWidth/2);
    CGFloat yIdeal = self.topView.center.y;
    
    return CGPointMake(xIdeal, yIdeal);
}

- (void)recycleView {
    // Increment the index of the top view
    ++self.indexOfTopView;
    
    if (self.indexOfTopView > self.countOfItems)
        self.indexOfTopView = 0;
    
    NSLog(@"index of top view = %i", self.indexOfTopView);
    
    // Starting at the top index, iterate over the next few items
    // If any of them are NSNull then we need to request a new view from our data source
    for (int index=self.indexOfTopView; index<MIN(index+self.maxVisibleItems,self.views.count); ++index) {
        if (NO == [self.views[index] isKindOfClass:[NSNull class]]) continue;
        NSLog(@"current index = %i", index);
        self.views[index] = [self viewAtIndex:index];
    }
    
    NSMutableArray *temp = [self.views mutableCopy];
    [temp removeObjectAtIndex:0];
    [temp addObject:self.views[0]];
    self.views = temp;
    
    self.topView = self.views[0];
}

- (void)shuffleViewsAnimated:(BOOL)animated newTopView:(BOOL)newTopView {
    _animating = YES;
    
    if (newTopView) {
        [UIView animateWithDuration:animated?self.shuffleAnimationDuration:0 animations:^{
            
            self.topView.center = [self bestAnimationPoint];
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:animated?self.shuffleAnimationDuration:0 animations:^{
                
                self.topView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
                [self sendSubviewToBack:self.topView];
                
            } completion:^(BOOL finished) {
                
                [self recycleView];
                
                if ([self.delegate respondsToSelector:@selector(viewStack:didMoveViewToTopOfStack:withIndex:)])
                    [self.delegate viewStack:self didMoveViewToTopOfStack:self.topView withIndex:(NSUInteger)self.indexOfTopView];
                
                _animating = NO;
                
            }];
            
        }];
    } else {
        [UIView animateWithDuration:animated?self.shuffleAnimationDuration:0 animations:^{
            self.topView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        } completion:^(BOOL finished) {
            _animating = NO;
        }];
    }
}


#pragma mark - actions

- (void)reloadData {
    [self loadDataFromDataSource];
}

- (UIView *)dequeueReusableView {
    if (self.recycledViews.count == 0) return nil;
    
    UIView *viewToRecycle = [self.recycledViews lastObject];
    [self.recycledViews removeObject:viewToRecycle];
    
    return viewToRecycle;
}


#pragma mark - setters/getters

- (void)setDataSource:(id<LDViewStackDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        
        [self initialiseWithNewDataSource];
    }
}

- (CGFloat)shuffleAnimationDuration {
    if (0 == _shuffleAnimationDuration)
        _shuffleAnimationDuration = 0.15f;
    return _shuffleAnimationDuration;
}


#pragma mark - user interaction

- (void)dragView:(UIPanGestureRecognizer *)recognizer {
    CGPoint viewPosition = self.topView.center;
    
    if (_dragging) {
        CGPoint translation = [recognizer translationInView:self];
        
        viewPosition.x += translation.x;
        viewPosition.y += translation.y;
        
        self.topView.center = viewPosition;
        
        [recognizer setTranslation:CGPointZero inView:self];
    } else {
        BOOL isInsideLimit = CGRectContainsPoint(self.limitRect, viewPosition);
        [self shuffleViewsAnimated:YES newTopView:!isInsideLimit];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (_animating) return;
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            _dragging = YES;
            [self dragView:recognizer];
            break;
            
        case UIGestureRecognizerStateChanged:
            [self dragView:recognizer];
            break;
            
        case UIGestureRecognizerStateEnded:
            _dragging = NO;
            [self dragView:recognizer];
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self dragView:recognizer];
            _dragging = NO;
            break;
            
        default:
            break;
    }
}


@end

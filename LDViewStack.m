//
//  LDViewStack.m
//  View Stack
//
//  Created by Lee Daffen on 03/05/2013.
//  Copyright (c) 2013 Lee Daffen. All rights reserved.
//

#import "LDViewStack.h"
#import "LDViewStackView.h"

@interface LDViewStack() <UIGestureRecognizerDelegate>

@property (nonatomic, assign) NSUInteger countOfItems;
@property (nonatomic, strong) NSMutableArray *views;

@property (nonatomic, strong) LDViewStackView *topView;
@property (nonatomic, assign) NSUInteger indexOfTopView;
@property (nonatomic, assign) CGRect limitRect;

@property (nonatomic, weak) UIView *originalParentView;
@property (nonatomic, strong) UIView *temporaryOverlaidContainer;

@property (nonatomic, assign) CGRect originalFrame;
@property (nonatomic, copy) NSArray *originalConstraints;

@end


@implementation LDViewStack {
    BOOL _dragging;
    BOOL _animating;
}

- (void)initialise {
    self.userInteractionEnabled = YES;
    
    self.limitRect = CGRectInset(self.bounds, self.bounds.size.width*0.2f, self.bounds.size.height*0.2f);
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.delegate = self;
    [self addGestureRecognizer:pan];
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

- (void)getDisplayViewForView:(LDViewStackView *)view withIndex:(NSUInteger)index {
    UIView *displayView = [self.dataSource viewStack:self viewAtIndex:index];
    view.displayView = displayView;
}

- (void)loadDataFromDataSource {
    self.countOfItems = [self.dataSource numberOfViewsInStack];
    self.views = [NSMutableArray arrayWithCapacity:self.countOfItems];
    
    for (int index=0; index<self.countOfItems ; ++index) {
        // make a new empty view
        LDViewStackView *view = [[LDViewStackView alloc] initWithFrame:self.bounds];
        view.backgroundColor = [UIColor whiteColor];
        
        if (index < self.maxVisibleItems)
            [self getDisplayViewForView:view withIndex:index];

        [self.views addObject:view];
        
        [self insertSubview:view atIndex:0];
    }
    
    if (self.views.count >= 1) {
        self.topView = self.views[0];
        if ([self.delegate respondsToSelector:@selector(viewStack:didMoveViewToTopOfStack:)])
            [self.delegate viewStack:self didMoveViewToTopOfStack:self.topView.displayView];
    }
}

- (void)reloadData {
    if (nil != self.views) {
        [self.views makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.views removeAllObjects];
        self.indexOfTopView = 0;
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

- (void)recycleViews {
    ++self.indexOfTopView;
    if (self.indexOfTopView >= self.views.count)
        self.indexOfTopView = 0;
    
    NSMutableArray *temp = [self.views mutableCopy];
    [temp removeObjectAtIndex:0];
    [temp addObject:self.views[0]];
    [self.topView removeDisplayView];
    self.views = temp;
    self.topView = self.views[0];
    
    int maxIndex = MIN(self.maxVisibleItems, self.views.count);
    for (int index=0; index<maxIndex; ++index) {
        int indexToRequest = (index+self.indexOfTopView) % self.views.count;
        
        LDViewStackView *view = self.views[index];
        if (nil == view.displayView)
            [self getDisplayViewForView:view withIndex:indexToRequest];
    }
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
                
                [self recycleViews];
                
                if ([self.delegate respondsToSelector:@selector(viewStack:didMoveViewToTopOfStack:)])
                    [self.delegate viewStack:self didMoveViewToTopOfStack:self.topView.displayView];
                
                _animating = NO;
                
                // move ourselves back to our original parent view
                [self moveStackToView:self.originalParentView];                
            }];
            
        }];
    } else {
        [UIView animateWithDuration:animated?self.shuffleAnimationDuration:0 animations:^{
            self.topView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        } completion:^(BOOL finished) {
            _animating = NO;
            
            // move ourselves back to our original parent view
            [self moveStackToView:self.originalParentView];
        }];
    }
}

- (void)moveStackToView:(UIView *)view {
    if (nil == self.overlayParentView) return;
    
    const BOOL autolayout = [self respondsToSelector:@selector(translatesAutoresizingMaskIntoConstraints)];
    
    if (view != self.originalParentView) {
        self.originalParentView = self.superview;
        self.originalFrame = self.frame;
        CGRect f = [self convertRect:self.bounds toView:view];
        self.frame = f;
        if (autolayout) {
            self.originalConstraints = self.constraints;
            [self removeConstraints:self.constraints];
            self.translatesAutoresizingMaskIntoConstraints = YES;
        }
    } else {
        self.frame = self.originalFrame;
        if (autolayout) {
            [self addConstraints:self.originalConstraints];
            self.translatesAutoresizingMaskIntoConstraints = self.constraints == 0;
        }
        [self.temporaryOverlaidContainer removeFromSuperview];
        self.temporaryOverlaidContainer = nil;
    }
    
    [view addSubview:self];
}

#pragma mark - setters/getters

- (NSUInteger)maxVisibleItems {
    if (0 == _maxVisibleItems)
        _maxVisibleItems = 3;
    return _maxVisibleItems;
}

- (void)setDataSource:(id<LDViewStackDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        
        [self reloadData];
    }
}

- (CGFloat)shuffleAnimationDuration {
    if (0 == _shuffleAnimationDuration)
        _shuffleAnimationDuration = 0.15f;
    return _shuffleAnimationDuration;
}

- (UIView *)temporaryOverlaidContainer {
    // make a new overlay view
    if (nil == _temporaryOverlaidContainer && self.overlayParentView) {
        _temporaryOverlaidContainer = [[UIView alloc] initWithFrame:self.overlayParentView.frame];
        _temporaryOverlaidContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.overlayParentView addSubview:_temporaryOverlaidContainer];
    }
    
    return _temporaryOverlaidContainer;
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

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer {
    if (NO == [recognizer isMemberOfClass:[UIPanGestureRecognizer class]]) return YES;
    CGPoint translation = [(UIPanGestureRecognizer *)recognizer translationInView:self];
    
    if (YES == self.preventX)
        return fabs(translation.y) > fabs(translation.x);
        
    if (YES == self.preventY)
        return fabs(translation.x) > fabs(translation.y);
    
    return YES;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    // bail if we're already animating an image or we only have one view
    if (_animating) return;
    if (self.countOfItems < 2) return;
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            _dragging = YES;
            // move ourselves into a new overlay view (the superview should be specified in the implementation)
            [self moveStackToView:self.temporaryOverlaidContainer];
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
            _dragging = NO;
            [self dragView:recognizer];
            break;
            
        default:
            break;
    }
}

@end

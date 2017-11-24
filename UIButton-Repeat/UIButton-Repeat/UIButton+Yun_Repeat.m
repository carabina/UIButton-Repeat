//
// Created by yun on 2017/11/20.
// Copyright (c) 2017 skkj. All rights reserved.
//

#import <objc/runtime.h>
#import "UIButton+Yun_Repeat.h"

@implementation UIButton (Yun_Repeat)

//runtime动态绑定属性
//注意BOOL类型需要用OBJC_ASSOCIATION_RETAIN_NONATOMIC不要用错，否则set方法会赋值出错

- (NSTimeInterval)clickInterval {
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setClickInterval:(NSTimeInterval)clickInterval {
    objc_setAssociatedObject(self, @selector(clickInterval), @(clickInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setIsIgnoreEvent:(BOOL)isIgnoreEvent {
    objc_setAssociatedObject(self, @selector(isIgnoreEvent), @(isIgnoreEvent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isIgnoreEvent {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)disableRepeat {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setDisableRepeat:(BOOL)disableRepeat {
    objc_setAssociatedObject(self, @selector(disableRepeat), @(disableRepeat), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)resetState {
    [self setIsIgnoreEvent:NO];
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selA = @selector(sendAction:to:forEvent:);

        SEL selB = @selector(mySendAction:to:forEvent:);

        Method methodA = class_getInstanceMethod(self, selA);

        Method methodB = class_getInstanceMethod(self, selB);

        //将methodB的实现添加到系统方法中也就是说将methodA方法指针添加成方法methodB的返回值表示是否添加成功
        BOOL isAdd = class_addMethod(self, selA, method_getImplementation(methodB), method_getTypeEncoding(methodB));

        //添加成功了说明本类中不存在methodB所以此时必须将方法b的实现指针换成方法A的，否则b方法将没有实现。
        if (isAdd) {
            class_replaceMethod(self, selB, method_getImplementation(methodA), method_getTypeEncoding(methodA));
        }
        else {
            //添加失败了说明本类中有methodB的实现，此时只需要将methodA和methodB的IMP互换一下即可。
            method_exchangeImplementations(methodA, methodB);
        }
    });
}

//当我们按钮点击事件sendAction时将会执行mySendAction
- (void)mySendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    if (!self.disableRepeat) {
        if ([self isKindOfClass:[UIButton class]]) {
            self.clickInterval = self.clickInterval == 0 ? DefBtnRpTimeItv : self.clickInterval;
            if (self.isIgnoreEvent) {
                return;
            }
            else if (self.clickInterval > 0) {
                [self performSelector:@selector(resetState) withObject:nil afterDelay:self.clickInterval];
            }
        }

        //此处methodA和methodB方法IMP互换了，实际上执行sendAction；所以不会死循环
        self.isIgnoreEvent = YES;
    }

    [self mySendAction:action to:target forEvent:event];
}

@end
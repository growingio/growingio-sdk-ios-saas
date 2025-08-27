//
//  GrowingAnalytics
//  Copyright (C) 2025 Beijing Yishu Technology Co., Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


#import <UIKit/UIKit.h>
#import "MasonryGrowing3rd.h"

@interface GrowingUIViewAutoResizeMask : NSObject
@property (nonatomic, readonly) GrowingUIViewAutoResizeMask *left;
@property (nonatomic, readonly) GrowingUIViewAutoResizeMask *right;
@property (nonatomic, readonly) GrowingUIViewAutoResizeMask *top;
@property (nonatomic, readonly) GrowingUIViewAutoResizeMask *bottom;
@property (nonatomic, readonly) GrowingUIViewAutoResizeMask *width;
@property (nonatomic, readonly) GrowingUIViewAutoResizeMask *heigh;

@property (nonatomic, readonly) GrowingUIViewAutoResizeMask *fullsize;

- (id)set;

@end

@interface UIView (quickLayoutInit)


- (UILabel*)growAddLabelWithFontSize:(NSInteger)fontSize
                               color:(UIColor*)color
                               lines:(NSInteger)lines
                                text:(NSString*)text
                               block:(void(^)(MASG3ConstraintMaker *make,UILabel*lable))block;


- (UITextField*)growAddTextFieldWithFontSize:(NSInteger)fontSize
                                       color:(UIColor*)color
                                 placeHolder:(NSString*)placeHolder
                                  block:(void(^)(MASG3ConstraintMaker *make, UITextField *textField))block;

- (UITextField*)growAddTextFieldWithFontSize:(NSInteger)fontSize
                                       color:(UIColor *)color
                                 placeHolder:(NSString *)placeHolder
                                       inset:(UIEdgeInsets)inset
                                       block:(void (^)(MASG3ConstraintMaker *, UITextField *))block;

- (UIImageView*)growAddImageViewWithImage:(UIImage*)image
                               block:(void(^)(MASG3ConstraintMaker *make, UIImageView *imageView))block;

- (UIImageView*)growAddImageViewWithImageName:(NSString*)imageName
                                   block:(void(^)(MASG3ConstraintMaker *make, UIImageView *imageView))block;

- (UIImageView*)growAddImageViewWithBlock:(void(^)(MASG3ConstraintMaker *make, UIImageView *imageView))block;


- (UIControl*)growAddControlWithBlock:(void(^)(MASG3ConstraintMaker *make, UIControl *control))block;
- (UIControl*)growAddControlWithOnClick:(void(^)(void))onClick
                                  block:(void(^)(MASG3ConstraintMaker *make, UIControl *control))block;


- (UIButton*)growAddButtonWithTitle:(NSString*)title
                              color:(UIColor*)color
                            onClick:(void(^)(void))onClick
                              block:(void(^)(MASG3ConstraintMaker *make, UIButton *button))block;

- (UIButton*)growAddButtonWithAttributedTitle:(NSAttributedString*)title
                                      onClick:(void(^)(void))onClick
                                        block:(void(^)(MASG3ConstraintMaker *make, UIButton *button))block;

- (UIButton*)growAddButtonWithImage:(UIImage*)image
                            onClick:(void(^)(void))onClick
                              block:(void(^)(MASG3ConstraintMaker *make,UIButton *button))block;

- (UIButton*)growAddButtonWithBlock:(void(^)(MASG3ConstraintMaker *make,UIButton *button))block;



- (UIView*)growAddViewWithColor:(UIColor*)color
                          block:(void(^)(MASG3ConstraintMaker *make,UIView *view))block;


- (id)growAddSubviewClass:(Class)classs
                    block:(void(^)(MASG3ConstraintMaker *make,id obj))block;

- (id)growAddSubviewInstance:(UIView *)view
                       block:(void(^)(MASG3ConstraintMaker *make,id obj))block;

- (GrowingUIViewAutoResizeMask*)growingAutoResizeMakeObject;

@end

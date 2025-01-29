//
//  BaseSceneVC.h
//  MediaPlayground
//
//  Created by Viva on 2024/11/20.
//

#import <UIKit/UIKit.h>

@interface BaseSceneVC : UIViewController

- (void)updateTitle:(NSString*)title;
- (void)backAction;// sub class should override to do release

@end

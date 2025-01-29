//
//  BaseSceneVC.m
//  MediaPlayground
//
//  Created by Viva on 2024/11/20.
//

#import "BaseSceneVC.h"

@interface BaseSceneVC ()

@end

@implementation BaseSceneVC

- (void)updateTitle:(NSString *)title {
  self.title = title;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor whiteColor];
  
  UIBarButtonItem* backItem = [[UIBarButtonItem alloc] initWithTitle:@"back" style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
  self.navigationItem.leftBarButtonItems = @[backItem];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
}

- (void)backAction {
  [self.navigationController popViewControllerAnimated:YES];
}

@end

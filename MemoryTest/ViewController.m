//
//  ViewController.m
//  MemoryTest
//
//  Created by huijin on 2018/7/20.
//  Copyright © 2018年 huijin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *totalMemoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *userMemoryLabel;
@property (weak, nonatomic) IBOutlet UIView *allocatedMemoryView;
@property (weak, nonatomic) IBOutlet UIView *kernelMemoryView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)startNewTest:(UIButton *)sender {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

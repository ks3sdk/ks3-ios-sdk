//
//  ViewController.m
//  KS3iOSSDKDemo
//
//  Created by Blues on 12/16/14.
//  Copyright (c) 2014 Blues. All rights reserved.
//

#import "ViewController.h"
#import <KS3YunSDK/KS3YunSDK.h>


@interface ViewController ()

@property (nonatomic, strong) NSArray *arrItems;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"KS3 SDK for iOS Demo";
    self.arrItems = [NSArray arrayWithObjects:@"Service", @"Bucket", @"Object", nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableView datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _arrItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *strIdentifier = @"item identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:strIdentifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strIdentifier];
    }
    cell.textLabel.text = _arrItems[indexPath.row];
    return cell;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *strIdentifier = @"";
    switch (indexPath.row) {
        case 0:
            strIdentifier = @"Service Identifier";
            break;
        case 1:
            strIdentifier = @"Bucket Identifier";
            break;
        case 2:
            strIdentifier = @"Object Identifier";
            break;
        default:
            break;
    }
    [self performSegueWithIdentifier:strIdentifier sender:nil];
}

@end

//
//  ListBucketViewController.m
//  KS3iOSSDKDemo
//
//  Created by Blues on 12/16/14.
//  Copyright (c) 2014 Blues. All rights reserved.
//

#import "ListBucketViewController.h"
#import <KS3YunSDK/KS3YunSDK.h>

@interface ListBucketViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) IBOutlet UITableView *bucketListTable;
@property (nonatomic, strong) NSIndexPath *selectIndexPath;
@property (nonatomic, strong) NSArray *arrBuckets;

@end

@implementation ListBucketViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Bucket列表";
    UIBarButtonItem *addBtnItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                target:self
                                                                                action:@selector(clickAddBucketBtn:)];
    self.navigationItem.rightBarButtonItem = addBtnItem;
    
    _arrBuckets = [[KS3Client initialize] listBuckets];
}

#pragma mark - UITableView datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _arrBuckets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *strIdentifier = @"list bucket identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:strIdentifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strIdentifier];
    }
    KS3Bucket *bucketObj = _arrBuckets[indexPath.row];
    cell.textLabel.text = bucketObj.name;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectIndexPath = indexPath;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Delete"
                                                    otherButtonTitles:@"Edit Canned ACL", nil];
    actionSheet.tag = 100;
    [actionSheet showInView:self.view];
}

- (NSString *)tableView:(NSString *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"More";
}

#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    KS3Bucket *bucketObj = _arrBuckets[_selectIndexPath.row];
    if (actionSheet.tag == 100) {
        switch (buttonIndex) {
            case 0:
            {
                KS3DeleteBucketResponse *response = [[KS3Client initialize] deleteBucketWithName:bucketObj.name];
                if (response.httpStatusCode == 204) { // **** 没有返回任何内容
                    NSLog(@"Delete bucket success!");
                    _arrBuckets = [[KS3Client initialize] listBuckets];
                    [_bucketListTable reloadData];
                }
                else {
                    NSLog(@"Delete bucket error: %@", response.error.description);
                }
            }
                break;
            case 1:
            {
                UIActionSheet *aclActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                            delegate:self
                                                                   cancelButtonTitle:@"Cancel"
                                                              destructiveButtonTitle:nil
                                                                   otherButtonTitles:@"Private", @"Public-Read", @"Public-Read-Write", @"Authenticated-Read", nil];
                aclActionSheet.tag = 101;
                [aclActionSheet showInView:self.view];
            }
                break;
            case 2:
                NSLog(@"Cancel More");
                break;
            default:
                break;
        }
    }
    else if (actionSheet.tag == 101) {
        KingSoftYun_PermissionACLType cannedACLType = KingSoftYun_Permission_Private;
        switch (buttonIndex) {
            case 0:
                cannedACLType = KingSoftYun_Permission_Private;
                break;
            case 1:
                cannedACLType = KingSoftYun_Permission_Public_Read;
                break;
            case 2:
                cannedACLType = KingSoftYun_Permission_Public_Read_Write;
                break;
            case 3:
                cannedACLType = KingSoftYun_Permission_Authenticated_Read;
                break;
            case 4:
                NSLog(@"Cancel ACL Setting");
                break;
            default:
                break;
        }
        KS3SetACLRequest *setACLRequest = [[KS3SetACLRequest alloc] initWithName:bucketObj.name];
        KS3AccessControlList *acl = [[KS3AccessControlList alloc] init];
        [acl setContronAccess:cannedACLType];
        setACLRequest.acl = acl;
        KS3SetACLResponse *response = [[KS3Client initialize] setACL:setACLRequest];
        if (response.httpStatusCode == 200) {
            NSLog(@"Set bucket acl success!");
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"Set bucket acl success!"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        else {
            NSLog(@"Set bucket acl error: %@", response.error.description);
        }
    }
}

#pragma mark - Actions

- (void)clickAddBucketBtn:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Create Bucket"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Create", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *nameField = [alertView textFieldAtIndex:0];
    nameField.placeholder = @"Bucket Name";
    [alertView show];
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        UITextField *nameField = [alertView textFieldAtIndex:0];
        KS3CreateBucketResponse *response = [[KS3Client initialize] createBucketWithName:nameField.text];
        if (response.httpStatusCode == 200) {
            NSLog(@"Create bucket success!");
            _arrBuckets = [[KS3Client initialize] listBuckets];
            [_bucketListTable reloadData];
        }
        else {
            NSLog(@"error: %@", response.error.localizedDescription);
        }
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    UITextField *nameField = [alertView textFieldAtIndex:0];
    if ([nameField.text isEqualToString:@""] == YES) {
        return NO;
    }
    return YES;
}

@end

//
//  ObjectViewController.m
//  KS3iOSSDKDemo
//
//  Created by Blues on 12/17/14.
//  Copyright (c) 2014 Blues. All rights reserved.
//

#warning Please set correct bucket and object name

//Demo下载文件的地址：http://ecloud.kssws.ks-cdn.com/test2/Test.pdf


#define kBucketName @"kssjw"   //下载所用的bucketName
#define kUploadBucketName @"kssjw"   //下载所用的bucketName
#define kDownloadBucketName @"ecloud"//@"alert1"//@"bucketcors"//@"alert1"  //上传所用的bucketName
#define kDownloadBucketKey @"test2/Test.pdf"   //下载的地址拼接
#define kDownloadSize 21131496   //Demo下载文件的大小，根据业务需求，需要记录
#define kObjectName @"Count_1.txt"//@"test_download.txt"//@"bug.txt"
#define kDesBucketName @"kssjw2"//@"ggg"//
#define kDesObjectName @"bug_copy.txt"
#define kObjectSpecial1 @"+-.jpg"
#define kObjectSpecial2 @"+-.txt"


//1 a b  + - * ~ ! @  # ^ :中 ～ 文.jpg
#define kTestSpecial1 @"1 a b  + - * ~ ! @  # ^ & :\"中 ～ 文.jpg"//@"1 a b  + - * ~ ! @  # ^ & :\"中 ～ 文.jpg"
#define kTestSpecial2 @"a 1 b  + - * ~ ! @  # ^ & :\"中 ～ 文"
#define kTestSpecial3 @"+ - b  + - * ~ ! @  # ^ & :\"中 ～ 文"
#define kTestSpecial4 @"  1 a b+ - * ~ ! @  # ^ & :\"中 ～ 文"
#define kTestSpecial5 @"＋ a b  + - * ~ ! @  # ^ & :\"中 ～ 文"
#define kTestSpecial6 @"－ a b  + - * ~ ! @  # ^ & :\"中 ～ 文"
#define kTestSpecial7 @"—— a b  + - * ~ ! @  # ^ & :\"中 ～ 文"
#define kTestSpecial8 @"¥ 1 a b + - * ~ ! @  # ^ & :\"中 ～ 文"
#define kTestSpecial9 @"％ 1 a b + - * ~ ! @  # ^ & :\"中 ～ 文"
#define kTestSpecial10 @"中 ～ 文—— 1 a b  + - * ~ ! @  # ^ & :\"中 ～ 文"

#define mScreenWidth          ([UIScreen mainScreen].bounds.size.width)
#define mScreenHeight         ([UIScreen mainScreen].bounds.size.height)

#import "ObjectViewController.h"
#import <KS3YunSDK/KS3YunSDK.h>
#import "KS3Util.h"
#import "AppDelegate.h"
@interface ObjectViewController () <KingSoftServiceRequestDelegate>
@property (nonatomic, strong) NSArray *arrItems;
@property (nonatomic, strong) KS3DownLoad *downloader;

@property (strong, nonatomic) NSFileHandle *fileHandle;
@property (assign, nonatomic) NSInteger partSize;
@property (assign, nonatomic) long long fileSize;
@property (assign, nonatomic) long long partLength;
@property (nonatomic) NSInteger totalNum;
@property (nonatomic) NSInteger uploadNum;
@property (nonatomic, strong) NSString *bucketName;
@property (strong, nonatomic)  KS3MultipartUpload *muilt;

@end

@implementation ObjectViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Object";
    _arrItems = [NSArray arrayWithObjects:
                 @"Get Object",       @"Delete Object", @"Head Object", @"Put Object", @"Put Object Copy", @"Post Object",
                 @"Get Object ACL",   @"Set Object ACL", @"Set Object Grant ACL",
                 @"Multipart Upload", @"Pause Download", @"Abort Upload", nil];
    UIButton *rightBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 100, 44)];
    [rightBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    rightBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [rightBtn setTitle:@"删除已完成" forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(deleteFinishedFile) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:rightBtn] ;
    
}

- (void)deleteFinishedFile
{
    NSString *strHost = [NSString stringWithFormat:@"http://%@.kss.ksyun.com/%@", kDownloadBucketName, kDownloadBucketKey];
    NSString  *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];;
    //文件临时文件地址，计算百分比
    NSString *  temporaryPath = [filePath stringByAppendingPathComponent: [NSString stringWithFormat:@"%@.%@",[strHost MD5Hash],@"pdf"]];
    if ( [[NSFileManager defaultManager] removeItemAtPath:temporaryPath error:nil]) {
        UIProgressView *progressView = (UIProgressView *)[self.view viewWithTag:99];
        UIButton *stopBtn = (UIButton *)[self.view viewWithTag:100];
        progressView.progress = 0;
        [stopBtn setTitle:@"开始" forState:UIControlStateNormal];
        stopBtn.selected = NO;
    }else
    {
        NSLog(@"移除失败");
    }
    
    
}
#pragma mark TouchEvents
- (void)stopBtnClicked:(UIButton *)btn
{
    if ([btn.titleLabel.text isEqualToString:@"完成"]) {
        NSLog(@"文件下载完成，请删除重试");
        return;
    }
    
    btn.selected =! btn.selected;
    if (btn.selected ) {
        [btn setTitle:@"暂停 " forState:UIControlStateNormal];
        [self beginDownload];
        
    }else
    {
        [btn setTitle:@"继续 " forState:UIControlStateNormal];
        [self stopDownload];
    }
}

/*开始下载，
1.如果本地文件已存在，则下载完成
2.本地文件不存在，从0下载
3.本地有临时下载文件，则从原先进度继续下载
 */
- (void)beginDownload
{
    UIProgressView *progressView = (UIProgressView *)[self.view viewWithTag:99];
    UIButton *stopBtn = (UIButton *)[self.view viewWithTag:100];

    dispatch_queue_t concurrentQueue = dispatch_queue_create("my.concurrent.queue", DISPATCH_QUEUE_SERIAL);

    dispatch_async(concurrentQueue, ^(){
        _downloader = [[KS3Client initialize] downloadObjectWithBucketName:kDownloadBucketName key:kDownloadBucketKey downloadBeginBlock:^(KS3DownLoad *aDownload, NSURLResponse *responseHeaders) {
            NSLog(@"开始下载,responseHeaders:%@",responseHeaders);
        } downloadFileCompleteion:^(KS3DownLoad *aDownload, NSString *filePath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [stopBtn setTitle:@"完成" forState:UIControlStateNormal];
                NSLog(@"completed, file path: %@", filePath);
            });
        } downloadProgressChangeBlock:^(KS3DownLoad *aDownload, double newProgress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressView.progress = newProgress;
                NSLog(@"progress: %f", newProgress);
            });
        } failedBlock:^(KS3DownLoad *aDownload, NSError *error) {
            NSLog(@"failed: %@", error.description);
        }];
        
        // //使用token签名时从Appserver获取token后设置token，使用Ak sk则忽略，不需要调用
        [_downloader setStrKS3Token:[KS3Util KSYAuthorizationWithHTTPVerb:strAccessKey secretKey:strSecretKey httpVerb:_downloader.httpMethod contentMd5:_downloader.contentMd5 contentType:_downloader.contentType date:_downloader.strDate canonicalizedKssHeader:_downloader.kSYHeader canonicalizedResource:_downloader.kSYResource]];
        //                [_downloader setEndPoint:@"kssws.ks-cdn.com"];
        [_downloader start];
        
    });
 

}

//暂停下载，支持断点续传，下次开启程序，进度条的恢复需要计算一下，demo里define kDownloadSize了文件大小
- (void)stopDownload
{
    [_downloader stop];
}

- (void)uploadBtnClicked:(UIButton *)btn
{
    btn.selected =! btn.selected;
    if (btn.selected) {
        [btn setTitle:@"取消" forState:UIControlStateNormal];
        [self beginUpload];
    }else
    {
        [btn setTitle:@"开始" forState:UIControlStateNormal];
        [self cancelUpload];
    }
}

//开始上传
- (void)beginUpload
{
    NSString *strKey = @"testtoken-11.text";//@"+-.txt";
    NSString *strFilePath = [[NSBundle mainBundle] pathForResource:@"bugDownload" ofType:@"txt"];
    _partSize = 5;
    _fileHandle = [NSFileHandle fileHandleForReadingAtPath:strFilePath];
    _fileSize = [_fileHandle availableData].length;
    if (_fileSize <= 0) {
        NSLog(@"####This file is not exist!####");
        return ;
    }
    if (!(_partSize > 0 || _partSize != 0)) {
        _partLength = _fileSize;
    }else{
        _partLength = _partSize * 1024.0 * 1024.0;
    }
    _totalNum = (ceilf((float)_fileSize / (float)_partLength));
    [_fileHandle seekToFileOffset:0];
    
    KS3AccessControlList *acl = [[KS3AccessControlList alloc] init];
    [acl setContronAccess:KingSoftYun_Permission_Private];
    KS3InitiateMultipartUploadRequest *initMultipartUploadReq = [[KS3InitiateMultipartUploadRequest alloc] initWithKey:strKey inBucket:kUploadBucketName acl:acl grantAcl:nil];
    [initMultipartUploadReq setCompleteRequest];
    //使用token签名时从Appserver获取token后设置token，使用Ak sk则忽略，不需要调用
    [initMultipartUploadReq setStrKS3Token:[KS3Util getAuthorization:initMultipartUploadReq]];
    //            [initMultipartUploadReq setEndPointWith:@"kssws.ks-cdn.com"];
    
    _muilt = [[KS3Client initialize] initiateMultipartUploadWithRequest:initMultipartUploadReq];
    if (_muilt == nil) {
        NSLog(@"####Init upload failed, please check access key, secret key and bucket name!####");
        return ;
    }
    
    _uploadNum = 1;
    [self uploadWithPartNumber:_uploadNum];
}

//取消上传，调用abort 接口，终止上传，修改进度条即可
- (void)cancelUpload
{
    if (_muilt == nil) {
        NSLog(@"请先创建上传,再调用Abort");
        return;
    }
    _muilt.isCanceled = YES;
    
    KS3AbortMultipartUploadRequest *request = [[KS3AbortMultipartUploadRequest alloc] initWithMultipartUpload:_muilt];
    [request setCompleteRequest];
    //             使用token签名时从Appserver获取token后设置token，使用Ak sk则忽略，不需要调用
    [request setStrKS3Token:[KS3Util getAuthorization:request]];
    KS3AbortMultipartUploadResponse *response = [[KS3Client initialize] abortMultipartUpload:request];
    NSString *str = [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding];
    if (response.httpStatusCode == 204) {
        NSLog(@"Abort multipart upload success!");
    }
    else {
        NSLog(@"error: %@", response.error.description);
    }
}
#pragma mark - UITableView datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _arrItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *strIdentifier = @"bucket identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:strIdentifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strIdentifier];
        if (indexPath.row == 0) {
            UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(mScreenWidth * .35 , 20, mScreenWidth * .5, 20)];
            progressView.progressViewStyle = UIProgressViewStyleDefault;
            progressView.tag = 99;
            
            //计算下载临时文件的大小,临时文件是经过MD5Hash的文件名
            NSString *strHost = [NSString stringWithFormat:@"http://%@.kss.ksyun.com/%@", kDownloadBucketName, kDownloadBucketKey];
            NSString  *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];;
            //文件临时文件地址，计算百分比
            NSString *  temporaryPath=[filePath stringByAppendingPathComponent: [strHost MD5Hash]];
            NSFileHandle * fileHandle = [NSFileHandle fileHandleForWritingAtPath:temporaryPath];
            unsigned long long   offset = [fileHandle seekToEndOfFile];
            progressView.progress = offset * 1.0 / kDownloadSize;
            [cell.contentView addSubview:progressView];
            
            UIButton *stopBtn = [[UIButton alloc]initWithFrame:CGRectMake(mScreenWidth - 50, 10, 40, 20)];
            [stopBtn setTitle:@"开始" forState:UIControlStateNormal];
            stopBtn.titleLabel.font  = [UIFont systemFontOfSize:14];
            [stopBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
            stopBtn .tag = 100;
            [stopBtn addTarget:self action:@selector(stopBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:stopBtn];

        }
        if (indexPath.row == 9) {
            UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(mScreenWidth * .4 , 20, mScreenWidth * .45, 20)];
            progressView.progressViewStyle = UIProgressViewStyleDefault;
            progressView.tag = 199;
            [cell.contentView addSubview:progressView];
            
            UIButton *uploadBtn = [[UIButton alloc]initWithFrame:CGRectMake(mScreenWidth - 50, 10, 40, 20)];
            [uploadBtn setTitle:@"开始" forState:UIControlStateNormal];
            uploadBtn.titleLabel.font  = [UIFont systemFontOfSize:14];
            [uploadBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
            uploadBtn .tag = 200;
            [uploadBtn addTarget:self action:@selector(uploadBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:uploadBtn];
        }

    }
    cell.textLabel.text = _arrItems[indexPath.row];
    return cell;
}

#pragma mark - UITableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
        {
//            [self beginDownload];
        }
            break;
        case 1:
        {
            KS3DeleteObjectRequest *deleteObjRequest = [[KS3DeleteObjectRequest alloc] initWithName:kBucketName withKeyName:kObjectSpecial1];
            [deleteObjRequest setCompleteRequest];
            [deleteObjRequest setStrKS3Token:[KS3Util getAuthorization:deleteObjRequest]];
            KS3DeleteObjectResponse *response = [[KS3Client initialize] deleteObject:deleteObjRequest];
            if (response.httpStatusCode == 204) {
                NSLog(@"Delete object success!");
            }
            else {
                NSLog(@"Delete object error: %@", response.error.description);
            }
        }
            break;
        case 2:
        {
            KS3HeadObjectRequest *headObjRequest = [[KS3HeadObjectRequest alloc] initWithName:kBucketName withKeyName:kObjectSpecial2];
            [headObjRequest setCompleteRequest];
             //使用token签名时从Appserver获取token后设置token，使用Ak sk则忽略，不需要调用
            [headObjRequest setStrKS3Token:[KS3Util getAuthorization:headObjRequest]];
            KS3HeadObjectResponse *response = [[KS3Client initialize] headObject:headObjRequest];
            NSString *str = [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding];
            if (response.httpStatusCode == 200) {
                NSLog(@"Head object success!");
            }
            else {
                NSLog(@"Head object error: %@", response.error.description);
            }
        }
            break;
        case 3:
        {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                KS3AccessControlList *ControlList = [[KS3AccessControlList alloc] init];
                [ControlList setContronAccess:KingSoftYun_Permission_Public_Read_Write];
                KS3GrantAccessControlList *acl = [[KS3GrantAccessControlList alloc] init];
                acl.identifier = @"4567894346";
                acl.displayName = @"accDisplayName";
                [acl setGrantControlAccess:KingSoftYun_Grant_Permission_Read];
                KS3PutObjectRequest *putObjRequest = [[KS3PutObjectRequest alloc] initWithName:kBucketName withAcl:ControlList grantAcl:@[acl]];
                NSString *fileName = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"jpg"];
                putObjRequest.data = [NSData dataWithContentsOfFile:fileName options:NSDataReadingMappedIfSafe error:nil];
                putObjRequest.filename = @"20150404视频云&标准存储服务产品规划-07.pptx";//@"testtoken-01&.jpg";//[fileName lastPathComponent];
                putObjRequest.contentMd5 = [KS3SDKUtil base64md5FromData:putObjRequest.data];
                [putObjRequest setCompleteRequest];
                NSLog(@"url is %@,host is %@",putObjRequest.url,putObjRequest.host);
                //使用token签名时从Appserver获取token后设置token，使用Ak sk则忽略，不需要调用
                [putObjRequest setStrKS3Token:[KS3Util getAuthorization:putObjRequest]];
                NSLog(@"host is %@",putObjRequest.host);
                NSLog(@"request token is %@",[KS3Util getAuthorization:putObjRequest]);
//                [putObjRequest setEndPointWith:@"kssws.ks-cdn.com"];
                KS3PutObjectResponse *response = [[KS3Client initialize] putObject:putObjRequest];
                NSLog(@"%@",[[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding]);
                if (response.httpStatusCode == 200) {
                    NSLog(@"Put object success");
                }
                else {
                    NSLog(@"Put object failed");
                }

            });
                    }
            break;
        case 4:
        {
            KS3BucketObject *destBucketObj = [[KS3BucketObject alloc] initWithBucketName:kDesBucketName keyName:@"testtoken-11.text"];
            KS3BucketObject *sourceBucketObj = [[KS3BucketObject alloc] initWithBucketName:kBucketName keyName:@"testtoken-11.text"];
            KS3PutObjectCopyRequest *request = [[KS3PutObjectCopyRequest alloc] initWithName:destBucketObj sourceBucketObj:sourceBucketObj];
            [request setCompleteRequest];
             //使用token签名时从Appserver获取token后设置token，使用Ak sk则忽略，不需要调用
            [request setStrKS3Token:[KS3Util getAuthorization:request]];
            KS3PutObjectCopyResponse *response = [[KS3Client initialize] putObjectCopy:request];
            NSString *str = [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding];
            if (response.httpStatusCode == 200) {
                NSLog(@"Put object copy success!");
            }
            else {
                NSLog(@"Put object copy error: %@", response.error.description);
            }
        }
            break;
        case 5:
        {
            NSLog(@"暂不对移动端开放！");
        }
            break;
        case 6:
        {
            KS3GetObjectACLRequest  *getObjectACLRequest = [[KS3GetObjectACLRequest alloc] initWithName:kBucketName withKeyName:kObjectSpecial2];
            [getObjectACLRequest setCompleteRequest];
             //使用token签名时从Appserver获取token后设置token，使用Ak sk则忽略，不需要调用
            [getObjectACLRequest setStrKS3Token:[KS3Util getAuthorization:getObjectACLRequest]];
            KS3GetObjectACLResponse *response = [[KS3Client initialize] getObjectACL:getObjectACLRequest];
            KS3BucketACLResult *result = response.listBucketsResult;
              NSString *str = [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding];
            
            if (response.httpStatusCode == 200) {
                NSLog(@"Get object acl success!");
                NSLog(@"Object owner ID:          %@",result.owner.ID);
                NSLog(@"Object owner displayName: %@",result.owner.displayName);
                for (KS3Grant *grant in result.accessControlList) {
                    NSLog(@"%@",grant.grantee.ID);
                    NSLog(@"%@",grant.grantee.displayName);
                    NSLog(@"%@",grant.grantee.URI);
                    NSLog(@"_______________________");
                    NSLog(@"%@",grant.permission);
                }
            }
            else {
                NSLog(@"Get object acl error: %@", response.error.description);
            }
        }
            break;
        case 7:
        {
            KS3AccessControlList *acl = [[KS3AccessControlList alloc] init];
            [acl setContronAccess:KingSoftYun_Permission_Public_Read_Write];
            KS3SetObjectACLRequest *setObjectACLRequest = [[KS3SetObjectACLRequest alloc] initWithName:kBucketName withKeyName:kObjectSpecial2 acl:acl];
            [setObjectACLRequest setCompleteRequest];
             //使用token签名时从Appserver获取token后设置token，使用Ak sk则忽略，不需要调用
            [setObjectACLRequest setStrKS3Token:[KS3Util getAuthorization:setObjectACLRequest]];
            KS3SetObjectACLResponse *response = [[KS3Client initialize] setObjectACL:setObjectACLRequest];
              NSString *str = [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding];
            if (response.httpStatusCode == 200) {
                NSLog(@"Set object acl success!");
            }
            else {
                NSLog(@"Set object acl error: %@", response.error.description);
            }
        }
            break;
        case 8:
        {
            KS3GrantAccessControlList *acl = [[KS3GrantAccessControlList alloc] init];
            acl.identifier = kObjectName;
            acl.displayName = @"blues111DisplayName";
            [acl setGrantControlAccess:KingSoftYun_Grant_Permission_Read];
            KS3SetObjectGrantACLRequest *setObjectGrantACLRequest = [[KS3SetObjectGrantACLRequest alloc] initWithName:kBucketName withKeyName:kObjectSpecial2 grantAcl:acl];
            [setObjectGrantACLRequest setCompleteRequest];
             //使用token签名时从Appserver获取token后设置token，使用Ak sk则忽略，不需要调用
            [setObjectGrantACLRequest setStrKS3Token:[KS3Util getAuthorization:setObjectGrantACLRequest]];
            KS3SetObjectGrantACLResponse *response = [[KS3Client initialize] setObjectGrantACL:setObjectGrantACLRequest];
            if (response.httpStatusCode == 200) {
                NSLog(@"Set object grant acl success!");
            }
            else {
                NSLog(@"Set object grant acl error: %@", response.error.description);
            }
        }
            break;
        case 9:
        {
//            [self beginUpload];
        }
            break;
        case 10:
        {
            [_downloader stop];
        }
            break;
        case 11:
        {
            [self cancelUpload];
        }
            break;
        default:
            break;
    }
}

- (void)uploadWithPartNumber:(NSInteger)partNumber
{
    @autoreleasepool {
        long long partLength = _partSize * 1024.0 * 1024.0;
        NSData *data = nil;
        if (_uploadNum == _totalNum) {
            data = [_fileHandle readDataToEndOfFile];
        }else {
            data = [_fileHandle readDataOfLength:(NSUInteger)partLength];
            [_fileHandle seekToFileOffset:partLength*(_uploadNum)];
        }
        
        KS3UploadPartRequest *req = [[KS3UploadPartRequest alloc] initWithMultipartUpload:_muilt partNumber:(int32_t)partNumber data:data generateMD5:NO];
        req.delegate = self;
        req.contentLength = data.length;
        req.contentMd5 = [KS3SDKUtil base64md5FromData:data];
        [req setCompleteRequest];
        //使用token签名时从Appserver获取token后设置token，使用Ak sk则忽略，不需要调用
        [req setStrKS3Token:[KS3Util getAuthorization:req]];
        [[KS3Client initialize] uploadPart:req];

    }
 }



#pragma mark - Delegate

- (void)request:(KS3Request *)request didCompleteWithResponse:(KS3Response *)response
{
    _uploadNum ++;
    if (_totalNum < _uploadNum) {
        KS3ListPartsRequest *req2 = [[KS3ListPartsRequest alloc] initWithMultipartUpload:_muilt];
        [req2 setCompleteRequest];
         //使用token签名时从Appserver获取token后设置token，使用Ak sk则忽略，不需要调用
        [req2 setStrKS3Token:[KS3Util getAuthorization:req2]];
        
        KS3ListPartsResponse *response2 = [[KS3Client initialize] listParts:req2];
        
        
        KS3CompleteMultipartUploadRequest *req = [[KS3CompleteMultipartUploadRequest alloc] initWithMultipartUpload:_muilt];
        for (KS3Part *part in response2.listResult.parts) {
            [req addPartWithPartNumber:part.partNumber withETag:part.etag];
        }
        //req参数设置完一定要调这个函数
        [req setCompleteRequest];
         //使用token签名时从Appserver获取token后设置token，使用Ak sk则忽略，不需要调用
        [req setStrKS3Token:[KS3Util getAuthorization:req]];
        
        KS3CompleteMultipartUploadResponse *resp = [[KS3Client initialize] completeMultipartUpload:req];
        NSLog(@"%@",[[NSString alloc] initWithData:resp.body encoding:NSUTF8StringEncoding]);
        if (resp.httpStatusCode != 200) {
            NSLog(@"#####complete multipart upload failed!!! code: %d#####", resp.httpStatusCode);
        }
        
    }
    else {
        [self uploadWithPartNumber:_uploadNum];
    }
}

- (void)request:(KS3Request *)request didFailWithError:(NSError *)error
{
    NSLog(@"upload error: %@", error);
}

- (void)request:(KS3Request *)request didReceiveResponse:(NSURLResponse *)response
{
    // **** TODO:

}

- (void)request:(KS3Request *)request didReceiveData:(NSData *)data
{
    /**
     *  Never call this method, because it's upload
     *
     *  @return <#return value description#>
     */
}

-(void)request:(KS3Request *)request didSendData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite
{
    UIProgressView *progressView = (UIProgressView *)[self.view viewWithTag:199];
    if (_muilt.isCanceled ) {
        [request cancel];
        
        progressView.progress = 0;
        return;
    }
    
    long long alreadyTotalWriten = (_uploadNum - 1) * _partLength + totalBytesWritten;
    double progress = alreadyTotalWriten / (float)_fileSize;
    NSLog(@"upload progress: %f", progress);
#warning upload progress Callback
    progressView.progress = progress;
    if (progress == 1) {
        [_fileHandle closeFile];
    }
}

@end

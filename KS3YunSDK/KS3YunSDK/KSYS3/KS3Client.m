//
//  KingSoftS3Client.m
//  KS3SDK
//
//  Created by JackWong on 12/9/14.
//  Copyright (c) 2014 kingsoft. All rights reserved.
//

#import "KS3Client.h"
#import "KS3AbortMultipartUploadRequest.h"
#import "KS3AbortMultipartUploadResponse.h"
#import "KS3AccessControlList.h"
#import "KS3AuthUtils.h"
#import "KS3ClientException.h"
#import "KS3CompleteMultipartUploadRequest.h"
#import "KS3CompleteMultipartUploadResponse.h"
#import "KS3CreateBucketRequest.h"
#import "KS3CreateBucketResponse.h"
#import "KS3Credentials.h"
#import "KS3DeleteBucketRequest.h"
#import "KS3DeleteBucketResponse.h"
#import "KS3DeleteBucketResponse.h"
#import "KS3DeleteObjectRequest.h"
#import "KS3DeleteObjectResponse.h"
#import "KS3DownLoad.h"
#import "KS3ErrorHandler.h"
#import "KS3GetACLRequest.h"
#import "KS3GetACLResponse.h"
#import "KS3GetBucketLoggingRequest.h"
#import "KS3GetBucketLoggingResponse.h"
#import "KS3GetObjectACLRequest.h"
#import "KS3GetObjectACLResponse.h"
#import "KS3GetObjectRequest.h"
#import "KS3GetObjectResponse.h"
#import "KS3HeadBucketRequest.h"
#import "KS3HeadBucketResponse.h"
#import "KS3HeadObjectRequest.h"
#import "KS3HeadObjectResponse.h"
#import "KS3InitiateMultipartUploadRequest.h"
#import "KS3InitiateMultipartUploadResponse.h"
#import "KS3ListBucketsRequest.h"
#import "KS3ListBucketsResponse.h"
#import "KS3ListBucketsResult.h"
#import "KS3ListObjectsRequest.h"
#import "KS3ListObjectsResponse.h"
#import "KS3ListObjectsResult.h"
#import "KS3ListPartsRequest.h"
#import "KS3ListPartsResponse.h"
#import "KS3PutObjectCopyRequest.h"
#import "KS3PutObjectCopyResponse.h"
#import "KS3PutObjectRequest.h"
#import "KS3PutObjectResponse.h"
#import "KS3SDKUtil.h"
#import "KS3SetACLRequest.h"
#import "KS3SetACLResponse.h"
#import "KS3SetBucketLoggingRequest.h"
#import "KS3SetBucketLoggingResponse.h"
#import "KS3SetGrantACLRequest.h"
#import "KS3SetGrantACLResponse.h"
#import "KS3SetObjectACLRequest.h"
#import "KS3SetObjectACLResponse.h"
#import "KS3SetObjectGrantACLRequest.h"
#import "KS3SetObjectGrantACLResponse.h"
#import "KS3UploadPartRequest.h"
#import "KS3UploadPartResponse.h"
#import <AssetsLibrary/AssetsLibrary.h>
static NSString *const KingSoftYun_Host_Name =
@"http://ks3-cn-beijing.ksyun.com";
static NSTimeInterval const KingSoftYun_RequestTimeout = 600; // in seconds

@interface KS3Client () <NSURLConnectionDataDelegate>

@property(strong, nonatomic) KSS3GetTokenSuccessBlock tokenBlock;
@property(strong, nonatomic) NSMutableData *tokenData;
@property(assign, nonatomic) KS3BucketDomainRegion bucketDomainRegion;
@property(copy, nonatomic) NSString *bucketDomainIp;
@property(strong, nonatomic) NSString *customBucketDomain; //用户自定义的domain
@property(strong, nonatomic) ALAssetsLibrary *assetsLibrary;

@end

@implementation KS3Client

+ (KS3Client *)initialize {
    static KS3Client *shareObj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareObj = [[self alloc] init];
        shareObj.bucketDomainRegion = KS3BucketBeijing;
        shareObj.bucketDomainIp = @"ks3-cn-beijing.ksyun.com";
        shareObj.assetsLibrary = [[ALAssetsLibrary alloc] init];
        shareObj.enableHTTPS = YES;
    });
    return shareObj;
}

#pragma mark - Request Protocol
- (NSString *)requestProtocol {
    return self.enableHTTPS ? @"https" : @"http";
}

#pragma mark - Init credentials

- (void)connectWithAccessKey:(NSString *)accessKey
               withSecretKey:(NSString *)secretKey {
    if (_credentials == nil) {
        _credentials = [[KS3Credentials alloc] initWithAccessKey:accessKey
                                                   withSecretKey:secretKey];
    }
}

- (void)setBucketDomainWithRegion:(KS3BucketDomainRegion)domainRegion {
    _bucketDomainRegion = domainRegion;
}

- (NSString *)getBucketDomain {
    if (_customBucketDomain != nil) {
        return _customBucketDomain;
    }

    if (_bucketDomainRegion == KS3BucketBeijing) {
        return @"ks3-cn-beijing.ksyun.com";
    }

    if (_bucketDomainRegion == KS3BucketAmerica) {
        return @"ks3-us-west-1.ksyun.com";
    }
    if (_bucketDomainRegion == KS3BucketHongkong) {
        return @"ks3-cn-hk-1.ksyun.com";
    }
    if (_bucketDomainRegion == KS3BucketHangzhou) {
        return @"kss.ksyun.com";
    }
    if (_bucketDomainRegion == KS3BucketShanghai) {
        return @"ks3-cn-shanghai.ksyun.com";
    }
    if (_bucketDomainRegion == KS3BucketQingdao) {
        return @"ks3-cn-qingdao.ksyun.com";
    }
    return @"ks3-cn-beijing.ksyun.com";
}

- (NSString *)getCustomBucketDomain {
    if (_customBucketDomain && _bucketDomainRegion != KS3BucketPrivate) {
        return _customBucketDomain;
    } else {
        return nil;
    }
}

- (void)setBucketDomain:(NSString *)domainRegion {
    _customBucketDomain = domainRegion;
}

#pragma mark - Buckets

- (NSArray *)listBuckets:(KS3ListBucketsRequest *)listBucketsRequest {
    KS3ListBucketsResponse *listResponse =
    (KS3ListBucketsResponse *)[self invoke:listBucketsRequest];
    if (listResponse.error == nil) {
        if (![listResponse respondsToSelector:@selector(listBucketsResult)]) {
            return nil;
        }
        if (listResponse.listBucketsResult != nil &&
            listResponse.listBucketsResult.buckets != nil) {
            return [NSArray arrayWithArray:listResponse.listBucketsResult.buckets];
        }
    }
    return nil;
}

- (KS3CreateBucketResponse *)createBucket:
(KS3CreateBucketRequest *)createBucketRequest {
    return (KS3CreateBucketResponse *)[self invoke:createBucketRequest];
}

- (KS3DeleteBucketResponse *)deleteBucket:
(KS3DeleteBucketRequest *)deleteBucketRequest {
    return (KS3DeleteBucketResponse *)[self invoke:deleteBucketRequest];
}

- (KS3HeadBucketResponse *)headBucket:(KS3HeadBucketRequest *)headBucketRequest;
{ return (KS3HeadBucketResponse *)[self invoke:headBucketRequest]; }

- (KS3GetACLResponse *)getBucketACL:(KS3GetACLRequest *)getACLRequest {
    return (KS3GetACLResponse *)[self invoke:getACLRequest];
}

- (KS3SetACLResponse *)setBucketACL:(KS3SetACLRequest *)bucketACLRequest {
    return (KS3SetACLResponse *)[self invoke:bucketACLRequest];
}

- (KS3GetBucketLoggingResponse *)getBucketLogging:
(KS3GetBucketLoggingRequest *)getBucketLoggingRequest {
    return (KS3GetBucketLoggingResponse *)[self invoke:getBucketLoggingRequest];
}

- (KS3SetBucketLoggingResponse *)setBucketLogging:
(KS3SetBucketLoggingRequest *)setBucketTaggingRequest {
    return (KS3SetBucketLoggingResponse *)[self invoke:setBucketTaggingRequest];
}

#pragma mark - Objects

- (KS3ListObjectsResponse *)listObjects:
(KS3ListObjectsRequest *)listObjectsRequest {
    return (KS3ListObjectsResponse *)[self invoke:listObjectsRequest];
}

- (KS3GetObjectResponse *)getObject:(KS3GetObjectRequest *)getObjectRequest {
    return (KS3GetObjectResponse *)[self invoke:getObjectRequest];
}

- (KS3DeleteObjectResponse *)deleteObject:
(KS3DeleteObjectRequest *)deleteObjectRequest {
    return (KS3DeleteObjectResponse *)[self invoke:deleteObjectRequest];
}

- (KS3HeadObjectResponse *)headObject:
(KS3HeadObjectRequest *)headObjectRequest {
    return (KS3HeadObjectResponse *)[self invoke:headObjectRequest];
}

- (KS3PutObjectResponse *)putObject:(KS3PutObjectRequest *)putObjectRequest {
    return (KS3PutObjectResponse *)[self invoke:putObjectRequest];
}

- (KS3PutObjectCopyResponse *)putObjectCopy:
(KS3PutObjectCopyRequest *)putObjectCopyRequest {
    return (KS3PutObjectCopyResponse *)[self invoke:putObjectCopyRequest];
}

- (KS3GetObjectACLResponse *)getObjectACL:
(KS3GetObjectACLRequest *)getObjectACLRequest {
    return (KS3GetObjectACLResponse *)[self invoke:getObjectACLRequest];
}

- (KS3SetObjectACLResponse *)setObjectACL:
(KS3SetObjectACLRequest *)setObjectACLRequest {
    return (KS3SetObjectACLResponse *)[self invoke:setObjectACLRequest];
}

- (KS3SetObjectGrantACLResponse *)setObjectGrantACL:
(KS3SetObjectGrantACLRequest *)setObjectGrantACLRequest {
    return (KS3SetObjectGrantACLResponse *)[self invoke:setObjectGrantACLRequest];
}

- (KS3SetGrantACLResponse *)setGrantACL:
(KS3SetGrantACLRequest *)setGrantACLRequest {
    return (KS3SetGrantACLResponse *)[self invoke:setGrantACLRequest];
}

#pragma mark - MultipartUpload

- (KS3MultipartUpload *)initiateMultipartUploadWithRequest:
(KS3InitiateMultipartUploadRequest *)request {
    KS3InitiateMultipartUploadResponse *response =
    (KS3InitiateMultipartUploadResponse *)[self invoke:request];
    return response.multipartUpload;
}

- (KS3InitiateMultipartUploadResponse *)initiateMultipartUploadWithRequestAndResponse:
(KS3InitiateMultipartUploadRequest *)request {
    KS3InitiateMultipartUploadResponse *response =
    (KS3InitiateMultipartUploadResponse *)[self invoke:request];
    return response;
}

- (KS3UploadPartResponse *)uploadPart:
(KS3UploadPartRequest *)uploadPartRequest {
    return (KS3UploadPartResponse *)[self invoke:uploadPartRequest];
}

- (NSData *)getUploadPartDataWithPartNum:(NSInteger)partNum
                              partLength:(NSInteger)partlength
                              alassetURL:(NSURL *)alassetURL {
    if (alassetURL == nil || alassetURL.absoluteString.length == 0) {
        NSLog(@"请检查AlassetURL");
        return nil;
    }
    if (partlength < 5 * 1024 * 1024) {
        NSLog(@"分块上传最小块为5MB");
        return nil;
    }
    if (partNum < 0) {
        NSLog(@"partNum不合法，请检查");
        return nil;
    }

    ALAsset *alasset =
    [[KS3Client initialize] getAlassetFromAlassetURL:alassetURL];
    return [self getUploadPartDataWithPartNum:partNum
                                   partLength:partlength
                                      Alasset:alasset];
}

- (NSData *)getUploadPartDataWithPartNum:(NSInteger)partNum
                              partLength:(NSInteger)partlength
                                 Alasset:(ALAsset *)assets {

    if (assets == nil) {
        NSLog(@"请检查Alasset");
        return nil;
    }
    if (partlength < 5 * 1024 * 1024) {
        NSLog(@"分块上传最小块为5MB");
        return nil;
    }
    if (partNum < 1) {
        NSLog(@"partNum不合法，请检查");
        return nil;
    }
    BOOL endOfStreamReached = NO;
    NSUInteger currentOffset = (partNum - 1) * partlength; //当前偏移量
    NSError *error;
    NSMutableData *mData = [[NSMutableData alloc] init];
    while (!endOfStreamReached) {
        NSInteger maxLength = 256 * 1024;
        uint8_t readBuffer[maxLength];
        NSInteger bytesRead = [assets.defaultRepresentation getBytes:readBuffer
                                                          fromOffset:currentOffset
                                                              length:maxLength
                                                               error:&error];
        if (bytesRead <= 0) {
            //读取完了或者读取地址不正确，导致读取为空
            endOfStreamReached = YES;
            if (mData.length > 0) {
                return mData;
            }
        } else {
            [mData appendBytes:readBuffer length:bytesRead];
            currentOffset += bytesRead;
            //正在读取,满5M则本地存储分块
            if (mData.length >= partlength) {
                return mData;
            }
        }
    }
    return mData;
}

- (ALAsset *)getAlassetFromAlassetURL:(NSURL *)alassetURL {

    __block ALAsset *assets;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_queue_t concurrentQueue =
    dispatch_queue_create("my.concurrent.queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(concurrentQueue, ^{

        [self.assetsLibrary assetForURL:alassetURL
                            resultBlock:^(ALAsset *asset) {
                                //本地存储的上传文件
                                assets = asset;
                                dispatch_semaphore_signal(sem);
                            }
                           failureBlock:^(NSError *error) {
                               NSLog(@"读取AssetURL出错,%@", error.localizedDescription);
                               dispatch_semaphore_signal(sem);
                           }];

    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return assets;
}
- (KS3ListPartsResponse *)listParts:(KS3ListPartsRequest *)listPartsRequest {
    return (KS3ListPartsResponse *)[self invoke:listPartsRequest];
}

- (KS3CompleteMultipartUploadResponse *)completeMultipartUpload:
(KS3CompleteMultipartUploadRequest *)completeMultipartUploadRequest {
    return (KS3CompleteMultipartUploadResponse *)[self
                                                  invoke:completeMultipartUploadRequest];
}

- (KS3AbortMultipartUploadResponse *)abortMultipartUpload:
(KS3AbortMultipartUploadRequest *)abortMultipartRequest {
    return (KS3AbortMultipartUploadResponse *)[self invoke:abortMultipartRequest];
}

+ (id)constructResponseFromRequest:(KS3Request *)request {
    NSString *requestClassName = NSStringFromClass([request class]);
    NSString *responseClassName =
    [[requestClassName substringToIndex:[requestClassName length] - 7]
     stringByAppendingFormat:@"Response"];
    id response = [[NSClassFromString(responseClassName) alloc] init];
    if (nil == response) {
        if ([requestClassName isEqualToString:@"KS3UploadRequest"]) {
            response = [[KS3InitiateMultipartUploadResponse alloc] init];
        } else {
            response = [[KS3Response alloc] init];
        }
    }
    return response;
}

- (NSMutableURLRequest *)signKSS3Request:(KS3Request *)request {
    request.credentials = _credentials;
    KS3URLRequest *urlRequest = [request configureURLRequest];
    return urlRequest;
}

- (NSTimeInterval)getRequestTimeOut:(KS3Request *)request {
    NSTimeInterval ksyRequestTimeOut = request.timeoutInterval;
    if (ksyRequestTimeOut == 0 || ksyRequestTimeOut < 0) {
        ksyRequestTimeOut = KingSoftYun_RequestTimeout;
    }
    return ksyRequestTimeOut;
}
- (KS3Response *)invoke:(KS3Request *)request {
    NSString *message = nil;
    if ((_credentials.accessKey == nil || _credentials.secretKey == nil) &&
        _credentials != nil) {
        NSLog(@"######### 使用本地AK/SK签名, 请正确配置本地AK/SK #############");
        message = @"请正确配置本地AK/SK";
    }
    if (message) {
        KS3Response *response = [KS3Response new];
        response.error =
        [KS3ErrorHandler errorFromExceptionWithThrowsExceptionOption:
         [KS3ClientException exceptionWithMessage:message]];
        return response;
    }

    if (nil == request) {
        KS3Response *response = [KS3Response new];
        response.error = [KS3ErrorHandler
                          errorFromExceptionWithThrowsExceptionOption:
                          [KS3ClientException
                           exceptionWithMessage:@"Request cannot be nil."]];
        return response;
    }
    KS3ClientException *clientException = [request validate];
    if (clientException != nil) {
        KS3Response *response = [KS3Response new];
        response.error = [KS3ErrorHandler
                          errorFromExceptionWithThrowsExceptionOption:((NSException *)
                                                                       clientException)];
        return response;
    }
    NSMutableURLRequest *urlRequest = [self signKSS3Request:request];

    [urlRequest setTimeoutInterval:[self getRequestTimeOut:request]];
    return [self startURLRequest:urlRequest
                      KS3Request:request
                           token:request.strKS3Token];
}

- (KS3Response *)startURLRequest:(NSMutableURLRequest *)urlRequest
                      KS3Request:(KS3Request *)request
                           token:(NSString *)strToken {
    if (strToken != nil) {
        [urlRequest setValue:strToken forHTTPHeaderField:@"Authorization"];
    }
    KS3Response *response = [KS3Client constructResponseFromRequest:request];
    [response setRequest:request];
    if ([request delegate] != nil) {
        NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest
                                                                         delegate:response
                                                                 startImmediately:NO];
        request.urlConnection = urlConnection;

        [NSTimer scheduledTimerWithTimeInterval:[self getRequestTimeOut:request]
                                         target:response
                                       selector:@selector(timeout)
                                       userInfo:nil
                                        repeats:NO];

        dispatch_async(dispatch_get_main_queue(), ^{
            [urlConnection start];
        });
        return nil;
    }
    NSURLConnection *urlConnection =
    [[NSURLConnection alloc] initWithRequest:urlRequest
                                    delegate:response
                            startImmediately:NO];
    [urlConnection scheduleInRunLoop:[NSRunLoop currentRunLoop]
                             forMode:KSYS3DefaultRunLoopMode];
    request.urlConnection = urlConnection;
    [urlConnection start];

    NSTimer *timeoutTimer =
    [NSTimer timerWithTimeInterval:[self getRequestTimeOut:request]
                            target:response
                          selector:@selector(timeout)
                          userInfo:nil
                           repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timeoutTimer
                                 forMode:KSYS3DefaultRunLoopMode];
    while (!response.isFinishedLoading) {
        [[NSRunLoop currentRunLoop]
         runMode:KSYS3DefaultRunLoopMode
         beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    return response;
}

#pragma mark - Download

- (KS3DownLoad *)
downloadObjectWithBucketName:(NSString *)bucketName
key:(NSString *)key
downloadBeginBlock:(KSS3DownloadBeginBlock)downloadBeginBlock
downloadFileCompleteion:
(kSS3DownloadFileCompleteionBlock)downloadFileCompleteion
downloadProgressChangeBlock:
(KSS3DownloadProgressChangeBlock)downloadProgressChangeBlock
failedBlock:(KSS3DownloadFailedBlock)failedBlock {
    if (!bucketName || !key) {
        NSLog(@"bucket 或 key 不能为空");
        return nil;
    }

    if ((_credentials.accessKey == nil || _credentials.secretKey == nil) &&
        _credentials != nil) {
        NSLog(@"######### 使用本地AK/SK签名, 请正确配置本地AK/SK #############");
        return nil;
    }
    NSLog(@"====== downloadObjectWithBucketName ======");
    NSString *strHost = [NSString
                         stringWithFormat:@"%@://%@.%@/%@",
                         [[KS3Client initialize] requestProtocol], bucketName,
                         [[KS3Client initialize] getBucketDomain], key];
    KS3DownLoad *downLoad = [[KS3DownLoad alloc] initWithUrl:strHost
                                                 credentials:
                                                _credentials:
                                                  bucketName:key];
    downLoad.downloadBeginBlock = downloadBeginBlock;
    downLoad.downloadFileCompleteionBlock = downloadFileCompleteion;
    downLoad.downloadProgressChangeBlock = downloadProgressChangeBlock;
    downLoad.failedBlock = failedBlock;
    
    return downLoad;
}

+ (NSString *)apiVersion {
    return @"2.1.3";
}

@end

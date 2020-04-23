//
//  KingSoftS3Client.h
//  KS3SDK
//
//  Created by JackWong on 12/9/14.
//  Copyright (c) 2014 kingsoft. All rights reserved.
//  有问题联系
//  QQ:315720327
//  email:me@iluckly.com
//

#import "KS3WebServiceClient.h"

@class KingSoftURLConnection;
@class KS3DownLoad;
@class ALAsset;
#pragma mark - Download block

typedef void (^KSS3GetTokenSuccessBlock)(NSString *strToken);
typedef void (^KSS3DownloadBeginBlock)(KS3DownLoad *aDownload,
                                       NSURLResponse *responseHeaders);
typedef void (^KSS3DownloadProgressChangeBlock)(KS3DownLoad *aDownload,
                                                double newProgress);
typedef void (^KSS3DownloadFailedBlock)(KS3DownLoad *aDownload, NSError *error);
typedef void (^kSS3DownloadFileCompleteionBlock)(KS3DownLoad *aDownload,
                                                 NSString *filePath);

@class KS3DeleteBucketResponse;
@class KS3SetACLResponse;
@class KS3ListBucketsRequest;
@class KS3ListBucketsResponse;
@class KS3CreateBucketResponse;
@class KS3GetACLResponse;
@class KS3GetBucketLoggingResponse;
@class KS3SetBucketLoggingResponse;
@class KS3GetObjectResponse;
@class KS3DeleteObjectResponse;
@class KS3HeadObjectResponse;
@class KS3PutObjectResponse;
@class KS3GetObjectACLResponse;
@class KS3SetObjectACLResponse;
@class KS3UploadPartResponse;
@class KS3UploadPartRequest;
@class KS3MultipartUpload;
@class KS3ListPartsResponse;
@class KS3ListPartsRequest;
@class KS3CompleteMultipartUploadResponse;
@class KS3CompleteMultipartUploadRequest;
@class KS3ListObjectsResponse;
@class KS3ListObjectsRequest;
@class KS3CreateBucketRequest;
@class KS3DeleteBucketResponse;
@class KS3DeleteBucketRequest;
@class KS3SetACLRequest;
@class KS3PutObjectRequest;
@class KS3GetObjectACLRequest;
@class KS3SetObjectACLRequest;
@class KS3DeleteObjectRequest;
@class KS3AbortMultipartUploadRequest;
@class KS3AbortMultipartUploadResponse;
@class KS3HeadBucketRequest;
@class KS3HeadBucketResponse;
@class KS3GetACLRequest;
@class KS3GetObjectRequest;
@class KS3HeadObjectRequest;
@class KS3SetGrantACLResponse;
@class KS3SetGrantACLRequest;
@class KS3SetObjectGrantACLResponse;
@class KS3SetObjectGrantACLRequest;
@class KS3SetBucketLoggingRequest;
@class KS3PutObjectCopyRequest;
@class KS3PutObjectCopyResponse;
@class KS3Response;
@class KS3Request;
@class KS3InitiateMultipartUploadRequest;
@class KS3InitiateMultipartUploadResponse;
@class KS3GetBucketLoggingRequest;
@class KS3Credentials;

typedef enum {
  KS3BucketBeijing = 0,
  KS3BucketAmerica,
  KS3BucketHongkong,
  KS3BucketHangzhou,
  KS3BucketShanghai,
  KS3BucketQingdao,
  KS3BucketPrivate,
} KS3BucketDomainRegion; // bucket所在地区

@interface KS3Client : KS3WebServiceClient

@property(assign, nonatomic) BOOL enableHTTPS;
@property(strong, nonatomic) KS3Credentials *credentials;

/**
 *  初始化
 *
 *  @return Client对象
 */
+ (KS3Client *)initialize;

/**
 * 返回请求协议：http/https
 * 目前由enableHTTPS决定
 */
- (NSString *)requestProtocol;

/**
 *  设置AccessKey和SecretKey
 *
 *  @param accessKey
 *  @param secretKey
 *  注释：这个接口必须实现（这个是使用下面API的（前提））建议在工程的delegate里面实现
 */
- (void)connectWithAccessKey:(NSString *)accessKey
               withSecretKey:(NSString *)secretKey;
/**
 *  设置KS3Bucket所在的地区，默认北京

 *  @param 共有北京，杭州，美国圣克拉拉，香港四个
 *  注释：建议在工程的delegate里面实现
  */
- (void)setBucketDomainWithRegion:(KS3BucketDomainRegion)domainRegion;

/*
  设置KS3Bucket 所在的地区
 @param 自定义的域名
 */
- (void)setBucketDomain:(NSString *)domainRegion;

/**
 *  获取当前bucket所在地区，默认北京
    共有北京，杭州，美国圣克拉拉，香港四个
 */
- (NSString *)getBucketDomain;

/**
 *  获取用户自定义的域名
 *  如果没有设置，返回nil
 */
- (NSString *)getCustomBucketDomain;

/**
 *  列出客户所有的Bucket信息
 *
 *  @return 所有bucket的数组
 */
- (NSArray *)listBuckets:(KS3ListBucketsRequest *)listBucketsRequest;

/**
 *  创建一个新的Bucket
 *
 *  @param createBucketRequest 设置创建bucket的request信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3CreateBucketResponse *)createBucket:
    (KS3CreateBucketRequest *)createBucketRequest;
/**
 *  删除指定Bucket
 *
 *  @param deleteBucketRequest 设置删除bucket的request信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3DeleteBucketResponse *)deleteBucket:
    (KS3DeleteBucketRequest *)deleteBucketRequest;
/**
 *  查询是否已经存在指定Bucket
 *
 *  @param headBucketRequest 设置是否已经存在指定Bucket的request信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3HeadBucketResponse *)headBucket:(KS3HeadBucketRequest *)headBucketRequest;

/**
 *  获得Bucket的acl
 *
 *  @param getACLRequest 设置获取Bucket的acl的request对象
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3GetACLResponse *)getBucketACL:(KS3GetACLRequest *)getACLRequest;
/**
 *  设置Bucket的ACL
 *
 *  @param getACLRequest 设置设置Bucket的ACL的request对象
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3SetACLResponse *)setBucketACL:(KS3SetACLRequest *)getACLRequest;
/**
 *  设置GrantACL信息
 *
 *  @param setGrantACLRequest 设置grantACL的request信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3SetGrantACLResponse *)setGrantACL:
    (KS3SetGrantACLRequest *)setGrantACLRequest;
/**
 *  列举Bucket内的Object
 *
 *  @param bucketName
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3ListObjectsResponse *)listObjects:
    (KS3ListObjectsRequest *)listObjectsRequest;

/**
 *  获得Bucket的日志信息
 *
 *  @param bucketName
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3GetBucketLoggingResponse *)getBucketLogging:
    (KS3GetBucketLoggingRequest *)getBucketLoggingRequest;
/**
 *  下载Object数据
 *
 *  @param getObjectRequest 设置下载Object的request请求信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3GetObjectResponse *)getObject:(KS3GetObjectRequest *)getObjectRequest;
/**
 *  删除指定Object
 *
 *  @param deleteObjectRequest 设置删除Object的request请求信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3DeleteObjectResponse *)deleteObject:
    (KS3DeleteObjectRequest *)deleteObjectRequest;

/**
 *  查询是否已经存在指定Object
 *
 *  @param headObjectRequest 设置是否已存在Object的request的信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3HeadObjectResponse *)headObject:(KS3HeadObjectRequest *)headObjectRequest;
/**
 *  上传Object数据 （如果文件比较大请设置委托）
 *
 *  @param putObjectRequest 设置上传object的request的信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3PutObjectResponse *)putObject:(KS3PutObjectRequest *)putObjectRequest;
/**
 *  把源Bucket里面的某个Object复制到目的Bucket里面一个指定的Object
 *
 *  @param putObjectCopyRequest 设置setObjectACLRequest的request信息
 *
 *  @return 返回response对象（里边有服务返回的数据（具体的参照demo）
 */
- (KS3PutObjectCopyResponse *)putObjectCopy:
    (KS3PutObjectCopyRequest *)putObjectCopyRequest;

/**
 *  获得Object的acl
 *
 *  @param getObjectACLRequest 设置获取object的acl的request信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3GetObjectACLResponse *)getObjectACL:
    (KS3GetObjectACLRequest *)getObjectACLRequest;
/**
 *  设置Object的acl
 *
 *  @param setObjectACLRequest 设置设置object的acl的request信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */

- (KS3SetObjectACLResponse *)setObjectACL:
    (KS3SetObjectACLRequest *)setObjectACLRequest;
/**
 *  设置ObjectGrantACL
 *
 *  @param setObjectGrantACLRequest 设置设置ObjectGrantACL的request信息
 *
 *  @return @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */

- (KS3SetObjectGrantACLResponse *)setObjectGrantACL:
    (KS3SetObjectGrantACLRequest *)setObjectGrantACLRequest;
/**
 *  调用这个接口会初始化一个分块上传
 *
 *  @param theKey    指的是上传到bucketName的文件名称
 *  @param bucketName
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3MultipartUpload *)initiateMultipartUploadWithRequest:
    (KS3InitiateMultipartUploadRequest *)request;

- (KS3InitiateMultipartUploadResponse *)initiateMultipartUploadWithRequestAndResponse:(KS3InitiateMultipartUploadRequest *)request;

/**
 *  上传分块
 *
 *  @param uploadPartRequest 指定上传分块的request信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3UploadPartResponse *)uploadPart:(KS3UploadPartRequest *)uploadPartRequest;
/**
 *  获取相册分块数据
 *
 *  @param partNum 从1开始计数，第一块partNum = 1
 *  @param partLength 每一块数据的大小，单位为字节
 *  @param alassetURL 形如assets-library://asset/asset.mov?
 id=25A47CAE-87CF-47A3-8834-592D60841DDB&ext=mov 的相册地址  ，
 *
 *  @return
 */
- (NSData *)getUploadPartDataWithPartNum:(NSInteger)partNum
                              partLength:(NSInteger)partlength
                              alassetURL:(NSURL *)alassetURL;
/**
 *  获取相册分块数据
 *
 *  @param partNum 从1开始计数，第一块partNum = 1
 *  @param partLength 每一块数据的大小，单位为字节
 *  @param alassetURL Alasset对象，是获取视频数据的类 ，
 *
 *  @return
 */
- (NSData *)getUploadPartDataWithPartNum:(NSInteger)partNum
                              partLength:(NSInteger)partlength
                                 Alasset:(ALAsset *)assets;
/**
 *  获取相册类
 *  @param alassetURL 开头是assets-library://标识Alasset类的相册地址
 *
 *  @return
 */
- (ALAsset *)getAlassetFromAlassetURL:(NSURL *)alassetURL;
/**
 *  罗列出已经上传的块
 *
 *  @param listPartsRequest 设置罗列已经上传的分块的request信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */

- (KS3ListPartsResponse *)listParts:(KS3ListPartsRequest *)listPartsRequest;
/**
 *  组装所有分块上传的文件
 *
 *  @param completeMultipartUploadRequest 设置组装所有分块的http信息
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3CompleteMultipartUploadResponse *)completeMultipartUpload:
    (KS3CompleteMultipartUploadRequest *)completeMultipartUploadRequest;
/**
 *  取消分块上传
 *
 *  @param abortMultipartRequest 设置分块文件属性
 *
 *  @return 返回resonse对象（里边有服务返回的数据（具体的参照demo））
 */
- (KS3AbortMultipartUploadResponse *)abortMultipartUpload:
    (KS3AbortMultipartUploadRequest *)abortMultipartRequest;
/**
 *  下载Object数据
 *
 *  @param bucketName
 *  @param key 文件所在的仓库路径（和listObject的key对应）（具体的参照demo）
 *  @param downloadBeginBlock          下载开始回调
 *  @param downloadFileCompleteion     下载完成回调
 *  @param downloadProgressChangeBlock 下载进度回调
 *  @param failedBlock                 下载失败回调
 *
 *  @return 一个下载器对象（里面有文件属性）
 */
- (KS3DownLoad *)
downloadObjectWithBucketName:(NSString *)bucketName
                         key:(NSString *)key
          downloadBeginBlock:(KSS3DownloadBeginBlock)downloadBeginBlock
     downloadFileCompleteion:
         (kSS3DownloadFileCompleteionBlock)downloadFileCompleteion
 downloadProgressChangeBlock:
     (KSS3DownloadProgressChangeBlock)downloadProgressChangeBlock
                 failedBlock:(KSS3DownloadFailedBlock)failedBlock;

/**
 *  返回版本信息
 *
 *  @return 版本信息
 */
+ (NSString *)apiVersion;

@end

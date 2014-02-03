//
//  SHEditKeyViewController.m
//  SGit
//
//  Created by Rizhen Zhang on 2/1/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import "SHEditKeyViewController.h"
#import "SHBasic.h"
#import "Repo.h"
#import <Security/Security.h>

@interface SHEditKeyViewController ()

@property (weak, nonatomic) IBOutlet UITextField *keyName;
@property (weak, nonatomic) IBOutlet UITextView *publicKey;
@property (weak, nonatomic) IBOutlet UITextView *privateKey;
@property (weak, nonatomic) IBOutlet UITextField *passphrase;
@property (weak, nonatomic) IBOutlet UISwitch *isDefaultKey;

@property (nonatomic) BOOL isDefaultOriginal;
@end

@implementation SHEditKeyViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.key != nil) {
        SHBasic *basic = [SHBasic defaultBasic];
        self.keyName.text = self.key;
        NSString *privateKeyPath = [basic privateKeyPath:self.key];
        NSString *publicKeyPath = [basic publicKeyPath:self.key];
        NSDictionary *dict = [basic keyPairByKeyName:self.key];
        self.passphrase.text = [dict objectForKey:@"passphrase"];
        self.publicKey.text = [NSString stringWithContentsOfFile:publicKeyPath
                                                        encoding:NSUTF8StringEncoding
                                                           error:nil];
        self.privateKey.text = [NSString stringWithContentsOfFile:privateKeyPath
                                                         encoding:NSUTF8StringEncoding
                                                            error:nil];
    }
    [self loadDefaultKey];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveKey:(id)sender {
    SHBasic *basic = [SHBasic defaultBasic];
    if ([self.keyName.text isEqualToString:@""] || [[self.keyName.text pathExtension] isEqualToString:@"pub"]) {
        [basic showError:@"Key name should not be empty or end with \"pub\"."];
        return;
    }
    if (self.key != nil) {
        [basic removeKeyPair:self.key];
    }
    NSString *privateKeyPath = [basic privateKeyPath:self.keyName.text];
    NSString *publicKeyPath = [basic publicKeyPath:self.keyName.text];
    [self.privateKey.text writeToFile:privateKeyPath
                           atomically:YES
                             encoding:NSUTF8StringEncoding
                                error:nil];
    [self.publicKey.text writeToFile:publicKeyPath
                           atomically:YES
                             encoding:NSUTF8StringEncoding
                                error:nil];
    NSDictionary *keyPair = @{@"name":self.keyName.text, @"passphrase":self.passphrase.text};
    [basic setKeyPair:keyPair byKeyName:self.keyName.text];
    [self saveDefaultKey];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)loadDefaultKey
{
    SHBasic *basic = [SHBasic defaultBasic];
    self.isDefaultOriginal = [basic.defaultKeyPair isEqualToString:self.key];
    self.isDefaultKey.on = self.isDefaultOriginal ;
}

- (void)saveDefaultKey
{
    SHBasic *basic = [SHBasic defaultBasic];
    if (self.isDefaultKey.on) {
        basic.defaultKeyPair = self.keyName.text;
    } else if(self.isDefaultOriginal) {
        basic.defaultKeyPair = @"";
    }
}

static const UInt8 publicKeyIdentifier[] = "me.sheimi.publickey\0";
static const UInt8 privateKeyIdentifier[] = "me.sheimi.privatekey\0";

- (IBAction)generateKeyPair:(id)sender
{
    dispatch_async([Repo getRepoQueues], ^{
        [self generateKeyPair];
    });
}

- (void) generateKeyPair
{
    OSStatus status = noErr;
    NSMutableDictionary *privateKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *publicKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *keyPairAttr = [[NSMutableDictionary alloc] init];
    // Allocates dictionaries to be used for attributes in the SecKeyGeneratePair function.
    
    NSData * publicTag = [NSData dataWithBytes:publicKeyIdentifier
                                        length:strlen((const char *)publicKeyIdentifier)];
    NSData * privateTag = [NSData dataWithBytes:privateKeyIdentifier
                                         length:strlen((const char *)privateKeyIdentifier)];
    // Creates NSData objects that contain the identifier strings defined in step 1.
    
    SecKeyRef publicKey = NULL;
    SecKeyRef privateKey = NULL;
    // Allocates SecKeyRef objects for the public and private keys
    [keyPairAttr setObject:(__bridge id)kSecAttrKeyTypeRSA
                    forKey:(__bridge id)kSecAttrKeyType];
    // Sets the key-type attribute for the key pair to RSA
    [keyPairAttr setObject:[NSNumber numberWithInt:2048]
                    forKey:(__bridge id)kSecAttrKeySizeInBits];
    // Sets the key-size attribute for the key pair to 1024 bits
    
    [privateKeyAttr setObject:[NSNumber numberWithBool:YES]
                       forKey:(__bridge id)kSecAttrIsPermanent];
    // Sets an attribute specifying that the private key is to be stored permanently (that is, put into the keychain)
    [privateKeyAttr setObject:privateTag
                       forKey:(__bridge id)kSecAttrApplicationTag];
    // Adds the identifier string defined in steps 1 and 3 to the dictionary for the private key
    
    [publicKeyAttr setObject:[NSNumber numberWithBool:YES]
                      forKey:(__bridge id)kSecAttrIsPermanent];
    // Sets an attribute specifying that the public key is to be stored permanently (that is, put into the keychain)
    [publicKeyAttr setObject:publicTag
                      forKey:(__bridge id)kSecAttrApplicationTag];
    // Adds the identifier string defined in steps 1 and 3 to the dictionary for the public key
    
    [keyPairAttr setObject:privateKeyAttr
                    forKey:(__bridge id)kSecPrivateKeyAttrs];
    // Adds the dictionary of private key attributes to the key-pair dictionary
    [keyPairAttr setObject:publicKeyAttr
                    forKey:(__bridge id)kSecPublicKeyAttrs];
    // Adds the dictionary of public key attributes to the key-pair dictionary
    
    status = SecKeyGeneratePair((__bridge CFDictionaryRef)keyPairAttr, &publicKey, &privateKey); // Generates the key pair
    //    error handling...
    
    size_t publicSize = SecKeyGetBlockSize(publicKey);
    NSData* publicData = [NSData dataWithBytes:publicKey length:publicSize];
    NSString *publicKeyStr =[publicData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    size_t privateSize = SecKeyGetBlockSize(privateKey);
    NSData* privateData = [NSData dataWithBytes:privateKey length:privateSize];
    NSString *privatekeyStr =[privateData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.publicKey.text = publicKeyStr;
        self.privateKey.text = privatekeyStr;
    });
    
    if(publicKey) CFRelease(publicKey);
    if(privateKey) CFRelease(privateKey);                       // Releases memory that is no longer needed
}


@end

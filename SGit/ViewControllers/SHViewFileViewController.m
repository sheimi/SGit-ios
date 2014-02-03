//
//  SHViewFileViewController.m
//  SGit
//
//  Created by Rizhen Zhang on 12/30/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import "Repo.h"
#import "SHViewFileViewController.h"
#import "SHCodeGuesser.h"

@interface SHViewFileViewController ()<UIWebViewDelegate, UIActionSheetDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (nonatomic) BOOL editClicked;
@property (weak, nonatomic) IBOutlet UIPickerView *languagePicker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;

- (void)initSouceCodeViewer;

@end

@implementation SHViewFileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.filePath.lastPathComponent;
    NSURL *url = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"assets/editor"
                                                                         ofType:@"html"]];
    self.webview.delegate = self;
    [self.webview loadRequest:[NSURLRequest requestWithURL: url]];
    self.editClicked = NO;
    self.languagePicker.hidden = YES;
    self.languagePicker.dataSource = self;
    self.languagePicker.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = [request URL];
    if ([[url scheme] isEqualToString:@"ios"]) {
        // parse the rest of the URL object and execute functions
        NSString* rq = url.absoluteString.lastPathComponent;
        if ([rq isEqualToString:@"init"]) {
            [self initSouceCodeViewer];
        }
        return NO;
    }
    return YES;
}

- (void)initSouceCodeViewer {
    __weak SHViewFileViewController *_self = self;
    dispatch_async([Repo getRepoQueues], ^{
        NSError *error;
        NSString *source = [NSString stringWithContentsOfFile:_self.filePath
                                                     encoding:NSUTF8StringEncoding error:&error];
        if (error != nil) {
            NSLog(@"%@", error);
            return;
        }
        NSArray *lines =  [source componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSMutableString *ms = [[NSMutableString alloc] init];
        for (NSString *str in lines) {
            [ms appendString:[SHCodeGuesser addSlash:str]];
            [ms appendString:@"\\n"];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *setCodeJs = [NSString stringWithFormat:@"setRawCodes(\"%@\");", ms];
            NSString *setLangJs = [NSString stringWithFormat:@"setLang(\"%@\");", [SHCodeGuesser guessLangForFileName:self.filePath]];
            NSString *loadContent = @"display();";
            [_self.webview stringByEvaluatingJavaScriptFromString: setLangJs];
            [_self.webview stringByEvaluatingJavaScriptFromString: setCodeJs];
            [_self.webview stringByEvaluatingJavaScriptFromString: loadContent];
        });
    });
}
- (IBAction)menuButtonClicked:(id)sender {
    if (self.editClicked) {
        // TO SAVE FILE
        self.menuButton.title = @"Menu";
        NSString* content = [self.webview stringByEvaluatingJavaScriptFromString:@"save();"];
        __weak SHViewFileViewController *_self = self;
        dispatch_async([Repo getRepoQueues], ^{
            NSError *error;
            [content writeToFile:_self.filePath
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:&error];
            if (error != nil) {
                NSLog(@"%@", error);
                return;
            }
            [_self.repo addToStage:_self.filePath];
        });
        self.editClicked = NO;
        return;
    }
    
    if (!self.languagePicker.hidden) {
        self.menuButton.title = @"Menu";
        NSString* lang = [[SHCodeGuesser getSupportLanguageList] objectAtIndex:[self.languagePicker selectedRowInComponent:0]];
        NSString *setLangJs = [NSString stringWithFormat:@"setLang(\"%@\");", [SHCodeGuesser guessLangForExt:lang]];
        [self.webview stringByEvaluatingJavaScriptFromString: setLangJs];
        self.languagePicker.hidden = YES;
        
        __weak SHViewFileViewController *_self = self;
        [UIView animateWithDuration:0.5 animations:^(void) {
            _self.webview.alpha = 1;
        }];
        return;
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles: @"Edit", @"Choose Language", nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)actionSheet:(UIActionSheet *) actionSheet
clickedButtonAtIndex: (NSInteger) buttonIndex {
    NSString *key = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([key isEqualToString:@"Edit"]) {
        self.menuButton.title = @"Save";
        self.editClicked = YES;
        [self.webview stringByEvaluatingJavaScriptFromString:@"setEditable();"];
        return;
    }
    if ([key isEqualToString:@"Choose Language"]) {
        self.languagePicker.hidden = NO;
        self.menuButton.title = @"OK";
        
        __weak SHViewFileViewController *_self = self;
        [UIView animateWithDuration:0.5 animations:^(void) {
            _self.webview.alpha = 0.4;
        }];
        return;
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component {
    return [[SHCodeGuesser getSupportLanguageList] count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
    return [[SHCodeGuesser getSupportLanguageList] objectAtIndex:row];
}


@end

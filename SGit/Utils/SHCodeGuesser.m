//
//  SHCodeGuesser.m
//  SGit
//
//  Created by Rizhen Zhang on 12/30/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import "SHCodeGuesser.h"

static NSMutableDictionary* fileExtensionMap;
static NSArray* fileExtensionArray;
static NSMutableArray* supportLanguageList;

@implementation SHCodeGuesser


+ (NSArray *)getFileExtensionArray {
    if (fileExtensionArray == nil) {
        fileExtensionArray = @[@[ @"APL", @"text/apl", @"apl" ],
        @[ @"Asterisk dialplan", @"text/x-asterisk", @"conf" ],
        @[ @"C", @"text/x-csrc", @"c", @"m" ],
        @[ @"C++", @"text/x-c++src", @"cpp", @"hpp", @"h" ],
        @[ @"C#", @"text/x-csharp", @"cs" ],
        @[ @"Java", @"text/x-java", ],
        @[ @"Clojure", @"text/x-clojure.", @"clj", @"cljs" ],
        @[ @"COBOL", @"text/x-cobol", @"cbl" ],
        @[ @"CoffeeScript", @"text/x-coffeescript", @"coffee" ],
        @[ @"Lisp", @"text/x-common-lisp", @"lisp", @"lsp", @"el", @"cl", @"jl",
           @"L", @"emacs", @"sawfishrc" ],
        @[ @"CSS", @"text/css", @"css" ],
        @[ @"Scss", @"text/x-scss", @"scss" ],
        @[ @"Sass", @"text/x-sass", @"sass" ],
        @[ @"Less", @"text/x-x-less", @"sass" ],
        @[ @"D", @"text/x-d", @"d" ],
        @[ @"Diff", @"text/x-diff", @"diff", @"patch", @"rej" ],
        @[ @"DTD", @"application/xml-dtd" ],
        @[ @"ECL", @"text/x-ecl" ],
        @[ @"Eiffel", @"text/x-eiffel", @"e" ],
        @[ @"Erlang", @"text/x-erlang", @"erl", @"hrl", @"yaws" ],
        @[ @"Fortran", @"text/x-Fortran", @"f", @"for", @"f90", @"f95" ],
        @[ @"Gas", @"text/x-gas", @"as", @"gas" ],
        @[ @"Go", @"text/x-go", @"go" ],
        @[ @"Groovy", @"text/x-groovy", @"groovy", @"gvy", @"gy", @"gsh" ],
        @[ @"HAML", @"text/x-haml", @"haml" ],
        @[ @"Haskell", @"text/x-haskell", @"hs" ],
        @[ @"ASP.net", @"text/x-aspx", @"asp", @"aspx" ],
        @[ @"JSP", @"text/x-jsp", @"jsp" ],
        @[ @"HTML", @"text/html", @"html", @"htm" ],
        @[ @"Jade", @"text/x-jade", @"jade" ],
        @[ @"JavaScript", @"text/javascript", @"js", @"javascript" ],
        @[ @"JinJia2", @"jinja2" ],
        @[ @"LiveScript", @"text/x-livescript", @"ls" ],
        @[ @"Lua", @"text/x-lua", @"lua" ],
        @[ @"Markdown", @"text/x-markdown", @"md", @"markdown" ],
        @[ @"Markdown (Github)", @"gfm", @"md", @"markdown" ],
        @[ @"Nginx", @"text/nginx", @"conf" ],
        @[ @"OCaml", @"text/x-ocaml", @"ocaml", @"ml", @"mli" ],
        @[ @"Matlab", @"text/x-octave" ],
        @[ @"Pascal", @"text/x-pascal", @"p", @"pp", @"pas" ],
        @[ @"PHP", @"application/x-httpd-php", @"php" ],
        @[ @"Pig Latin", @"text/x-pig", @"pig" ],
        @[ @"Perl", @"text/x-perl", @"pl" ],
        @[ @"Ini", @"text/x-ini", @"ini" ],
        @[ @"Properties", @"text/x-properties", @"properties" ],
        @[ @"Python", @"text/x-python", @"py" ],
        @[ @"R", @"text/x-rsrc", @"r" ],
        @[ @"Ruby", @"text/x-ruby", @"rb" ],
        @[ @"Scala", @"text/x-scala", @"scala" ],
        @[ @"Scheme", @"text/x-scheme", @"scm", @"ss" ],
        @[ @"Shell", @"text/x-sh", @"sh", @"bash" ],
        @[ @"Smalltalk", @"text/x-stsrc", @"st" ],
        @[ @"SQL", @"text/x-sql", @"sql" ],
        @[ @"Tex", @"text/x-stex", @"cls", @"latex", @"tex", @"sty", @"dtx", @"ltx",
           @"bbl" ],
        @[ @"VBScript", @"text/vbscript", @"vbs", @"vbe", @"wsc" ],
        @[ @"XML", @"application/xml", @"xml" ],
        @[ @"YAML", @"text/x-yaml", @"yaml" ], ];
    }
    return fileExtensionArray;
}

+ (NSDictionary *)getFileExtensionMap {
    if (fileExtensionMap == nil) {
        fileExtensionMap = [[NSMutableDictionary alloc] init];
        NSArray *fea = [SHCodeGuesser getFileExtensionArray];
        for (NSArray* lang in fea) {
            NSString *langName = [lang objectAtIndex:0];
            NSString *langTag = [lang objectAtIndex:1];
            [fileExtensionMap setObject:langTag forKey:langName.lowercaseString];
            for (int i = 2; i < [lang count]; i++) {
                NSString *ext = [lang objectAtIndex:i];
                [fileExtensionMap setObject:langTag forKey:ext.lowercaseString];
            }
        }
    }
    return fileExtensionMap;
}

+ (NSArray *) getSupportLanguageList {
    if (supportLanguageList == nil) {
        supportLanguageList = [[NSMutableArray alloc] init];
        NSArray *fea = [SHCodeGuesser getFileExtensionArray];
        for (NSArray* lang in fea) {
            NSString *langName = [lang objectAtIndex:0];
            [supportLanguageList addObject:langName];
        }
    }
    return supportLanguageList;
}

+ (NSString *) guessLangForExt:(NSString *)ext {
    NSDictionary *dict = [SHCodeGuesser getFileExtensionMap];
    return [dict objectForKey:ext.lowercaseString];
}

+ (NSString *) guessLangForFileName:(NSString *)filename {
    NSString *ext = filename.pathExtension;
    return [SHCodeGuesser guessLangForExt:ext];
}

+ (NSString *)addSlash:(NSString *)raw {
    NSMutableString *ms = [[NSMutableString alloc] init];
    for (int i = 0; i < raw.length; i++) {
        unichar c = [raw characterAtIndex:i];
        if (c == '"') {
            [ms appendString:@"\\\""];
        } else if (c == '\\') {
            [ms appendString:@"\\\\"];
        } else {
            [ms appendString:[NSString stringWithCharacters: &c length:1]];
        }
    }
    return ms;
}

@end

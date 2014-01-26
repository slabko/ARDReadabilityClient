# ARDReadabilityClient
`ARDReadabilityClient` is a simple API for the popular service, [Readability.com](http://readability.com/). The API allows to list users bookmarks, get article content, modify bookmarks, and a bit more. The API is based on `AFNetworking‘s` `AFHTTPClient` and [Readability web API](https://www.readability.com/developers/api/reader).

## Usage
First of all, you need to get your application’s customer key and customer secret. To do so, register your application by accessing the link [https://www.readability.com/developers/api](https://www.readability.com/developers/api) and grab your keys there. It takes only 2 minutes. After you obtain them it is time to start using `ARDReadabilityClient`.

Create an instance of `ARDReadabilityClient`:
```objective-c
readability = [[ARDReadabilityClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://www.readability.com/api/rest/v1/"]
                                                consumerKey:Your_Consumer_Key
                                             consumerSecret:Your_Cunsumer_Secret];
```

And authenticate the user:
```objective-c
[readability authenticateWithUserName:self.userNameTextField.text
                             password:self.passwordTextField.text
                              success:^(AFHTTPRequestOperation *operation, NSString *token, NSString *secret) {
                                  NSLog(@"User is authenticated!");
                            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                  //Something bad happens, check out the error
                                  NSLog("Failed to authenticate the user: %@", error);
                            }];
```

You will get a user’s token and a token secret. If you want to keep the user authentication between sessions, just save the received token and secret. 

> **Warning: Readability strongly recommends for the user’s password not to be stored anywhere.**

As such, the next time you need to create a new instance of `ARDReadabilityClient` for the same user, just use another initializer with the saved token and secret:
```objective-c
self.readability = [[ARDReadabilityClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://www.readability.com/api/rest/v1/"]
                                                           token:The_Token
                                                     tokenSecret:The_Secret
                                                     consumerKey:Your_Consumer_Key
                                                  consumerSecret:Your_Cunsumer_Secret];
```

After the `ARDReadabilityClient` acquires the user token and secret, it is ready to go. You can easily download the users’ list of bookmarks:
```objective-c
[self.readability bookmarksUpdatedSince:[NSDate distantPast] sucess:^(NSArray *opeations, NSArray *bookmarks) {
    foreach(ARDReadabilityBookmark *bookmark in bookmarks) {
        NSLog(@"%@", bookmark.articleTitle);
    }
} failure:^(AFHTTPRequestOperation *erroneousOpeation, NSError *error) {
    NSLog("Failed to get bookmarks: %@", error);
}];
```

Downloaded content of a particular article:
```objective-c
[self.readability articleContentByArticleId:self.articleId success:^(AFHTTPRequestOperation *operation, NSString *content) {
    NSLog(@"%@", content);
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog("Failed to get article content: %@", error);
}];
```
There are many other things, and all of them are very obvious to use. Just check out the `ARDReadabilityClient.h` file to discover them all. In the project, you can also find a simple example.

## Installation

[CocoaPods](http://cocoapods.org/) is the easiest way to add `ARDReadabilityClient` in your projects. 

Simply add to your Podfile:

    pod 'ARDReadabilityClient', '~> 0.1'

And run `pod update`

Another way way is to add `ARDReadabilityClient` to your project is to copy the `ARDReadabilityClient` folder to your project. In this case, `AFNetworking` version 1.3 should be added to the project. 

## Support
Please submit any issues, and I will work on them as fast as I can. Also, all pull requests that improve ARDReadabilityClient are welcomed.

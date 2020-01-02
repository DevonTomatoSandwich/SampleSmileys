# SampleSmileys
Tests non-consumable purchases of Smileys using @dooboolab 's plugin [flutter_inapp_purhcase](https://github.com/dooboolab/flutter_inapp_purchase)

## Why
Examples of how to use a purchasing system are hard to come by for any platform. Flutters own plugin for purchases is very lacking in examples so I thought I would use another plugin where I can at least make a start. dooboolab's plugin is pretty good for that and I'd like to share my own sample so others can quickly set up and test non-consumables.

Another reason I made this is because I ran out of iOS devices to test on. It is easy to reset a purcahse on Android but I'm not sure if it is possible on iOS. A way to get around this is do all your testing on Android first! This app also allows you to easily (*sort-of*) create more non-consumables (this comes with 5 already) in case you run out, so testing in iOS is not as bad but still bad...

## Free?
Yes! if you set everything up correctly yourself test purchases won't charge you

## What

![link3](https://github.com/DevonTomatoSandwich/SampleSmileys/blob/master/readmepics/small_screenshot_android.jpg)            ![link4](https://github.com/DevonTomatoSandwich/SampleSmileys/blob/master/readmepics/small_screenshot_ios.png)

The app has two sections: 
- The **green** section at the top shows a list of smileys. Each smiley has a name in the left column and graphic (or *art* as it is so called in the code) in the right column. The right column can either show the art if purchased, show a button to buy art if not purchased or show a button to restore purchase if restorable. Showing Restorable option is important if you want your device published in apple store. Also the first smiley is free.
- The **blue** section at the bottom shows a list of buttons that make it easier to debug the app. Exacly what each button does is explained aside it. Each of the buttons build on eachother for example pushing "Clear Purchases from Store" resets the store purchases on android then runs the same code as if pushing "Clear Purchases from Preference" which resets preferences then runs the same code as if pushing "Verify and refresh". The UI explains it better where the 1. and 2. represent events in order which happen when that button is pushed.

## So?

The advantage of having an app on the side like this is that you can debug the app yourself and understand what and when everything happens without ruining the code in your actual project. I'm copying across alot of the methods in this app so i can use them in my app straight away.

## Get Started

Ok setting this up is annoying as you may know the Play Developer Console (PDC) and App Store Connect (ASC) are bad UI experiences, some of which we pay alot of money for :)
Here are some tips to hopefully make the process faster. Firstly start testing on Android as you can reset the purchases easier

#### In your IDE
1. start a new flutter project called smileyfaces
1. copy pubspec file from the repo to your project
2. copy lib folder from repo to your project
3. run flutter pub get
4. replace all instances of `com.example.smileyfaces` with `com.mypackage.smileyfaces` (PDC whinges about example in the package ID)

#### On Android

To test on android your alpha or beta release needs to pass review. To be clear you don't need to put the app in production.
1. In `android/app/scr/main/AndroidManifest.xml`
Paste `<uses-permission android:name="com.android.vending.BILLING" />`
Between the manifest tag and the application tag
2. The key.properties file should be inside android folder and look something like this
```
storePassword=…
keyPassword=…
keyAlias=…
storeFile…/<yourkeys>.jks
```
3. Follow the steps under “Configure signing in gradle” [here](https://flutter.dev/docs/deployment/android#configure-signing-in-gradle) and save the build.gradle file
4. In terminal run
`flutter clean`
Then to make apk run
`flutter build apk`

   During the build the terminal might give you warnings on
   -	in_app_purchase: deprecated API
   -	in_app_purchase: unsafe operations
   -	shared_preferences: deprecated
   these can be ignored for now
5. When complete navigate to build/app/outputs/apk/release
6. Create a new app in the PDC
7. In PDC go to App releases and go to alpha you might be shown prompt “Let Google manage and protect your app signing key (recommended)” For the purpose of the example just press “OPT OUT”
8. drag app-release.apk into alpha release in the pdc
Hopefully you don’t get any errors uploading the build
Save the release but don’t review yet
9. In PDC go to in-app products / managed products. Click Create managed product with:
   - Product ID: smile2
   - Title: Nosey
   - Description: Buy the Nosey smiley
   - Status: active
   - Price: 1
   - Save
10. repeat step 9 for the other iaps (this is boring sorry) it should look like this
![iaps PDC](https://github.com/DevonTomatoSandwich/SampleSmileys/blob/master/readmepics/play_store_iap.png)
11. Add testers. Go to app releases. Next to alpha click manage.
See [here](https://support.google.com/googleplay/android-developer/answer/3131213) for more info on how to add testers
12. Finish filling out all the grey checkmarks on the left menu so you can rollout a test.
   This is really annoying
   Tips
    -	in content rating, set "Does the app allow users to purchase digital goods?" As yes but everything else as no
    -	in pricing and distribution say the app is free and select at least one country to be available
    -	in store listing you will need 2 screenshots (upload the same screenshot twice ^\_^ ) and a feature graphic. I have blank files you can use for your upload with the correct dimentions [here](https://github.com/DevonTomatoSandwich/SampleSmileys/tree/master/screenshots).
13. Now go back to App releases. Click edit release, click review
Check your warnings
-	You should ignore a warning about Unoptimized APK since this is just a test. Also flutter is having problems with Android App Bundle so just ignore this for now
Click rollout to alpha 
14. Send the opt in link to testers

#### On iOS
1. In [apple developer](https://developer.apple.com) Click account > Certificates, Identifiers & Profiles > Identifiers
and add an app id with
   - Description: Smiley Faces
   - Bundle ID: com.mypackage.smileyfaces
	 - Capabilities: game center and in-app purchase (defaulted and disabled)
2. In App Store Connect (ASC), Create a new app using the app id created above and description: Smiley Faces
3. Go to Features > In-App Purchases new non-consumable with
	 - Reference Name: Nosey
   - Product ID: smile2
   - Price: 0.99
   - Display Name: Nosey
   - Description: Buy the Nosey smiley
   - Add review picture
   - Review notes: Ignore image
   This IAP is just to test dooboolab 's flutter_inapp_purchase plugin.
   It is not intended for production
4. Repeat for the other 4 products. All 5 products should say “ready to submit”
5. Open xcode > open another project. Navigate to the path the project is in then > iOS > Runner.xcworkspace
	 - In targets > signing, select team
   - In capabilities turn in-app purchase to on
6. Upload a build to testflight
   - flutter build ios
   - in xCode product>archive
   - wait about 5 mins for email (ignore push notification warning in email)
   - Go to Testflight> builds > ios and your first build status should say processing (this can take 24 hours)
7. Add testers in the meantime. I create at least 1 user in App Store Connect Users
8. when status is "Ready to Test" you can debug with usb cable




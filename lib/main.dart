import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart'; // for prefs
import 'dart:io'; // for platform
import 'dart:async'; // for StreamSubscription
import 'package:samplefaces/info_dialog.dart'; // for dialog in UI
import 'package:samplefaces/smiley.dart'; // class for smiley data

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sample Faces',
      home: Scaffold(
        body: Start(),
      ),
    );
  }
}

class Start extends StatefulWidget {
  @override
  StartState createState() => StartState();
}

class StartState extends State<Start> {

  // It might take a while for the Dev Console or App Store Connect to review your build for testing
  // In the mean time you can set this to false and hot restart just to see how the UI works :)
  bool isUsingBilling = true;
  
  // This should not be changed in the current repo but in your real project change to false
  bool isSandbox = true;

  List<Smiley> smileys = [
    Smiley('Smiley' , ': )'      , ''      , true , false), // smiley always purchased (free smiley)
    Smiley('Nosey'  , ':-)'      , 'smile2', false, false),
    Smiley('Happy'  , ': D'      , 'smile3', false, false),
    Smiley('Toungy' , ': P'      , 'smile4', false, false),
    Smiley('Animaey', '^_^'      , 'smile5', false, false),
    Smiley('Kirby'  , '(>\'-\')>', 'smile6', false, false),
  ];

  bool isStoreReady = false;

  @override
  void initState() {
    asyncInitState();
    super.initState();
  }

  asyncInitState() async {
    print('asyncInitState');
    
    // first check the preferences or your db
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    bool allSmileysPurchased = true;
    for(Smiley smiley in smileys){
      if(smiley.name != 'Smiley'){
        // get purchase from prefs
        smiley.isPurchased = prefs.getBool(smiley.productID) ?? false;
        
        if(!smiley.isPurchased){ // check allSmileysPurchased
          allSmileysPurchased = false;
        }
      }
    }

    if(isUsingBilling){
      // for smileys that are not purchased in preferences, double check with the store to see if they can be restored
      if(!allSmileysPurchased){ // if there is at least one smiley not purchased
        isStoreReady = await getStorePurchases();
        verifyRestorableSmileys();
      }
    }
    else{
      isStoreReady = true;
    }

    refreshStartState();
  }

  // FIAP vars
  StreamSubscription _purchaseUpdatedSubscription;
  StreamSubscription _purchaseErrorSubscription;
  StreamSubscription _conectionSubscription;
  List<IAPItem> _items = [];
  List<PurchasedItem> _purchases = [];

  Future<bool> getStorePurchases() async {
    print('getStorePurchases');

    await FlutterInappPurchase.instance.initConnection;

    print('isStoreReady = $isStoreReady');
    if(!isStoreReady){

      _conectionSubscription = FlutterInappPurchase.connectionUpdated.listen((connected) {
        print('connected: $connected');
      });

      // todo SLOW_CARD fix slow test card issues on android
      _purchaseUpdatedSubscription = FlutterInappPurchase.purchaseUpdated.listen((purchasedItem) async {
        print('purchase-updated: $purchasedItem');
        
        try {
          
          // todo VALIDATE implement validateReceipt
          // validateReceipt(purchasedItem); // ? Question: should this be here
          
          String result = await FlutterInappPurchase.instance.finishTransaction( // this also verifies the purchase
            purchasedItem, 
            developerPayloadAndroid: purchasedItem.developerPayloadAndroid, 
            isConsumable: false
          );
          print('  result (from finishTransaction) = $result');
          
          Smiley smiley = smileys.firstWhere( (smiley) => smiley.productID == purchasedItem.productId, orElse: () => null);
          if(smiley != null){
            buySmiley(smiley);
          }
          else{
            throw Exception('There is no smiley with the productId. Make sure \'List<Smiley> smileys\' matches the products in the store.');
            
          }

        } 
        catch(err) {
          print('err.message = ${err.message}'); 
          if(err.message == 'E_DEVELOPER_ERROR'){
            MyInfoDialog(
              title: 'E_DEVELOPER_ERROR', 
              message: 'Google is indicating that we have some issue connecting to payment.',
            ).display(context);
          }
        }
      });

      _purchaseErrorSubscription = FlutterInappPurchase.purchaseError.listen((purchaseError) {
        print('purchase-error: $purchaseError');
        if(purchaseError.code == 'E_UNKNOWN'){
          print('This unknown error likely happens for when a card is declined immediately');
        }
      });
      
    }

    try{
      await _getProduct();
      await _getPurchases();
    }
    catch(err){
      print('error in _getProduct or _getPurchases. err.message = ${err.message}');
      if(err.message == 'E_SERVICE_ERROR'){
        MyInfoDialog(
          title: 'Service Issue', 
          message: 'The service is unreachable. This may be your internet connection, or the Play Store may be down.',
        ).display(context);
      }
      else if(err.message == 'Cancelled.'){ // iOS only
        MyInfoDialog(
          title: 'No Connection', 
          message: 'If you want to load any previous purchases you must sign into the app store and reload the app.',
        ).display(context);
      }
    }

    return true;
  }

  // todo VALIDATE setup validate Receipt
  validateReceipt(PurchasedItem purchasedItem) async {
    if(Platform.isIOS){
      var receiptBody = {
        'receipt-data': purchasedItem.transactionReceipt,
        //'password': '******' // ? Question: for iOS password is "Only used for receipts that contain auto-renewable subscriptions."
      };
      var result = await FlutterInappPurchase.instance.validateReceiptIos(
        receiptBody: receiptBody, 
        isTest: isSandbox
      );
      print(result);
    }
    else if(Platform.isAndroid){
      String accessToken; // todo VALIDATE setup getAccessToken()
      assert(accessToken != null);

      var result = await FlutterInappPurchase.instance.validateReceiptAndroid(
        packageName: 'com.mypackage.samplefaces', // ? Question: does my app id go here?
        productId: purchasedItem.productId,
        productToken: purchasedItem.purchaseToken, // ? Question: is this the same?
        accessToken: accessToken,
        isSubscription: false,
      );
      print(result);
    }
    
    
  }

  // ? Question: do we even need products for this application?
  Future _getProduct() async {
    print('_getProduct:');
    List<String> productLists = [];
    for(int i = 1; i < smileys.length; i++){
      productLists.add(smileys[i].productID);
    }
    
    try{
      List<IAPItem> items = await FlutterInappPurchase.instance.getProducts(productLists);

      print('IAPItem products:');
      for (var item in items) {
        print('  IAPItem{productId:${item.productId}, title:${item.title.substring(0, 10)}..., description:${item.description}, price:${item.currency} ${item.price}}');
        this._items.add(item);
      }

      setState(() {
        this._items = items;
        this._purchases = []; 
      });
    }
    catch(err){
      print('error in _getProduct. err.message = ${err.message}');
      if(err.message == 'Value not in range'){ // iOS only (i think)
        print('I can\'t get the products in iOS so I\'m just catching the error here and continuing');
      }
    }
    
  }

  Future _getPurchases() async {
    print('_getPurchases');
    List<PurchasedItem> items = await FlutterInappPurchase.instance.getAvailablePurchases();
    print('_getPurchases: (Short description)');
    for (var item in items) {
      print('  PurchasedItem{productId=${item.productId}, transactionId=${item.transactionId}, transactionDate=${item.transactionDate}}');
      this._purchases.add(item);
    }
    print('_getPurchases: (Long description)');
    for (var item in items) {
      print('  ${item.toString()}');
    }

    setState(() {
      this._items = [];
      this._purchases = items;
    });
    
  }

  // Having the user actually click a button that says "Restore Purchase" or something similar
  // is important in getting your iOS approved in the app store so verifyRestorableSmileys is actually needed
  verifyRestorableSmileys(){
    print('verifyRestorableSmileys');
    for(Smiley smiley in smileys){ // for each smiley
      smiley.isRestorable = false; // assume not restoreable
      if(!smiley.isPurchased){ // if the smiley is not purchased in the prefs
        for(PurchasedItem purchase in _purchases){ // for each purchaseItem
          if(smiley.productID == purchase.productId){ // if a purchased item matches the smiley
            smiley.isRestorable = true; // change it to restorable
          }
        }
      }
    }
  }

  verifyAndRefresh() async {
    if(isUsingBilling){
      await getStorePurchases(); // get any new purchases since the last call to getStorePurchases was made
      verifyRestorableSmileys();
    }

    refreshStartState();
  }

  clearPrefs() async {
    print('clearPrefs');
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for(Smiley smiley in smileys){ // for each smiley
      if(smiley.name != 'Smiley'){
        await prefs.setBool(smiley.productID, false); // the smiley is set to not purchased in the prefs
        smiley.isPurchased = false; // the smiley is changed to not purchased (setState yet to be called)
      }
    }

    // Since the store purchases will remain,
    // it is possible that some of the smileys are restoreable
    await verifyAndRefresh();
  }

  clearAndroidPurchases() async {
    print('clearAndroidPurchases');
    try {
      String msg = await FlutterInappPurchase.instance.consumeAllItems;
      print('consumeAllItems: $msg');
    } catch (err) {
      print('consumeAllItems error: $err');
    }
    
    // note in the next call to clearPrefs getStorePurchases() and verifyRestorableSmileys()
    // don't have any effect but easier to just call clearPrefs than write out the code again
    clearPrefs();
  }

  buySmiley(Smiley smiley) async {
    // save in prefs
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(smiley.productID, true);
  
    // set new state
    smiley.isPurchased = true;
    refreshStartState();
  }

  restoreSmiley(Smiley smiley) async {
    // save in prefs
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(smiley.productID, true);
    
    // set new state
    smiley.isPurchased = true;
    smiley.isRestorable = false;
    refreshStartState();
  }

  refreshStartState(){
    setState((){});
  }

  @override
  void dispose() async {
    print('StartState dispose');
    
    if(isUsingBilling){
      if (_conectionSubscription != null) {
        _conectionSubscription.cancel();
        _conectionSubscription = null;
      }
      _purchaseUpdatedSubscription.cancel();
      _purchaseUpdatedSubscription = null;
      _purchaseErrorSubscription.cancel();
      _purchaseErrorSubscription = null;
      
      await FlutterInappPurchase.instance.endConnection;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if(!isStoreReady){ // store is not setup
      return Center(child: Text('loading store ...'));
    }
    else{ // store is setup
      return Column(
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.fromLTRB(0, 20, 0, 0),
            leading: Container(width:100, child: Center(child: Text('Smiley Name'))),
            title: Center(child: Text('Smiley Graphic')),
          ),

          Container(
            color: Colors.lightGreenAccent,
            height: 200,
            child: ListView(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
              itemExtent: 40,
              children: <ListTile>[
                for(Smiley smiley in smileys)
                  ListTile(
                    leading: Container(width:100, child: Center(child: Text('${smiley.name} '))),
                    title: smiley.isPurchased ?
                      Center(child: Text('${smiley.art}'))
                      :
                      FlatButton(
                        color: Colors.blueAccent,
                        onPressed: () async {
                          if(smiley.isRestorable){
                            print('Restore ${smiley.name} Purchase clicked');
                            restoreSmiley(smiley);
                          }
                          else{
                            print('Buy ${smiley.name} clicked');
                          
                            if(isUsingBilling){
                              await getStorePurchases(); // incase connection not initilised
                              await FlutterInappPurchase.instance.requestPurchase(smiley.productID); // if no internet, plugin shows error dialog
                              // if a purchase is made jump to purchaseUpdated.listen
                            }
                            else{
                              buySmiley(smiley);
                            }
                          }
                        },
                        child: smiley.isRestorable ? Text('Restore ${smiley.name} Purchase') : Text('Buy ${smiley.name}'),
                      )
                    ,
                  ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: Colors.lightBlueAccent,
              child: ListView(
                padding: EdgeInsets.all(0),
                children: <ListTile>[

                  if(isUsingBilling)
                    ListTile(
                      leading: Container(width:150, child: FlatButton(
                        color: Colors.cyanAccent,
                        onPressed: verifyAndRefresh,
                        child: Container(child: Text('Verify and Refresh'),),
                      ),),
                      title: Center(child: Text('1. Retrieves the store purchases again incase a connection ' +
                      'is not initialised and verifies if any of the smileys are restoreable.\n' +
                      '2. Updates the state',
                        style: TextStyle(fontSize: 12),)),
                    ),
                    
                  ListTile(
                    leading: Container(width:150, child: FlatButton(
                      padding: const EdgeInsets.all(0), // black magic
                      color: Colors.cyanAccent,
                      onPressed: clearPrefs,
                      child: Container(child: Text('Clear Purcahses from Preferences'),),
                    ),),
                    title: Container(width:150, child: Center(child: Text(
                      '1. Resets each smiley as not purchased in the local shared preferences. \n2. Same as \"Verify and Refresh\"',
                      style: TextStyle(fontSize: 12),))),
                  ),

                  if(isUsingBilling)
                    ListTile(
                      leading: Container(width:150, child: FlatButton(
                        color: Colors.cyanAccent,
                        onPressed: (){
                          clearAndroidPurchases();
                          if(Platform.isIOS){
                            MyInfoDialog(
                              title: 'Store Purchases Unchanged', 
                              message: 'This only works for Android purchases. The local prefs have been cleared though.',
                            ).display(context);
                          }
                        },
                        child: Container(child: Text('Clear Purchases from Store'),),
                      ),),
                      title: Center(child: Text('1. Resets the store purchases if android device (does nothing on iOS).\n' +
                        '2. Same as \"Clear Purchases from Preferences\"',
                        style: TextStyle(fontSize: 12),)),
                    ),

                ],
              ),
            ),
          ),

        ],
      );
    }
  }
}

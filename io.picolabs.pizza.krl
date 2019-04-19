ruleset io.picolabs.pizza {
  meta {
    shares __testing, nearestStore, findMenu, parseMenu, findDescriptions, getDescription, findVariants, getPrice, practice, getToppings, getStoreID, getStoreAddress, getVariants, getMenu, getDefaultToppings,
          getProductCart, parseVariants, getParsedVariants, getOrderDescription, getOrderTitle, getChildrenOrders, getChildName, parseToppings, reverseToppings, getToppingsMap, combineItems
     use module io.picolabs.wrangler alias wrangler
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }, {"name": "nearestStore", "args": ["address", "location", "type"]}, {"name": "findMenu", "args":["StoreID"]}, 
      {"name": "findDescriptions", "args":["StoreID"]}, {"name": "getDescription"}, {"name": "findVariants", "args":["StoreID"]}, {"name": "getPrice", "args":["item"]},
      {"name": "practice"}, {"name": "getToppings", "args":["item"]}, {"name": "getMenu"}, {"name": "getVariants"}, {"name":"getDefaultToppings", "args":["item"]}, {"name": "parseVariants"},
      {"name": "getParsedVariants"}, {"name": "getProductCart"}, {"name": "getChildName", "args":["eci"]}, {"name": "parseToppings"}, {"name": "reverseToppings"}, {"name": "getToppingsMap"},
      {"name": "combineItems"}
        //{ "name": "parseMenu", "args": ["menu"]}
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ { "domain": "find", "type": "store", "attrs": ["street","city","state","zipcode","firstname","lastname","phone","email","type"]}, { "domain": "store", "type": "menu"},
        {"domain": "create", "type": "order", "attrs": ["street","city","state","zipcode","first_name","last_name","phone","email","type"]},
        {"domain": "val", "type": "order" }, {"domain": "place", "type": "order" }, {"domain": "echo", "type": "clear"}, {"domain":"add", "type":"Item"}, {"domain":"remove", "type":"Item"}
      //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    practice = function() {
     street = ent:customer{"Address"}{"Street"};
     street
    }
    
    getProductCart = function() {
      ent:Products;
    }
    
    removeItem = function(code, toppings, qty) {
      array = ent:Products.filter(function(x){
        x["Options"].klog("x");
        toppings.klog("toppings");
        
        (x["Code"] != code || x["Options"] != toppings.decode() ).klog("result")
        
      });
      array.klog("array");
      array
    }
    
    isIncluded = function(item) {
      included = ent:Products.map(function(x) {
        (x["Code"] == item["Code"] && x["Options"].encode() == item["Options"].encode()) => true | false;
      });
      (included >< true).klog("isIncluded return");
    }
    
    combineItems = function(item) {
      combined = not isIncluded(item) => ent:Products.append(item) | ent:Products.map(function(x) {
        x.klog("x");
        item.klog("item");
        (x["Code"] == item["Code"] && x["Options"].encode() == item["Options"].encode()) => x.set(["Qty"], x["Qty"].as("Number") + item["Qty"].as("Number")) | x;
      });
      combined
    }
    
    changeQty = function(item, qty) {
      products = ent:Products.map(function(x) {
        x["Code"].klog("x[Code]");
        item["Code"].klog("item[Code]");
        x["Options"].encode().klog("x[Options]");
        item["Options"].encode().klog("item[Options]");
        (x["Code"] == item["Code"] && x["Options"].encode() == item["Options"].encode()) => x.set(["Qty"], qty.decode()) | x;
      });
      products
    }
    
    nearestStore = function(address, location, type) {
      http:get(<<https://order.dominos.com/power/store-locator?s=#{address}&c=&#{location}type=#{type}">>, parseJSON=true).klog("StoreIDCall")
    }
    
    getStoreID = function() {
      ent:StoreID;
    }
    
    getStoreAddress = function() {
      ent:StoreAddress;
    }
    
    findStoreAddress = function(address, location, type) {
      http:get(<<https://order.dominos.com/power/store-locator?s=#{address}&c=#{location}type=#{type}">>, parseJSON=true)["content"]["Stores"][0]["AddressDescription"].klog("StoreAddressCall")
    }
    
    findVariants = function(StoreID) {
      http:get(<<https://order.dominos.com/power/store/#{StoreID}/menu?lang=en&structured=true>>, parseJSON=true)
      ["content"]["Variants"]
    }
    
    getVariants = function() {
      ent:Variants;
    }
    
    findMenu = function(StoreID) {
      http:get(<<https://order.dominos.com/power/store/#{StoreID}/menu?lang=en&structured=true>>, parseJSON=true)
    }
    
    getMenu = function() {
      ent:Menu;
    }
    
    parseMenu = function(menu) {
      parsed = menu.reduce(function(counter, val) {
        val{"Products"} > 0 => counter.put(val{"Name"}, val{"Products"}) | counter.put(parseMenu(val{"Categories"}))
      }, {});
      parsed
    }
    
    findDescriptions = function(StoreID) {
      http:get(<<https://order.dominos.com/power/store/#{StoreID}/menu?lang=en&structured=true>>, parseJSON=true)
      ["content"]["Products"]
    }
    
    getDescription = function(item) {
      ent:AllDescriptions;
    }
    
    getPrice = function(item) {
      variants = findVariants(ent:StoreID);
      price = ((variants.values().filter(function(x){x{"Code"} == item;}).map(function(x){ some_hash = {}.put(x["Name"],x["Price"]); some_hash}))); 
      price;
    }
    
    getDefaultToppings = function(item) {
      variants = ent:Variants;
      defToppings = ((variants.values().filter(function(x){x{"Code"} == item;}).map(function(x){ array = x["Tags"]["DefaultToppings"].split(re#,#); array})));
      defToppings[0]
    }
    
    parseToppingTags = function(toppings) {
      toppings.klog("toppings");
      otherMap = {};
      arrayMap = toppings.values().map(function(x) {
        x.values().map(function(y){
          y.klog("the y");
          otherMap.put(y["Code"], y["Tags"]).klog("otherMap")
        });
      });
      array = arrayMap.reduce(function(counter, val){
        val => counter.append(val) | noop()
      }, []);
      
      parsed = array.reduce(function(counter, val){
        val => counter.put(val) | noop()
      }, {});
      parsed
    }
    
    parseToppings = function(toppings) {
      toppings.klog("toppings");
      otherMap = {};
      arrayMap = toppings.values().map(function(x) {
        x.values().map(function(y){
          y.klog("the y");
          otherMap.put(y["Code"], y["Name"]).klog("otherMap")
        });
      });
      array = arrayMap.reduce(function(counter, val){
        val => counter.append(val) | noop()
      }, []);
      
      parsed = array.reduce(function(counter, val){
        val => counter.put(val) | noop()
      }, {});
      parsed
    }
    
    reverseToppings = function(toppings) {
      toppings.klog("toppings");
      otherMap = {};
      arrayMap = toppings.values().map(function(x) {
        x.values().map(function(y){
          y.klog("the y");
          otherMap.put(y["Name"], y["Code"]).klog("otherMap")
        });
      });
      array = arrayMap.reduce(function(counter, val){
        val => counter.append(val) | noop()
      }, []);
      
      parsed = array.reduce(function(counter, val){
        val => counter.put(val) | noop()
      }, {});
      parsed
    }
    
    getToppingsMap = function() {
      map = {};
      toppingMap = map.put("toppings", ent:Toppings).put("reverse", ent:reverseToppings).put("tags", ent:ToppingTags);
      toppingMap;
    }
    
    orderCreation = function(Address, Amounts, BusinessDate, Coupons, Currency, CustomerID, Email, EstimatedWaitMinutes, Extension, 
        FirstName, LastName, Market, metaData, NewUser, NoCombine, OrderID, OrderTaker, Partners, Payments, Phone, PriceOrderTime, Products, ServiceMethod, StoreID, Tags) {
      map = {"Order" : {"Address" : Address, "Amounts" : Amounts, "BusinessDate" :  BusinessDate, "Coupons" : Coupons, "Currency" : Currency, "CustomerID" : CustomerID, 
        "Email" : Email, "EstimatedWaitMinutes" :  EstimatedWaitMinutes, "Extension" : Extension, "FirstName" : FirstName, "LanguageCode" : language, "LastName" : LastName, 
        "Market" : Market, "metaData" : metaData, "NewUser" : NewUser, "NoCombine" : NoCombine, "OrderChannel" : orderChannel, "OrderID" : OrderID, "OrderMethod" : orderMethod, 
        "OrderTaker" : null, "Partners" : Partners, "Payments" : Payments, "Phone" : Phone, "PriceOrderTime" : PriceOrderTime, "Products" : Products.decode(), "ServiceMethod" : ServiceMethod, 
        "SourceOrganizationURI" : sourceUri, "StoreID" : StoreID, "Tags" : Tags, "Version" : version }};
      map
    }
    
    validate = function(order) {
      http:post("https://order.dominos.com/power/validate-order", form = order)
    }
    
    parseVariants = function(product) {
      product.klog("product");
      array = product.split(",");
      parsed = ent:Variants.filter(function(x) {
        x.klog("x");
        array.map(function(y){ y }) >< x["Code"]
      });
      parsed
    }
    
    getParsedVariants = function() {
      ent:ParsedVariants;
    }
    
    getOrderDescription = function() {
      ent:OrderDescription;
    }
    
    getOrderTitle = function() {
      ent:OrderTitle;
    }
    
    getChildrenOrders = function() {
      ent:Children;
    }
    
    getChildInfo = function(eci) {
      children = wrangler:children().klog("children");
      name = children.filter(function(x){
        x["eci"] == eci
      });
      name[0]
    }
    
    removeFromList = function(eci) {
      array = ent:Children.filter(function(x) {
        x != eci
      });
      array
    }
    
    sourceUri = "order.dominos.com"
    language = "en"
    orderMethod = "Web"
    orderChannel = "OLO"
    version = "1.0"
    
     app = { "name":"Dominos Pizza", "version":"0.0" };
  }
  
  rule discovery {
  select when manifold apps
  send_directive("app discovered...",
                          {
                            "app": app,
                            "iconURL": "data:image/png;base64,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",
                            "bindings" : {}
                          } );
}
  
  rule storeLocator {
    select when find store
    pre {
      address = event:attr("street") + " " + event:attr("city") + " " + event:attr("state") + ", " + event:attr("zipcode");
      first_name = event:attr("firstname").klog("fname");
      last_name = event:attr("lastname").klog("lname");
      phone = event:attr("phone").klog("phone");
      email = event:attr("email").klog("email");
      location = event:attr("zipcode").klog("location");
      type = event:attr("type").klog("type");
      Store = nearestStore(address, location,type).klog("storeID");
      StoreID = Store["content"]["Stores"][0]["StoreID"]
      storeAddress = Store["content"]["Stores"][0]["AddressDescription"].klog("store address");
      orderEdit = event:attr("edit").defaultsTo(false);
    }
      send_directive(StoreID);
   always {
     ent:StoreID := StoreID;
     ent:StoreAddress := storeAddress;
     map = {"Address" : {"Street" : event:attr("street"), "City" : event:attr("city"), "Region" : event:attr("state"), "PostalCode" : event:attr("zipcode")}, "first_name" : first_name, "last_name" : last_name, "phone" : phone, "email" : email, "service_method" : type };
     ent:customer := map;
     ent:orderEdit := orderEdit;
     ent:Products := (ent:orderEdit == true) => ent:Products | null;
     ent:Products := (ent:Products.isnull()) => ent:Products.defaultsTo([]) | ent:Products;
     raise store event "menu"
   }
  }
  
  rule storeMenu {
    select when store menu
    pre {
      fullCall = findMenu(ent:StoreID);
      menu = fullCall["content"]["Categorization"]["Food"]["Categories"];
      variants = fullCall["content"]["Variants"];
      descriptions = fullCall["content"]["Products"];
      allToppings = fullCall["content"]["Toppings"];
    }
    always {
     ent:AllDescriptions := descriptions;
     ent:Menu := parseMenu(menu);
     ent:Variants := variants;
     ent:ToppingTags := parseToppingTags(allToppings);
     ent:Toppings := parseToppings(allToppings);
     ent:reverseToppings := reverseToppings(allToppings);
     ent:practice := "blah!"
    }
  }
  
  rule addItem {
    select when add Item
    pre {
      Code = event:attr("item")
      Qty = event:attr("Qty")
      ID = 1
      isNew = true
      AutoRemove = false
      options = event:attr("options")
    }
    always {
       ent:Options := options;
       ent:Products := combineItems({"AutoRemove" : AutoRemove, "Code" : Code, "ID" : ID, "isNew" : isNew, "Options" : ent:Options.decode(), "Qty" : Qty.decode()});
    }
  }
  
  rule changeQuantity {
    select when change qty
    pre {
      item = event:attr("item").decode()
      qty = event:attr("qty")
    }
    always {
      ent:Products := changeQty(item, qty)
    }
  }
  
  rule removeItem {
    select when remove Item
    pre {
      code = event:attr("code");
      toppings = event:attr("toppings");
      qty = event:attr("qty");
    }
    always {
      ent:Products := removeItem(code, toppings, qty);
    }
  }
  
  rule createOrder {
    select when create order
    pre {
      City = ent:customer{"Address"}{"City"};
      Street = ent:customer{"Address"}{"Street"};
      State = ent:customer{"Address"}{"Region"};
      Zip = ent:customer{"Address"}{"PostalCode"};
      Type = "House";
      Address = {"Type" : Type, "Street" : Street, "City" : City, "Region" : State, "PostalCode" : Zip};
      Amounts = {};
      BusinessDate = "";
      Coupons = [];
      Currency = "";
      CustomerID = "";
      Email = ent:customer{"email"};
      EstimatedWaitMinutes = "";
      Extension = "";
      FirstName = ent:customer{"first_name"};
      LastName = ent:customer{"last_name"};
      Market = "";
      metaData = {};
      NewUser = true;
      NoCombine = true;
      OrderID = "";
      OrderTaker = null;
      Partners = {};
      Payments = [];
      Phone = ent:customer{"phone"};
      PriceOrderTime = "";
      Products = ent:Products;
      ServiceMethod = ent:customer{"service_method"};
      StoreID = ent:StoreID;
      Tags = {};
    }
    always {
      ent:Order := orderCreation(Address, Amounts, BusinessDate, Coupons, Currency, CustomerID, Email, EstimatedWaitMinutes, Extension, 
        FirstName, LastName, Market, metaData, NewUser, NoCombine, OrderID, OrderTaker, Partners, Payments, Phone, PriceOrderTime, Products, ServiceMethod, StoreID, Tags);
        ent:OrderTitle := event:attr("title");
        ent:OrderDescription := event:attr("description");
        raise val event "order"
    }
    
  }
  
  rule setOrder {
    select when set order
    pre {
      products = event:attr("products").decode()
      order = event:attr("order").decode()
      street = order["Order"]["Address"]["Street"]
      city =  order["Order"]["Address"]["City"]
      state = order["Order"]["Address"]["Region"]
      zipcode = order["Order"]["Address"]["PostalCode"]
      first_name = order["Order"]["FirstName"];
      last_name = order["Order"]["LastName"];
      phone = order["Order"]["Phone"];
      email = order["Order"]["Email"];
      location = "locationName=";
      type = order["Order"]["ServiceMethod"];
      editEci = event:attr("eci")
    }
    always {
      ent:Products := products;
      ent:editEci := editEci;
      raise find event "store"
        attributes {
          "street": street,
          "city": city,
          "state": state,
          "zipcode": zipcode,
          "firstname": firstname,
          "lastname": lastname,
          "phone": phone,
          "email": email,
          "type": type,
          "edit": true
        };
    }
  }
  
  rule validateOrder {
    select when val order
     pre {
       
     }
      http:post("https://order.dominos.com/power/validate-order", json = ent:Order.decode()) setting(result)
     
     always {
       ent:ParsedVariants := parseVariants();
       ent:Result := result;
       raise child event "order";
     }
  }
  
  rule createChildOrder {
    select when child order
    pre{
      
    }
      if  (not ent:orderEdit) && ent:Result["status_code"] == 200 then 
      send_directive("The order was validated");
    fired {
      raise wrangler event "child_creation"
        attributes {
          "name": ent:OrderTitle,
          "rids": "Order"
        }
    } else {
        raise edit event "order"
    }
  }
  
  rule setChildOrder {
    select when wrangler child_initialized
    pre {
      childEci = event:attr("eci");
    }
    event:send({"eci": childEci, "domain":"set", "type":"order", "attrs":{"order": ent:Order.decode(), "title": ent:OrderTitle, "description": ent:OrderDescription}})
    always {
      ent:Children := ent:Children.defaultsTo([]).append(childEci);
      raise echo event "clear";
    }
  }
  
  rule editChildOrder {
    select when edit order
    pre {
      
    }
      event:send({"eci": ent:editEci, "domain":"set", "type":"order", "attrs":{"order": ent:Order, "title": ent:OrderTitle, "description": ent:OrderDescription}})
    always {
      raise echo event "clear";
    }
  }
  
  rule deleteChildOrder {
    select when delete order
    pre {
      eci = event:attr("eci")
      name = getChildInfo(eci)["name"]
      id = getChildInfo(eci)["id"]
    }
    
    always {
      raise wrangler event "child_deletion"
        attributes {
          "name": name,
          "id": id
        };
      ent:Children := removeFromList(eci);
    }
  }
  
  rule setActiveOrder {
    select when active order
    pre {
      
    }
    always {
      ent:ActiveOrder :=  event:attr("order").decode();
    }
  }
  
  
  rule placeOrder {
    select when place order
    pre{
      
    }
    http:post("https://order.dominos.com/power/place-order", json = ent:ActiveOrder) setting(result)
    
    always {
      ent:Result := result;
    }
  }
  
  
  rule clearAll {
    select when echo clear
    pre {
    }
    fired {
      clear ent:Options;
      clear ent:Products;
      clear ent:Order;
      clear ent:OrderTitle;
      clear ent:OrderDescription;
      clear ent:practice;
      ent:orderEdit := false;
    }
  }
  
  
  
  
  
  
  
  
}

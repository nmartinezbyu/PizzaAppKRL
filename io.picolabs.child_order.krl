ruleset io.picolabs.child_order {
  meta {
    shares __testing, getOrderTitle, getOrderDescription, getProductCart, getOrder
     use module io.picolabs.wrangler alias wrangler
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    getOrder = function() {
      map = {"title": ent:OrderTitle, "description":ent:OrderDescription, "order": ent:Order};
      map;
    }
    
    getProductCart = function() {
      ent:Products.klog("products");
    }
    
    getOrderDescription = function() {
      map = {"title": ent:OrderTitle, "description":ent:OrderDescription, "active": ent:Active};
      map;
    }
    
    getOrderTitle = function() {
      ent:OrderTitle;
    }
    
    
  }

  rule setOrder {
    select when set order
    pre {
    }
    always {
      ent:Order := event:attr("order");
      ent:Products := ent:Order["Order"]["Products"];
      ent:OrderTitle := event:attr("title");
      ent:OrderDescription := event:attr("description");
      ent:Active := "false";
    }
  }
  
  rule changeActvie {
    select when change active
    pre {
      
    }
    always {
      ent:Active := event:attr("active");
      raise send event "order"
    }
  }
  
  rule sendOrder {
    select when send order
    pre {
      parentEci =  wrangler:parent_eci();
    }
    if ent:Active == "true" then 
      event:send({"eci": parentEci, "domain":"active", "type":"order", "attrs":{"order": ent:Order}})
    fired {
      
    }
  }
  
}

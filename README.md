# TinyJSON

Lightweight JSON processing lib inspired by SwiftyJSON. 
Uses same approach for traversing and getting values.
Designed to be as thin as possible, yet easily usable with Codables.

Pro:

+ internally uses native Swift types (SwiftyJSON extensively uses its NS counterparts). Only NSNull is used to represent JSON nulls.

+ zero construction cost - created structs never go to heap, having less than 3 payload values.

+ never gets in the way when you utilize Swift features like optionals.

+ fails early and loudly, allowing you to see *where* errors are occured.

+ allows to work with JSON just like JavaScript does: 

```Swift
    let name = json.data.entries[0].name.string               // new
    let oldName = json["data"]["entries"][0]["name"].string   // old
```

Contra: 

- ~does not allow to change underlying JSON data~ now it does!

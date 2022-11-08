# CloudLang

<hr>

## cloudlib.prg
This is the Visual Foxpro interface to interop with clouldlang service.

Example: the following gets the service version.

```xBase
? cloudlib_version()
```

Example 2: parsing JSON
The following retrieves an Visual Foxpro equivalent object of the Json string provided.

```xBase
text to lcJsonStr noshow
{
  "name": "John",
  "last_name": "Lennon",
  "dob": "1940-10-09 Liverpool",  
  "songs": ["Bless you", "My Life", "Stand by Me"]
}
endtext
myJson = cloudlib_parseJSON(lcJsonStr)
? myJson.entry1.key   // name
? myJson.entry1.value // "John"
? myJson.entry2.key   // last_name
? myJson.entry2.value // "Lennon"
? myJson.entry3.key   // dob
? myJson.entry3.value // "1940-10-09 Liverpool"

// print array of songs
? myJson.entry4.value.item1 // "Bless you"
? myJson.entry4.value.item2 // "My Life"
? myJson.entry4.value.item3 // "Stand by Me"
```

## What is an Entry?

The example above showed some helper properties like `entry1, item1, key and value`, let's explain each of them:

1. Entry: this is a special object that holds your json pair `key-value`, your result object will have as many entries as your JSON data contain. This object let you examine either the `key` or `value` by typing: `object.entry1.key` or `object.entry1.value`.
2. Item: this is a representation of an array's elements. You must inspect each element by typing: `object.entry1.item1`
3. Key: the key of your `key-value` pair.
4. Value: the actual value of your `key-value` pair.

# CloudLang

<hr>
**cloudlib.prg** this is the Visual Foxpro interface to interop with clouldlang service.

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

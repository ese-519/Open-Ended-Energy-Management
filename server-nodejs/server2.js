var express = require('express')
var app = express()

var MongoClient = require('mongodb').MongoClient

app.get('/', function (req, res) {
  console.log('Got a request')

  var r

  MongoClient.connect('mongodb://localhost:27017/energydata', function (err, db) {
    if (err) throw err

    db.collection('searchbin_results').find( { "_id" : "000000000000000000000001" }).toArray(function (err, result) {
      if (err) throw err

      console.log("Result: " + result)
      r = result
    })
  })
  res.send(r)
})

app.listen(8080, function () {
  console.log('Example app listening on port 8080!')
})

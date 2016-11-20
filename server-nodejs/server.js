var http = require('http'); 
var path = require('path');
var mongodb = require('mongodb');
var fs = require('fs');

const PORT = 8080;

/*
var MongoClient = mongodb.MongoClient;

var url = 'mongodb://localhost:27017/energydata';

function get_data()
{
  MongoClient.connect(url, function (err, db) {
  if (err) {
    console.log('Unable to connect to the mongoDB server. Error:', err);
  }
  else {
    //HURRAY!! We are connected. :)
    console.log('Connection established to', url);

    // Get the documents collection
    var collection = db.collection('searchbin_results');

    //Create some users
    //var user1 = {name: 'modulus admin', age: 42, roles: ['admin', 'moderator', 'user']};
    //var user2 = {name: 'modulus user', age: 22, roles: ['user']};
    //var user3 = {name: 'modulus super admin', age: 92, roles: ['super-admin', 'admin', 'moderator', 'user']};

    // Insert some users
    //collection.insert([user1, user2, user3], function (err, result) {
    //  if (err) {
    //    console.log(err);
    //  }
    //  else {
    //    console.log('Inserted %d documents into the "users" collection. The documents inserted with "_id" are:', result.length, result);
    //  }
        //Close connection

      
      db.close();
    });
  }
  });
}
*/

function requestHandler(req, res) {
  var content = '';
  var fileName = path.basename(req.url); // the requested file
  console.log('Request for ' + fileName + ' received.');
  var localDir = __dirname + '/public/'; // where we are storing our files

  if (fileName === 'favicon.ico') {
    res.writeHead(200, {'Content-Type': 'image/x-icon'});
    res.end();
    console.log('favicon requested');
  } else if (fileName === 'index.html' || fileName === 'chart.html') {
    content = localDir + fileName;

    fs.readFile(content, function(err, contents) {
      if (err) {
        console.log(err);
      } else {
        
        // calling function to query mongodb

        //get_data();

        // page found, http status: 200 ok
        res.writeHead(200, {'Content-Type': 'text/html'});
        // write file contents to response body and close the response
        res.end(contents);
      }
    });
  } else {
    // http status: 404 not found
    res.writeHead(404, {'Content-Type': 'text/html'});
    res.end('<h1>404: Page not found</h1>');
  }
};

var server = http.createServer(requestHandler);

console.log('Server listening on port ' + PORT + '...'); 
server.listen(PORT);



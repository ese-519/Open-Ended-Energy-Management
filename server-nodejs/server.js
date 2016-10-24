var http = require('http'); 
var path = require('path');
var fs = require('fs');

const PORT = 8080; 

function requestHandler(req, res) {
  var content = '';
  var fileName = path.basename(req.url); // the requested file
  console.log('Request for ' + fileName + ' received.');
  var localDir = __dirname + '/public/'; // where we are storing our files

  if (fileName === 'favicon.ico') {
    res.writeHead(200, {'Content-Type': 'image/x-icon'});
    res.end();
    console.log('favicon requested');
  } else if (fileName === 'index.html') {
    content = localDir + fileName;

    fs.readFile(content, function(err, contents) {
      if (err) {
        console.log(err);
      } else {
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



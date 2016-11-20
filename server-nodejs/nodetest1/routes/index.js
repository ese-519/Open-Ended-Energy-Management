var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res) {
    var db = req.db;
    var collection = db.get('searchbin_results');
    collection.find( {  "_id" : "000000000000000000000001" },{},function(e,docs){
        console.log("Resulting docs: " + JSON.stringify(docs))
        console.log("Resulting docs: " + JSON.stringify(docs[0]))
        res.render('main', {
            "data" : docs[0]
         });
    });
});

module.exports = router;

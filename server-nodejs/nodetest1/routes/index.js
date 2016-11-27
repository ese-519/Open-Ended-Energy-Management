var express = require('express');
var router = express.Router();

var searchbin_data = null;
var baseline_data = null;
var pagename_data = null;
var db = null;


/* GET home page. */
router.get('/', function(req, res) {
    
    function doRender()
    {
         if(searchbin_data !== null && baseline_data !== null && pagename_data !== null)
         { 
            res.render(pagename_data.name, {
                 "searchbin_data" : searchbin_data, "baseline_data" : baseline_data
            });
         }
    }

    db = req.db;
    var searchbin_collection = db.get('searchbin_results');
    searchbin_collection.find( { "_id" : 1 },{},function(e,docs){
         searchbin_data = docs[0];
         doRender();
    });

    var baseline_collection = db.get('baseline_data');
    baseline_collection.find({"$or": [{ "_id" : 1 }, { "_id": 2 }] },{},function(e,docs2){
         baseline_data = docs2[0];
         if (docs2.length > 1) {
            predicted_data = docs2[1];
         } else {
            predicted_data = [];
         }
         doRender();
    });

    var pagename_collection = db.get("pagename");
    pagename_collection.find( {"_id": 1}, {}, function(e, docs3) {
      console.log(pagename_collection.name);
      pagename_data = docs3[0];
      doRender();
   });
});
module.exports = router;

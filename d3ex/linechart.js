/*
############# LINE CHART ##################
-------------------------------------------
*/

var datasetLineChart = [
{ group: "All", category: 2008, measure: 289309 }, 
{ group: "All", category: 2009, measure: 234998 }, 
{ group: "All", category: 2010, measure: 310900 }, 
{ group: "All", category: 2011, measure: 223900 }, 
{ group: "All", category: 2012, measure: 234500 }, 
{ group: "Sam", category: 2008, measure: 81006.52 }, 
{ group: "Sam", category: 2009, measure: 70499.4 }, 
{ group: "Sam", category: 2010, measure: 96379 }, 
{ group: "Sam", category: 2011, measure: 64931 }, 
{ group: "Sam", category: 2012, measure: 70350 }, 
{ group: "Peter", category: 2008, measure: 63647.98 }, 
{ group: "Peter", category: 2009, measure: 61099.48 }, 
{ group: "Peter", category: 2010, measure: 87052 }, 
{ group: "Peter", category: 2011, measure: 58214 }, 
{ group: "Peter", category: 2012, measure: 58625 }, 
{ group: "Rick", category: 2008, measure: 23144.72 }, 
{ group: "Rick", category: 2009, measure: 14099.88 }, 
{ group: "Rick", category: 2010, measure: 15545 }, 
{ group: "Rick", category: 2011, measure: 11195 }, 
{ group: "Rick", category: 2012, measure: 11725 }, 
{ group: "John", category: 2008, measure: 34717.08 }, 
{ group: "John", category: 2009, measure: 30549.74 }, 
{ group: "John", category: 2010, measure: 34199 }, 
{ group: "John", category: 2011, measure: 33585 }, 
{ group: "John", category: 2012, measure: 35175 }, 
{ group: "Lenny", category: 2008, measure: 69434.16 }, 
{ group: "Lenny", category: 2009, measure: 46999.6 }, 
{ group: "Lenny", category: 2010, measure: 62180 }, 
{ group: "Lenny", category: 2011, measure: 40302 }, 
{ group: "Lenny", category: 2012, measure: 42210 }, 
{ group: "Paul", category: 2008, measure: 7232.725 }, 
{ group: "Paul", category: 2009, measure: 4699.96 }, 
{ group: "Paul", category: 2010, measure: 6218 }, 
{ group: "Paul", category: 2011, measure: 8956 }, 
{ group: "Paul", category: 2012, measure: 9380 }, 
{ group: "Steve", category: 2008, measure: 10125.815 }, 
{ group: "Steve", category: 2009, measure: 7049.94 }, 
{ group: "Steve", category: 2010, measure: 9327 }, 
{ group: "Steve", category: 2011, measure: 6717 }, 
{ group: "Steve", category: 2012, measure: 7035 }
]
;

// set initial category value
var group = "All";

function datasetLineChartChosen(group) {
  var ds = [];
  for (x in datasetLineChart) {
     if(datasetLineChart[x].group==group){
      ds.push(datasetLineChart[x]);
     } 
    }
  return ds;
}

function dsLineChartBasics() {

  var margin = {top: 20, right: 10, bottom: 0, left: 50},
      width = 500 - margin.left - margin.right,
      height = 150 - margin.top - margin.bottom
      ;
    
    return {
      margin : margin, 
      width : width, 
      height : height
    }     
    ;
}


function dsLineChart() {

  var firstDatasetLineChart = datasetLineChartChosen(group);    
  
  var basics = dsLineChartBasics();
  
  var margin = basics.margin,
    width = basics.width,
     height = basics.height
    ;

  var xScale = d3.scale.linear()
      .domain([0, firstDatasetLineChart.length-1])
      .range([0, width])
      ;

  var yScale = d3.scale.linear()
      .domain([0, d3.max(firstDatasetLineChart, function(d) { return d.measure; })])
      .range([height, 0])
      ;
  
  var line = d3.svg.line()
      //.x(function(d) { return xScale(d.category); })
      .x(function(d, i) { return xScale(i); })
      .y(function(d) { return yScale(d.measure); })
      ;
  
  var svg = d3.select("#lineChart").append("svg")
      .datum(firstDatasetLineChart)
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      // create group and move it so that margins are respected (space for axis and title)
      
  var plot = svg
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")")
      .attr("id", "lineChartPlot")
      ;

    /* descriptive titles as part of plot -- start */
  var dsLength=firstDatasetLineChart.length;

  plot.append("text")
    .text(firstDatasetLineChart[dsLength-1].measure)
    .attr("id","lineChartTitle2")
    .attr("x",width/2)
    .attr("y",height/2) 
    ;
  /* descriptive titles -- end */
      
  plot.append("path")
      .attr("class", "line")
      .attr("d", line)  
      // add color
    .attr("stroke", "lightgrey")
      ;
    
  plot.selectAll(".dot")
      .data(firstDatasetLineChart)
       .enter().append("circle")
      .attr("class", "dot")
      //.attr("stroke", function (d) { return d.measure==datasetMeasureMin ? "red" : (d.measure==datasetMeasureMax ? "green" : "steelblue") } )
      .attr("fill", function (d) { return d.measure==d3.min(firstDatasetLineChart, function(d) { return d.measure; }) ? "red" : (d.measure==d3.max(firstDatasetLineChart, function(d) { return d.measure; }) ? "green" : "white") } )
      //.attr("stroke-width", function (d) { return d.measure==datasetMeasureMin || d.measure==datasetMeasureMax ? "3px" : "1.5px"} )
      .attr("cx", line.x())
      .attr("cy", line.y())
      .attr("r", 3.5)
      .attr("stroke", "lightgrey")
      .append("title")
      .text(function(d) { return d.category + ": " + formatAsInteger(d.measure); })
      ;

  svg.append("text")
    .text("Performance 2012")
    .attr("id","lineChartTitle1") 
    .attr("x",margin.left + ((width + margin.right)/2))
    .attr("y", 10)
    ;

}

/* updates line chart on request */
function updateLineChart(group, colorChosen) {

  var currentDatasetLineChart = datasetLineChartChosen(group);   

  var basics = dsLineChartBasics();
  
  var margin = basics.margin,
    width = basics.width,
     height = basics.height
    ;

  var xScale = d3.scale.linear()
      .domain([0, currentDatasetLineChart.length-1])
      .range([0, width])
      ;

  var yScale = d3.scale.linear()
      .domain([0, d3.max(currentDatasetLineChart, function(d) { return d.measure; })])
      .range([height, 0])
      ;
  
  var line = d3.svg.line()
    .x(function(d, i) { return xScale(i); })
    .y(function(d) { return yScale(d.measure); })
    ;

   var plot = d3.select("#lineChartPlot")
    .datum(currentDatasetLineChart)
     ;
     
  /* descriptive titles as part of plot -- start */
  var dsLength=currentDatasetLineChart.length;
  
  plot.select("text")
    .text(currentDatasetLineChart[dsLength-1].measure)
    ;
  /* descriptive titles -- end */
     
  plot
  .select("path")
    .transition()
    .duration(750)          
     .attr("class", "line")
     .attr("d", line) 
     // add color
    .attr("stroke", colorChosen)
     ;
     
  var path = plot
    .selectAll(".dot")
     .data(currentDatasetLineChart)
     .transition()
    .duration(750)
     .attr("class", "dot")
     .attr("fill", function (d) { return d.measure==d3.min(currentDatasetLineChart, function(d) { return d.measure; }) ? "red" : (d.measure==d3.max(currentDatasetLineChart, function(d) { return d.measure; }) ? "green" : "white") } )
     .attr("cx", line.x())
     .attr("cy", line.y())
     .attr("r", 3.5)
     // add color
    .attr("stroke", colorChosen)
     ;
     
     path
     .selectAll("title")
     .text(function(d) { return d.category + ": " + formatAsInteger(d.measure); })   
     ;  

}

dsLineChart();
/*
############# PIE CHART ###################
-------------------------------------------
*/
function dsPieChart(){

  var dataset = [
      {category: "Sam", measure: 0.30},
        {category: "Peter", measure: 0.25},
        {category: "John", measure: 0.15},
        {category: "Rick", measure: 0.05},
        {category: "Lenny", measure: 0.18},
        {category: "Paul", measure:0.04},
        {category: "Steve", measure: 0.03}
        ]
        ;

  var   width = 400,
       height = 400,
       outerRadius = Math.min(width, height) / 2,
       innerRadius = outerRadius * .999,   
       // for animation
       innerRadiusFinal = outerRadius * .5,
       innerRadiusFinal3 = outerRadius* .45,
       color = d3.scale.category20()    //builtin range of colors
       ;
      
  var vis = d3.select("#pieChart")
       .append("svg:svg")              //create the SVG element inside the <body>
       .data([dataset])                   //associate our data with the document
           .attr("width", width)           //set the width and height of our visualization (these will be attributes of the <svg> tag
           .attr("height", height)
          .append("svg:g")                //make a group to hold our pie chart
           .attr("transform", "translate(" + outerRadius + "," + outerRadius + ")")    //move the center of the pie chart from 0, 0 to radius, radius
        ;
        
   var arc = d3.svg.arc()              //this will create <path> elements for us using arc data
          .outerRadius(outerRadius).innerRadius(innerRadius);
   
   // for animation
   var arcFinal = d3.svg.arc().innerRadius(innerRadiusFinal).outerRadius(outerRadius);
  var arcFinal3 = d3.svg.arc().innerRadius(innerRadiusFinal3).outerRadius(outerRadius);

   var pie = d3.layout.pie()           //this will create arc data for us given a list of values
        .value(function(d) { return d.measure; });    //we must tell it out to access the value of each element in our data array

   var arcs = vis.selectAll("g.slice")     //this selects all <g> elements with class slice (there aren't any yet)
        .data(pie)                          //associate the generated pie data (an array of arcs, each having startAngle, endAngle and value properties) 
        .enter()                            //this will create <g> elements for every "extra" data element that should be associated with a selection. The result is creating a <g> for every object in the data array
            .append("svg:g")                //create a group to hold each slice (we will have a <path> and a <text> element associated with each slice)
               .attr("class", "slice")    //allow us to style things in the slices (like text)
               .on("mouseover", mouseover)
            .on("mouseout", mouseout)
            .on("click", up)
            ;
            
        arcs.append("svg:path")
               .attr("fill", function(d, i) { return color(i); } ) //set the color for each slice to be chosen from the color function defined above
               .attr("d", arc)     //this creates the actual SVG path using the associated data (pie) with the arc drawing function
          .append("svg:title") //mouseover title showing the figures
           .text(function(d) { return d.data.category + ": " + formatAsPercentage(d.data.measure); });      

        d3.selectAll("g.slice").selectAll("path").transition()
          .duration(750)
          .delay(10)
          .attr("d", arcFinal )
          ;
  
    // Add a label to the larger arcs, translated to the arc centroid and rotated.
    // source: http://bl.ocks.org/1305337#index.html
    arcs.filter(function(d) { return d.endAngle - d.startAngle > .2; })
        .append("svg:text")
        .attr("dy", ".35em")
        .attr("text-anchor", "middle")
        .attr("transform", function(d) { return "translate(" + arcFinal.centroid(d) + ")rotate(" + angle(d) + ")"; })
        //.text(function(d) { return formatAsPercentage(d.value); })
        .text(function(d) { return d.data.category; })
        ;
     
     // Computes the label angle of an arc, converting from radians to degrees.
    function angle(d) {
        var a = (d.startAngle + d.endAngle) * 90 / Math.PI - 90;
        return a > 90 ? a - 180 : a;
    }
        
    
    // Pie chart title      
    vis.append("svg:text")
        .attr("dy", ".35em")
        .attr("text-anchor", "middle")
        .text("Revenue Share 2012")
        .attr("class","title")
        ;       


    
  function mouseover() {
    d3.select(this).select("path").transition()
        .duration(750)
              //.attr("stroke","red")
              //.attr("stroke-width", 1.5)
              .attr("d", arcFinal3)
              ;
  }
  
  function mouseout() {
    d3.select(this).select("path").transition()
        .duration(750)
              //.attr("stroke","blue")
              //.attr("stroke-width", 1.5)
              .attr("d", arcFinal)
              ;
  }
  
  function up(d, i) {
  
        /* update bar chart when user selects piece of the pie chart */
        //updateBarChart(dataset[i].category);
        updateBarChart(d.data.category, color(i));
        updateLineChart(d.data.category, color(i));
       
  }
}

dsPieChart();
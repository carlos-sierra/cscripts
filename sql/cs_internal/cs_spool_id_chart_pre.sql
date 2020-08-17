PRO ]);;
PRO
PRO var options = {&&is_stacked.
--PRO chartArea:{left:90, top:75, width:'75%', height:'70%'},
PRO chartArea:{left:&&cs_chartarea_left., top:&&cs_chartarea_top., width:'&&cs_chartarea_width.', height:'&&cs_chartarea_height.'},
PRO backgroundColor: {fill: 'white', stroke: '#336699', strokeWidth: 1},
PRO &&cs_curve_type. curveType: 'function',
PRO &&cs_chart_option_explorer. explorer: {actions: ['dragToZoom', 'rightClickToReset'], maxZoomIn: 0.01},
PRO &&cs_chart_option_pie. sliceVisibilityThreshold: 0.5/100, pieHole: 0.4, is3D: false,
PRO &&cs_chart_pie_slice_text.
PRO title: '&&chart_title.',
PRO titleTextStyle: {fontSize: 18, bold: false},
--PRO focusTarget: 'category',  //focusTarget:[{datum}|category]
PRO focusTarget: '&&cs_chart_option_focustarget.',
PRO legend: {position: 'right', textStyle: {fontSize: 14}},
PRO tooltip: {textStyle: {fontSize: 14}},
PRO &&cs_trendlines. trendlines: {type: '&&cs_trendlines_type.', degree: 2, lineWidth:10, opacity:0.2 &&cs_trendlines_series. }, //type:[{linear}|polynomial|exponential]
--PRO hAxis: {title: '&&xaxis_title.', gridlines: {count: -1}, titleTextStyle: {fontSize: 16, bold: false}},
PRO hAxis: {title: '&&xaxis_title.', titleTextStyle: {fontSize: 16, bold: false}, &&hAxis_maxValue. minorGridlines: {count: -1}, gridlines: {count: -1, units: {months: {format: 'yyyy-MM-dd'}, days: {format: 'MM-ddTHH'}, hours: {format: 'ddTHH:mm'}, minutes: {format: 'HH:mm:ss'}, seconds: {format: 'mm:ss'}}}},
PRO &&cs_oem_colors_series. series: { 0: { color :'#34CF27'}, 1: { color :'#0252D7'},  2: { color :'#1E96DD'},  3: { color :'#CEC3B5'},  4: { color :'#EA6A05'},  5: { color :'#871C12'},  6: { color :'#C42A05'}, 7: {color :'#75763E'},
PRO &&cs_oem_colors_series. 8: { color :'#594611'}, 9: { color :'#989779'}, 10: { color :'#C6BAA5'}, 11: { color :'#9FFA9D'}, 12: { color :'#F571A0'}, 13: { color :'#000000'}, 14: { color :'#ff0000'}},
PRO &&cs_oem_colors_slices. slices: { 0: { color :'#34CF27'}, 1: { color :'#0252D7'},  2: { color :'#1E96DD'},  3: { color :'#CEC3B5'},  4: { color :'#EA6A05'},  5: { color :'#871C12'},  6: { color :'#C42A05'}, 7: {color :'#75763E'},
PRO &&cs_oem_colors_slices. 8: { color :'#594611'}, 9: { color :'#989779'}, 10: { color :'#C6BAA5'}, 11: { color :'#9FFA9D'}, 12: { color :'#F571A0'}, 13: { color :'#000000'}, 14: { color :'#ff0000'}},
PRO vAxis: {title: '&&vaxis_title.' &&vaxis_baseline. &&vaxis_viewwindow., gridlines: {count: -1}, titleTextStyle: {fontSize: 16, bold: false}}
PRO };;
PRO
PRO var date_formatter = new google.visualization.DateFormat({pattern: 'yyyy-MM-ddTHH:mm:ss UTC'});;
PRO date_formatter.format(data, 0);;
PRO
PRO var chart = new google.visualization.&&cs_chart_type.Chart(document.getElementById('chart_div'));;
PRO
PRO chart.draw(data, options);;
PRO };;
PRO </script>
PRO </head>
PRO <body>
PRO <h1>&&report_title.</h1>

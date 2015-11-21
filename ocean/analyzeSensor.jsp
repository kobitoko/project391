<%@ page import="java.util.*, java.sql.*"%>
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Ocean Observation System</title>
</head>
<link rel="stylesheet" type="text/css" href="oceanstyler.css">
<script src="imports.js"></script>
<script src="analyzeSensor.js"></script>
<script>permission = 'scientist';</script>
 <body style="background:lightblue;">
 <div id='header' style="height:50px;border-style:inset;"></div>
 <div id='content'>
<p id="caption"></p>

<%
Integer grabYR = 0;
Integer grabQU = 0;
Integer grabMO = 0;
Integer grabWK = 0;
Integer grabDY = 0;
Integer sid = null;
Integer pid = null;
//Based on tutorials at http://www.tutorialspoint.com/
Cookie cookie = null;
Cookie[] cookies = null;
String compsid = "modsid";
String comppid = "pid";
String compYR = "olapYR";
String compQU = "olapQU";
String compMO = "olapMO";
String compWK = "olapWK";
String compDY = "olapDY";
String sortPref = "";
String ssetPref = "";
cookies = request.getCookies();
   if( cookies != null ){
	 for (Integer i = 0; i < cookies.length; i++){
         	cookie = cookies[i];
		if(cookie.getName().equals(comppid)){pid = Integer.parseInt(cookie.getValue());}
		if(cookie.getName().equals(compsid)){sid = Integer.parseInt(cookie.getValue());}
		if(cookie.getName().equals(compYR)){grabYR = Integer.parseInt(cookie.getValue());}
		if(cookie.getName().equals(compQU)){grabQU = Integer.parseInt(cookie.getValue());}
		if(cookie.getName().equals(compMO)){grabMO = Integer.parseInt(cookie.getValue());}
		if(cookie.getName().equals(compWK)){grabWK = Integer.parseInt(cookie.getValue());}
		if(cookie.getName().equals(compDY)){grabDY = Integer.parseInt(cookie.getValue());}
}
}

	String createOLAPview = "CREATE OR REPLACE VIEW OLAP_DATA AS SELECT s.sensor_id, EXTRACT (YEAR from s.date_created) AS Year, to_char(s.date_created, 'Q') AS Quarter, EXTRACT (MONTH FROM s.date_created) AS Month, to_char(s.date_created,'IW') AS Week, EXTRACT (DAY from s.date_created) AS Day, AVG(s.value) AS Average, MIN(s.value) AS Minimum, MAX(s.value) AS Maximum FROM scalar_data s WHERE s.sensor_id IN (SELECT sensor_id FROM subscriptions WHERE person_id = 7777) AND s.sensor_id = '22' GROUP BY s.sensor_id, ROLLUP(EXTRACT (YEAR from s.date_created), to_char(s.date_created, 'Q'), EXTRACT (MONTH FROM s.date_created), to_char(s.date_created,'IW') , EXTRACT (DAY from s.date_created))";

	String queryYears = "Select distinct year from olap_data ORDER BY year";

	String queryAll = "select YEAR, AVERAGE, MINIMUM, MAXIMUM from OLAP_DATA where QUARTER IS NULL";
	String queryYear = "select QUARTER, AVERAGE, MINIMUM, MAXIMUM from OLAP_DATA where YEAR = " + grabYR + " AND MONTH IS NULL AND WEEK IS NULL";
	String queryQuarter = "select MONTH, AVERAGE, MINIMUM, MAXIMUM from OLAP_DATA where QUARTER = " + grabQU + " AND YEAR = " + grabYR + " AND WEEK IS NULL AND DAY IS NULL";
	String queryMonth = "select DAY, AVERAGE, MINIMUM, MAXIMUM from OLAP_DATA where QUARTER = " + grabQU + " AND YEAR = " + grabYR + " AND MONTH = " + grabMO +" AND (DAY IS NOT NULL OR WEEK IS NULL)";
	String queryWeek = "select DAY, AVERAGE, MINIMUM, MAXIMUM from OLAP_DATA where QUARTER = " + grabQU + " AND YEAR = " + grabYR + " AND WEEK = " + grabWK;
	String queryDay = "select DAY, AVERAGE, MINIMUM, MAXIMUM from OLAP_DATA where QUARTER = " + grabQU + " AND YEAR = " + grabYR + " AND DAY = " + grabDY;

	String outQuery = "";
	if(grabYR != 0){
		if(grabQU != 0){
			if(grabMO != 0){
				if(grabDY != 0){
					outQuery = queryDay;
					sortPref = "Day " + Integer.toString(grabDY) + " of Month " + Integer.toString(grabMO) + " of " + Integer.toString(grabYR);
					ssetPref = "Day ";
				} else {
					outQuery = queryMonth;
					sortPref = "Month " + Integer.toString(grabMO) + " of " + Integer.toString(grabYR);
					ssetPref = "Day ";
				}
			} else if(grabWK != 0){
				if(grabDY != 0){
					outQuery = queryDay;
					sortPref = "Day " + Integer.toString(grabDY) + " of Month " + Integer.toString(grabMO) + " of " + Integer.toString(grabYR);
					ssetPref = "Day ";
				} else {
					outQuery = queryWeek;
					sortPref = "Week " + Integer.toString(grabWK) + " of " + Integer.toString(grabYR);
					ssetPref = "Day ";
				}
			} else {
				outQuery = queryQuarter;
				sortPref = "Quarter " + Integer.toString(grabQU) + " of " + Integer.toString(grabYR);
				ssetPref = "Month ";
			}			
		} else { 
			outQuery = queryYear;
			sortPref = Integer.toString(grabYR);
			ssetPref = "Quarter ";
		}	
	} else { 
		outQuery = queryAll;
		sortPref = "All Data";
	}
Boolean debug = Boolean.TRUE;
     
      String mUrl = "jdbc:oracle:thin:@gwynne.cs.ualberta.ca:1521:CRS";
      String mDriverName = "oracle.jdbc.driver.OracleDriver";
      
      String mUser = "satyabra";
      String mPass = "adasfa42";
      
      Connection mCon;
      Statement stmnt;
      PreparedStatement pstmnt;
      
      // instantiate the driver.
      try {
          Class drvClass = Class.forName(mDriverName);
          DriverManager.registerDriver((Driver) drvClass.newInstance());
      } catch(Exception e) {
          System.err.print("ClassNotFoundException: ");
          System.err.print(e.getMessage());
          if(debug)
            out.println("<BR>-debugLog: Received a ClassNotFoundException: " + e.getMessage());
      }
      
      // actually log in and perform statements
try {
          mCon = DriverManager.getConnection(mUrl, mUser, mPass);
          stmnt = mCon.createStatement();
	  stmnt.executeQuery(createOLAPview);
          ResultSet rset = stmnt.executeQuery(queryYears);
          %><select id="year" onchange='updateRollup()'><option id="emptyYR" value="0">Ignore Year</option> <%
	  while(rset.next()) {
	      
              Integer year = new Integer(rset.getInt(1));
		String tID = "yr" + year;
              %><option id="<%= tID%>" value="<%= year%>"><%= year%></option><%
}
%></select><%
  	 
%>
<select id="quarter" onchange='updateRollup()'>
<option value="0" id="emptyQU">Ignore Quarter</option>
<%
for(int i =1;i<5;i++){
	String tID = "qu" + i;
     %><option id="<%= tID%>" value="<%= i%>">Quarter <%= i%></option><%
}

%></select>
<select id="month" onchange='updateRollup()'>
<option value="0" id="emptyMO">Ignore Month</option>
<option id="mo1" value="1">January</option>
<option id="mo2" value="2">February</option>
<option id="mo3" value="3">March</option>
<option id="mo4" value="4">April</option>
<option id="mo5" value="5">May</option>
<option id="mo6" value="6">June</option>
<option id="mo7" value="7">July</option>
<option id="mo8" value="8">August</option>
<option id="mo9" value="9">September</option>
<option id="mo10" value="10">October</option>
<option id="mo11" value="11">November</option>
<option id="mo12" value="12">December</option>
</select>

<select id="week" onchange='updateRollupWK()'>
<option value="0" id="emptyWK">Ignore Week</option>
<%
for(int i =1;i<54;i++){
     String tID = "wk" + i;
     %><option id="<%= tID%>" value="<%= i%>">Week <%= i%></option><%
}

%></select>

<select id="day" onchange='updateRollup()'>
<option value="0" id="emptyDY">Ignore Day</option>
<%
for(int i =1;i<32;i++){
     String tID = "dy" + i;
     %><option id="<%= tID%>" value="<%= i%>">Day <%= i%></option><%
}

%></select>
<script>


var setYR = "yr<%= grabYR%>";
var setQU = "qu<%= grabQU%>";
var setMO = "mo<%= grabMO%>";
var setWK = "wk<%= grabWK%>";
var setDY = "dy<%= grabDY%>";
var genString = "Viewing Sensor Data for Sensor <%=sid %>, Showing records for: ";
var outString = "";
if(setQU != "qu0"){
	document.getElementById(setQU).selected = 'selected';
	outString =  "Quarter <%= grabQU%> of ";
} else { 
	document.getElementById("emptyQU").selected = 'selected';
}
if(setMO != "mo0"){
	document.getElementById(setMO).selected = 'selected';
	outString = "Month <%= grabMO%> of ";
} else { 
	document.getElementById("emptyMO").selected = 'selected';
}
if(setWK != "wk0"){
	document.getElementById(setWK).selected = 'selected';
	outString = "Week <%= grabWK%> of ";
} else { 
	document.getElementById("emptyWK").selected = 'selected';
}
if(setDY != "dy0"){
	document.getElementById(setDY).selected = 'selected';
	outString = "Day <%= grabDY%> in " + outString;
	
} else { 
	document.getElementById("emptyDY").selected = 'selected';
}



if(setYR != "yr0"){
	document.getElementById(setYR).selected = 'selected';
	outString = outString + "<%= grabYR%>";
} else { 
	document.getElementById("emptyYR").selected = 'selected';
	outString =  "all of history";
}
document.getElementById("caption").innerHTML = genString + outString;




</script>
<button onClick="updateOLAPcookies()" style="background-color:green;color:white;display:inline;">Update Analysis</button>
      <table style="width:100%;border-style:inset";>


	<tr>
<col width="20px">
<col width="20px">
<col width="20px">
<col width="20px">
<col width="20px">

    	<th>Filter From</th>
    	<th>Subset</th>
   	 <th>AVG</th>
	<th>MIN</th>
	<th>MAX</th>
	</tr>
<%  
 	rset = stmnt.executeQuery(outQuery);
	
	while(rset.next()) {
		Integer sset = new Integer(rset.getInt(1));
		Integer avg = new Integer(rset.getInt(2));
		Integer min = new Integer(rset.getInt(3));
		Integer max= new Integer(rset.getInt(4));
	
		String open = "<td>";
           	 String close = "</td>";
	    	 String tropen = "<tr>";
	   	 String trclose = "</tr>";	
		out.println( tropen + open + sortPref + close + open + ssetPref + sset + close + open + avg + close + open + min +  close + open + max + close + trclose);
			


}

 	  stmnt.close();
          mCon.close();
          
      } catch(SQLException ex) {
          if (debug)
            out.println("<BR>-debugLog: Received a SQLException: " + ex.getMessage());
          System.err.println("SQLException: " + ex.getMessage());
      }  
%></table>


</div>
</div>
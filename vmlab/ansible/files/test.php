<html>
<head>
<title>Demo</title>
<link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;900&display=swap" rel="stylesheet">
<style>
table, th, td {
  border-bottom: 1px solid black;
  padding: 10px;
  border-collapse: collapse;
  text-align: left;
}
.center {
  margin-left: auto;
  margin-right: auto;
}
h1 {
  text-align: center;
  font-size: 50px;
}
* {
  font-family: Montserrat;
  font-size: 20px;
  
}
</style>
</head>
<body>
<h1>Database Query Demo</h1>

<?php
// Variables
$db_host='127.0.0.1';
$db_user='appuser';
$db_name='appdb';
$db_password='let me in';
$db_table='tweet';

// Connecting, selecting database
$connection = new mysqli($db_host, $db_user, $db_password, $db_name);

if ($connection->connect_error) {
	die("<p>Could not connect to database server:</p>" . $connection->connect_error);
}

// Performing SQL query
$query = "SELECT * FROM $db_table ORDER BY ts DESC";
$result = $connection->query($query);

// Printing results in HTML
echo "<table class=\"center\">\n\t<tr><th>user_id</th><th>timestamp</th><th>message</th></tr>\n";
while ($row = $result->fetch_assoc()) {
    echo "\t<tr>\n";
    echo "\t\t<td>" . $row["user_id"] . "</td>\n";
    echo "\t\t<td>" . $row["ts"] . "</td>\n";
    echo "\t\t<td>" . $row["message"] . "</td>\n";
    echo "\t</tr>\n";
}
echo "</table>\n";

// Free resultset
$result->close();
// Closing connection
$connection->close();
?>
</body>

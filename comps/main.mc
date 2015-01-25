<%class>
has 'uri_prefix';
has 'content';
</%class>
<html>
  <head>
    <title>boards</title>
    <link rel="stylesheet" href="main.css"/>
    <script type="text/javascript" src="main.js"></script>
  </head>
  <body>
    <div class="container">
      <div class="site">
        <header class="header">
          <h1 class="title"><a href="<% $.uri_prefix %>/">boards</a></h1>
          <a class="extra" href="#">stuff</a>
        </header>

        <% $.content %>
      </div>
    </div>
  </body>
</html>

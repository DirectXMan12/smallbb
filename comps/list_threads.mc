<%class>
has 'uri_prefix';
has 'threads';
</%class>

% foreach my $thread (@{$.threads}) {
    <div>
        <p><a href="<% $.uri_prefix %>/<% $thread->{id} %>/"><% $thread->{topic} %></a></p>
        <p class="meta">by <% $thread->{author} %>
% if ($thread->{mtime}) {
        last post <% $thread->{mtime} %>
% }
        </p>
    </div>
% }

<div>
    <input type="button" id="show_form" value="New Thread">
    <form name="newThreadForm" action="new_thread" method="post" id="form">
        Title: <input name="title"/>
        Username: <input name="username"/>
        <input type="submit" value="Post"/>
    </form>
</div>

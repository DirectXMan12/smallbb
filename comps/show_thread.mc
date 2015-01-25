<%class>
has 'posts';
has 'max_post_length';
</%class>

% foreach my $post (@{$.posts}) {
    <div>
        <p class="meta">Posted by <% $post->{author} %> on <% $post->{ctime} %></p>
        <p class="post"><% $post->{post} %></p>
    </div>
% }

<input type="button" id="show_form" value="New post"/>
<form name="replyForm" action="reply" method="post" id="form">
    <p>Username: <input name="username" /></p>
    <p><textarea name="post" cols="60" rows="7" maxlength="<% $.max_post_length %>"></textarea></p>
    <input type="submit" value="Post"/>
</form>

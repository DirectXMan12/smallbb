#!/usr/bin/perl
# TODO:
#  add IP's to posts
#  add IP's to accounts
#  add sticky threads
#  remove public core dumps
use warnings;
use strict;
use Plack::Request;
use DBI;
my $debug = 0;
if ($debug) {
	use Data::Dumper qw(Dumper);
	$Data::Dumper::Sortkeys = 1;
}
use HTML::Escape qw(escape_html);
use Mason;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

# App uri and name are used in the main loop and to write out proper links
my $app_uri	 = '';
my $app_name	 = 'board';
my $disp_threads = 15;	# -1 for all
my $disp_posts	 = 20;	# -1 for all
my $max_post_length = 5000;
my $uri_prefix = "$app_uri/$app_name";

my $dbfile = 'boards.db';	# Boards database
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile",
	"", "",
	{RaiseError=>1},
) or die $DBI::errstr;

my $base_dir = dirname(abs_path(__FILE__));
my $mason_interp = Mason->new(comp_root => "$base_dir/comps", data_dir => "$base_dir/data");

sub list_threads {
	my $response = "";
	my $sth = $dbh->prepare("SELECT * FROM threads ORDER BY mtime DESC LIMIT ?");
	$sth->execute($disp_threads);
	my $threads = $sth->fetchall_arrayref({});
	$sth->finish();

	return $mason_interp->run('/list_threads', threads => $threads, uri_prefix => $uri_prefix)->output;
}

sub get_thread {
	my $thread = shift;
	my $response = "";
	my $sth = $dbh->prepare("SELECT * FROM posts WHERE THREAD = ? AND hidden IS NULL ORDER BY id ASC LIMIT ?");
	$sth->execute($thread, $disp_posts);
	my $posts = $sth->fetchall_arrayref({});
	$sth->finish();

	return $mason_interp->run('/show_thread', posts => $posts, uri_prefix => $uri_prefix)->output;
}

sub new_post {
	# FIXME: Display some 'working' message before redirect
	my $env = shift;
	my $thread = shift;
	my $req = Plack::Request->new($env);
	my $response = "";

	# Enforce our $max_post_length rule.
	# Select 0-$max_post_length characters along a word boundary and group it.
	# Treat the whole string as a single line.
	(my $post) = ($req->param('post') =~ /^(.{0,$max_post_length})\b.*$/s);
	# Empty usernames default to Anonymous Coward
	# Empty posts default to bumps
	my $sth = $dbh->prepare("INSERT INTO posts (thread,post,author) VALUES(?,?,?)");
	$sth->execute($thread, escape_html($post) || "<i class=\"meta\">bump</i>", escape_html($req->param('username')) || "Anonymous Coward");

	$sth->finish();
	return $response;
}

sub new_thread {
	# FIXME: Display some 'working' message before redirect
	my $env = shift;
	my $req = Plack::Request->new($env);
	my $response = "";

	# Empty usernames default to Anonymous Coward
	# Empty threads are useless, just abort
	if ($req->param('title')) {
		my $sth = $dbh->prepare("INSERT INTO threads (topic,author) VALUES(?,?)");
		$sth->execute(escape_html($req->param('title')), escape_html($req->param('username')) || "Anonymous Coward");
		$sth->finish();
	}

#	# FIXME: Huge race here
#	$sth = $dbh->prepare("SELECT id FROM threads ORDER BY ctime DESC LIMIT 1");
#	$sth->execute();
#
#	return &get_thread($sth->fetch());

	return &list_threads();
}

sub throw_404 {
	return [404, ['Content-Type'=>'text/html'], ['404 Not Found']];
}

my $content_types = { 'css' => 'css', 'js' => 'javascript' };

my $app = sub {
	my $env = shift;
	my $content = '';
	print Dumper($env) . "\n" if ($debug);	# Log the incoming headers

	$env->{PATH_INFO} =~ s/$app_uri\/$app_name//;
	if ($env->{PATH_INFO} eq '/') {
		# Root of the app, thread index goes here
		$content = &list_threads();
	} elsif (my ($static_file, $ext) = ($env->{PATH_INFO} =~ /.*\/(.+?\.(css|js))$/)) {
		# Serve up our css manually so we don't rely on the web server
		# Needs to be at the top of the chain to catch sub paths
		open my $fh, "<", $static_file or return &throw_404();
		my $content_type = $content_types->{$ext};
		return [200, ['Content-Type'=> "text/$content_type"], $fh];
	} elsif ($env->{PATH_INFO} =~ /new_thread$/ && $env->{REQUEST_METHOD} eq 'POST') {
		# We only care about POSTs, don't let people come here with a GET
		$content = new_thread($env);
	} elsif (my ($thread) = ($env->{PATH_INFO} =~ /^\/(\d+)/)) {
		# Assign the regex groups (\d+) to the variables list
		# Hijack /reply links
		# Then fall through to display the thread with the new post
		# We only care about POSTs, don't let people come here with a GET
		# FIXME: double-post protection
		$content = new_post($env, $thread) if ($env->{PATH_INFO} =~ /reply$/ && $env->{REQUEST_METHOD} eq 'POST');
		# Grab a list of threads that corresponds to our forum
		$content .= &get_thread($thread);
	} else {
		# Send everything else a 404 page
		return &throw_404();
	}

	my $page = $mason_interp->run('/main', uri_prefix => $uri_prefix, content => $content)->output;

	return [200, ['Content-Type'=>'text/html'], [$page]];
};

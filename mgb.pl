#!/usr/local/bin/perl -w
use CGI qw(:standard);
#######################################################################
#   MGB (MULTI-USER GUEST BOOK) ver 1.2
#   Written by Ruslan Ulanov (aka RUS GraFX). Started: 02.XII.1998
#   Updates and manuals available at http://come.to/RUS.GraFX
#   Questions and Comments direct to rus.grafx@usa.net
#   You can use MGB for free, but DO PLEASE LEAVE THESE COMMENTS!!!
#######################################################################

#######################################################################
# Section 1. User defined variables
# Path to where all users guestbooks stored
$BooksPath = "/users/host.com/guestbook";
# URL to books dir from web browser
$BooksURL= "http://www.host.com/guestbook";
# Mail program location (needed for sending notification letter only)
$mailprog = "/usr/lib/sendmail";
# Section 1. End of user defined variables
#######################################################################
#          !!! DO NOT MODIFY BELLOW THIS LINE !!!
#######################################################################
# Section 2. System variables
$Version = "Multi-user Guest Book ver 1.2";
import_names('R'); #Import parameters from page into namespace $R
$User = $R::User; #User of guestbook (getting from page hidden parameter)
$R::required =~ s/(\s+|\n)?,(\s+|\n)?/,/g;
$R::required =~ s/(\s+)?\n+(\s+)?//g;
@Required = split(/,/,$R::required);
$space = '&nbsp;&nbsp;&nbsp;';

&GetDate;
&CheckRequired;
&ProcessBook;
&EmailNotify;
&ExitRedirect;
exit 0;
#######################################################################
# Subroutines section
#######################################################################
sub CheckRequired{ #if there are Required fields - check them
local($req_field, @error);
 
 if (!$R::User) { &error('User'); } # _User_ is MUST BE field!
 if (!-e "$BooksPath/$User/book.html" || !-w "$BooksPath/$User/book.html"){ &error('no_book')} # Book file should exist!
 $host_info = ($ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'}); # We should know who really writes us :)
 
 foreach $req_field (@Required) {
    $RF = eval("\$R::"."$req_field");
     if ($req_field eq 'email' && !&check_email($RF)) {
           push(@error,$req_field);
     } elsif ($RF eq '') {
           push(@error,$req_field);
     }
 }
        # If any error fields have been found, send error message to the user.
    if (@error) { &error('missing_fields', @error) }
}
#######################################################################
sub error { 
    # Localize variables and assign subroutine input.
    local($error,@error_fields) = @_;
    local($missing_field,$missing_field_list);
        if ($error eq 'missing_fields') {
            if ($R::lang eq 'RU') {
                $msg_noblanks = "Поля указанные ниже должны быть заполнены:";
                $msg_propose = "Нажмите BACK в Вашем броузере и заполните их.";
            } elsif ($R::lang eq 'LT') {
                $msg_noblanks = "Paюymлti laukai turi bыti uюpildyti";
                $msg_propose = "Spauskite BACK mygtuka ir juos uюpildikyte ";
            } else {
                $msg_noblanks = "You should not left following fields blank:";
                $msg_propose = "Press Back and complete them.";
            }
            
           foreach $missing_field (@error_fields) { 
                $missing_field_list .= "      <li>$missing_field\n"; 
            }
            
            print header();
            print start_html(-"title"=>'Error!',
                             -style=>{-src=>"$BooksURL/$User/styles.css"});
            print "<center><table border=0 width=\"400\" cellpadding=10 cellspacing=0><tr><td bgcolor=eaeaea><hr>";
            print "$msg_noblanks";
            print "<ul> \n";
            print " $missing_field_list ";
            print "</ul><br>\n<center><font size=\"-1\">$msg_propose</font></center><hr>";
            print "</td></tr></table><br><font size=1>$Version</font><center>";
            print end_html();
            exit;
        }
        if ($error eq 'no_book') {
            if ($R::lang eq 'RU') {
                $msg_nobook = "Я не могу найти Книгу с именем";
                $msg_propose = "Проверьте значение параметра <b>User</b> в Вашей гостевой книге, а также права доступа к ней.";
            } elsif ($R::lang eq 'LT') {
                $msg_nobook = "Aр negaliu rasti Knygos, kurios vardas -  ";
                $msg_propose = "Patikrinkite Jыsш sveиiш knygos <b>User</b> parametrus ir priлjimo teises. ";
            } else {
                $msg_nobook = "I cannot find the Book named";
                $msg_propose = "Please check <b>User</b> value in your HTML form and <i>guestbook file</i> permissions.";
            }
            print header();
            print start_html(-"title"=>'Error!',
                             -style=>{-src=>"$BooksURL/$User/styles.css"});
            print "<center><table border=0 width=\"400\" cellpadding=10 cellspacing=0><tr><td bgcolor=eaeaea><hr>";
            print "<center><font size=+2>$msg_nobook <b><u>$User</u></b>!</font><br>";
            print "<br>\n $msg_propose<br>";
            print "<pre>&lt;input type=\"hidden\" name=\"User\" value=\"???\"></pre></center>";
            print "<hr></td></tr></table><br><font size=1>$Version</font><center>";
            print end_html();
            exit;
        }
        if ($error eq 'User'){
            print header();
            print start_html(-"title"=>'Error!',
                             -style=>{-src=>"$BooksURL/$User/styles.css"});
            print "<center><table border=0 width=\"400\" cellpadding=10 cellspacing=0><tr><td bgcolor=eaeaea><hr>";
            print "<center><font size=+2><b><u>User</u></b> variable is not defined!</font><br>";
            print "<br>\nPlease check <b>User</b> value in your HTML form. <br>";
            print "<pre>&lt;input type=\"hidden\" name=\"User\" value=\"???\"></pre></center>";
            print "<hr></td></tr></table><center>";
            print end_html();
            exit;
        }
}
#######################################################################
sub ProcessBook {

        open (FILE,"$BooksPath/$User/book.html") || die "Can't Open GuestBook $BooksPath/$User/book.html: $!\n";
        @LINES=<FILE>;
        close(FILE);
        $SIZE=@LINES;

# Writing data to the file
        open (GUEST,">$BooksPath/$User/book.html") || die "Can't Open GuestBook $BooksPath/$User/book.html: $!\n";
#        if (defined $ENV{'REMOTE_HOST'}){
#            $host_info = $ENV{'REMOTE_HOST'}
#        } else {
#            $host_info = $ENV{'REMOTE_ADDR'}
#        }

    for ($i=0;$i<=$SIZE;$i++) {
            $_=$LINES[$i];
                if (/<!--begin-->/) { 
                print GUEST "<!--begin-->\n";
                print GUEST "<!-- recorded by: $host_info --><br>\n";   
                if (defined $R::tabwidth){
                    $tabwidth = $R::tabwidth;
                } else {
                    $tabwidth = "75%";
                }
                print GUEST "<table width=$tabwidth bgcolor=\"#eaeaea\" align=\"center\" border=\"0\" cellpadding=\"4\" cellspacing=\"0\">\n";

                    if ( $R::url ne 'http://www' && $R::url ne '') {
                        print GUEST "<tr><tr><td> <a href=\"$R::url\">$R::name</a>";
                    } else {
                        print GUEST "<tr><tr><td> $R::name";
                    }

    if ( $R::email ) {
        print GUEST "$space < <a href=\"mailto:$R::email\">$R::email</a> > $space";
    } else {
        print GUEST "$space ";
    }
    print GUEST "<i>$R::city, $R::country</i></td></tr>\n";
    print GUEST "<tr><td>$R::comments<br></td></tr>\n";
    print GUEST "<tr><td><font size=1 color=gray>$msg_received $date</font></td></tr></table>\n";
    print GUEST "\n\n\n";   
   } else {
      print GUEST $_;
   }
}

close (GUEST);

}
#######################################################################
sub ExitRedirect {
# Redirect user
    if(defined $R::redirect) {
        print redirect($R::redirect);
    } else {
        print redirect("$BooksURL/$User/book.html");
        exit;
    }
}
#######################################################################
sub GetDate {
    # Get the current time and format the hour, minutes and seconds.
        ($sec,$min,$hour,$mday,$mon,$year,$wday) = (localtime(time))[0,1,2,3,4,5,6];
        $time = sprintf("%02d:%02d:%02d",$hour,$min,$sec);
        $year += 1900; # Add  1900 to the year to get the full 4 digit year. Just for Y2000 compliance. :)
    # Define arrays for the day of the week and month of the year depending on the selected language
    if ($R::lang eq 'LT') {
        @days   = ('Sekmadienб','Pirmadienб','Antradienб','Treиiadienб',
                 'Ketvirtadienб','Penktadienб','Рeрtadienб');
        @months = ('Sausio','Vasario','Kovo','Balandюio','Geguюлs','Birюelio','Liepos',
    	         'Rugpjыиio','Rugsлjo','Spalio','Lapkriиio','Gruodюio');
        $msg_received = "Praneрimas бvestas ";
        $date = "$days[$wday], $months[$mon] $mday, $year $time";# Format the date.   
    } elsif ($R::lang eq 'RU') {
        @days   = ('Воскресенье','Понедельник','Вторник','Среду',
                   'Четверг','Пятницу','Субботу');
        @months = ('Января','Февраля','Марта','Апреля','Мая','Июня','Июля',
    	         'Августа','Сентября','Октября','Ноября','Декабря');
        $msg_received = "Это было ";
        $date = "в $days[$wday], $mday $months[$mon] , $year в $time";# Format the date.   
    } else { #Defaulting to English
        @days   = ('Sunday','Monday','Tuesday','Wednesday',
                   'Thursday','Friday','Saturday');
        @months = ('January','February','March','April','May','June','July',
    	         'August','September','October','November','December');
        $msg_received = "Received ";
        $date = "$days[$wday], $months[$mon] $mday, $year at $time";# Format the date.   
    }
}

#######################################################################
sub check_email {
    # Initialize local email variable with input to subroutine.
    $email = $_[0];
    # If the e-mail address contains:
    if ($email =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ || $email !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})(\]?)$/) {
        # Return a false value, since the e-mail address did not pass valid syntax.
        return 0;
    }
    else {
        # Return a true value, e-mail verification passed.
        return 1;
    }
}

sub EmailNotify {
    if (defined $R::notify && &check_email($R::notify)){
            if ($R::lang eq 'RU') {
                $emsg = "написал следующее сообщение в Вашу гостевую книгу:\n";
            } elsif ($R::lang eq 'LT') {
                $emsg = "paliko tokia юinute:\n";
            } else {
                $emsg = "wrote the following to your Guest book:\n";
            }
            open (MAIL,"|$mailprog $R::notify");
       		print MAIL ("From: $R::name <$R::email>\n");
    		print MAIL ("Subject: MGB Notification\n\n");
            print MAIL '~' x 75 . "\n";
            print MAIL ("$R::name <$R::email> ($R::city, $R::country)\n $emsg\n\t$R::comments\n");
            print MAIL '~' x 75 . "\n";
            print MAIL ("\t\t\t\t$Version\n");
    		close (MAIL);
    }
}
#######################################################################
# this procedure for test purposes only!
#            print header();
#            print start_html(-"title"=>'Control!');
#            print "\n Name <b>$req_field</b> = <b>$RF</b><br>";
#            print "\nVar RF: $RF <br>";
#            print "\nArray: @Required";
#            print end_html();
#            exit;
###########################   HAPPY END   #############################
# TO DO: 
# 2. AntiF%&K filter (convert to *****)
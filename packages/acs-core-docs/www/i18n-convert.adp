
<property name="context">{/doc/acs-core-docs {Documentation}} {How to Internationalize a Package}</property>
<property name="doc(title)">How to Internationalize a Package</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="i18n-introduction" leftLabel="Prev"
		    title="
Chapter 14. Internationalization"
		    rightLink="i18n-design" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="i18n-convert" id="i18n-convert"></a>How to Internationalize a Package</h2></div></div></div><div class="tip" style="margin-left: 0.5in; margin-right: 0.5in;">
<h3 class="title">Tip</h3><p>For multilingual websites we recommend using the UTF8 charset.
In order for AOLserver to use utf8 you need to set the config
parameters OutputCharset and URLCharset to utf-8 in your AOLserver
config file (use the etc/config.tcl template file). This is the
default for OpenACS 5.1 and later. For sites running on Oracle you
need to make sure that AOLserver is running with the NLS_LANG
environment variable set to .UTF8. You should set this variable in
the nsd-oracle run script (use the
acs-core-docs/www/files/nds-oracle.txt template file).</p>
</div><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>
<b>Replace all text with temporary message
tags. </b>From<code class="computeroutput">/acs-admin/apm/</code>, select a package and then
click on <code class="computeroutput">Internationalization</code>,
then <code class="computeroutput">Convert ADP, Tcl, and SQL files
to using the message catalog.</code>. This pass only changes the
adp files; it does not affect catalog files or the catalog in the
database.</p><div class="mediaobject" align="center"><img src="images/i18n-1.png" align="middle"></div><p>You will now be walked through all of the selected adp pages.
The UI shows you the intended changes and lets you edit or cancel
them key by key.</p><div class="mediaobject" align="center"><img src="images/i18n-2.png" align="middle"></div>
</li><li class="listitem"><p>
<b>Replace the temporary message tags in ADP
files. </b>From the same <code class="computeroutput">Convert ADP ...</code> page in <code class="computeroutput">/acs-admin/apm</code> as in the last step, repeat
the process but deselect <code class="computeroutput">Find human
language text ...</code> and select <code class="computeroutput">Replace &lt;# ... #&gt; tags ...</code> and click
OK. This step replaces all of the temporary tags with "short"
message lookups, inserts the message keys into the database message
catalog, and then writes that catalog out to an xml file.</p></li><li class="listitem">
<p>
<b>Replace human-readable text in Tcl files with temporary
tags. </b>Examine all of the tcl files in the packages
for human-readable text and replace it with temporary tags. The
temporary tags in Tcl are slightly different from those in ADP. If
the first character in the temporary tag is an underscore
(<code class="computeroutput">_</code>), then the message keys will
be auto-generated from the original message text. Here is an
unmodified tcl file:</p><pre class="programlisting">
set title "Messages for $a(name) in $b(label)"
set context [list [list . "SimPlay"] \
                  [list [export_vars -base case-admin { case_id }] \ 
                    "Administer $a(name)"] \
                  "Messages for $a(name)"]
</pre><p>... and here is the same file after temporary message tags have
been manually added:</p><pre class="programlisting">
set title &lt;#admin_title Messages for %a.name% in %b.label%#&gt;
set context [list [list . &lt;#_ SimPlay#&gt;] \
                  [list [export_vars -base case-admin { case_id }] \
                    &lt;#_ Administer %a.name%#&gt;] \
                  &lt;#_ Messages for %a.name%#&gt;]
</pre><p>Note that the message key <code class="computeroutput">case_admin_page_title</code> was manually
selected, because an autogenerated key for this text, with its
substitute variables, would have been very confusing</p>
</li><li class="listitem">
<p>
<b>Replace the temporary message tags in Tcl
files. </b>Repeat step 2 for tcl files. Here is the
example Tcl file after conversion:</p><pre class="programlisting">
set title [_ simulation.admin_title]
set context [list [list . [_ simulation.SimPlay]] \
                  [list [export_vars -base case-admin { case_id }] \
                    [_ simulation.lt_Administer_name_gt]] \
                  [_ simulation.lt_Messages_for_role_pre]]
</pre>
</li><li class="listitem"><p>
<b>Internationalize SQL Code. </b>If there is any
user-visible Tcl code in the .sql or .xql files, internationalize
that the same way as for the Tcl files.</p></li><li class="listitem"><p>
<b>Internationalize Package Parameters. </b> See
<a class="xref" href="i18n-introduction" title="APM Parameters">Multilingual APM Parameters</a>
</p></li><li class="listitem">
<p><b>Internationalize Date and Time queries. </b></p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem">
<p>Find datetime in .xql files. Use command line tools to find
suspect SQL code:</p><pre class="programlisting">
grep -r "to_char.*H" *
grep -r "to_date.*H" *
</pre>
</li><li class="listitem">
<p>In SQL statements, replace the format string with the ANSI
standard format, <code class="computeroutput">YYYY-MM-DD
HH24:MI:SS</code> and change the field name to *_ansi so that it
cannot be confused with previous, improperly formatting fields. For
example,</p><pre class="programlisting">
to_char(timestamp,'MM/DD/YYYY HH:MI:SS') as foo_date_pretty
</pre><p>becomes</p><pre class="programlisting">
to_char(timestamp,'YYYY-MM-DD HH24:MI:SS') as foo_date_ansi
</pre>
</li><li class="listitem">
<p>In Tcl files where the date fields are used, convert the
datetime from local server timezone, which is how it's stored in
the database, to the user's timezone for display. Do this with the
localizing function <code class="computeroutput"><a class="ulink" href="/api-doc/proc-view?proc=lc_time_system_to_conn" target="_top">lc_time_system_to_conn</a></code>:</p><pre class="programlisting">
set foo_date_ansi [lc_time_system_to_conn $foo_date_ansi]
</pre><p>When a datetime will be written to the database, first convert
it from the user's local time to the server's timezone with
<code class="computeroutput"><a class="ulink" href="/api-doc/proc-view?proc=lc%5ftime%5fconn%5fto%5fsystem" target="_top">lc_time_conn_to_system</a></code>.</p>
</li><li class="listitem">
<p>When a datetime field will be displayed, format it using the
localizing function <code class="computeroutput"><a class="ulink" href="/api-doc/proc-view?proc=lc_time_fmt" target="_top">lc_time_fmt</a></code>. lc_time_fmt takes two parameters,
datetime and format code. Several format codes are usable for
localization; they are placeholders that format dates with the
appropriate codes for the user's locale. These codes are:
<code class="computeroutput">%x, %X, %q, %Q, and %c.</code>
</p><pre class="programlisting">
set foo_date_pretty [lc_time_fmt $foo_date_ansi "%x %X"]
</pre><p>Use the <code class="computeroutput">_pretty</code> version in
your ADP page.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>%c: Long date and time (Mon November 18, 2002 12:00 AM)</p></li><li class="listitem"><p>%x: Short date (11/18/02)</p></li><li class="listitem"><p>%X: Time (12:00 AM)</p></li><li class="listitem"><p>%q: Long date without weekday (November 18, 2002)</p></li><li class="listitem"><p>%Q: Long date with weekday (Monday November 18, 2002)</p></li>
</ul></div><p>The "q" format strings are OpenACS additions; the rest follow
unix standards (see <code class="computeroutput">man
strftime</code>).</p>
</li>
</ol></div>
</li><li class="listitem"><p>
<b>Internationalize Numbers. </b> To
internationalize numbers, use <code class="computeroutput">lc_numeric $value</code>, which formats the number
using the appropriate decimal point and thousand separator for the
locale.</p></li><li class="listitem"><p>
<b>Internationalizing Forms. </b>When coding forms,
remember to use message keys for each piece of text that is
user-visible, including form option labels and button labels.</p></li><li class="listitem">
<p>
<a name="catalog-consistency-check" id="catalog-consistency-check"></a><b>Checking the Consistency of
Catalog Files. </b> This section describes how to check
that the set of keys used in message lookups in tcl, adp, and info
files and the set of keys in the catalog file are identical. The
scripts below assume that message lookups in adp and info files are
on the format \#package_key.message_key\#, and that message lookups
in tcl files are always is done with one of the valid lookups
described above. The script further assumes that you have perl
installed and in your path. Run the script like this: <code class="computeroutput">acs-lang/bin/check-catalog.sh
package_key</code>
</p><p>where package_key is the key of the package that you want to
test. If you don't provide the package_key argument then all
packages with catalog files will be checked. The script will run
its checks primarily on en_US xml catalog files.</p>
</li>
</ol></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140673159451712" id="idp140673159451712"></a>Avoiding common i18n mistakes</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>
<b>Replace complicated keys with longer, simpler
keys. </b>When writing in one language, it is possible
to create clever code to make correct text. In English, for
example, you can put an <code class="computeroutput">if</code>
command at the end of a word which adds "s" if a count is anything
but 1. This pluralizes nouns correctly based on the data. However,
it is confusing to read and, when internationalized, may result in
message keys that are both confusing and impossible to set
correctly in some languages. While internationalizing, watch out
that the automate converter does not create such keys. Also,
refactor compound text as you encounter it.</p><p>The automated system can easily get confused by tags within
message texts, so that it tries to create two or three message keys
for one long string with a tag in the middle. In these cases,
uncheck those keys during the conversion and then edit the files
directly. For example, this code:</p><pre class="programlisting">
  &lt;p class="form-help-text"&gt;&lt;b&gt;Invitations&lt;/b&gt; are sent,
          when this wizard is completed and casting begins.&lt;/p&gt;
</pre><p>has a bold tag which confuses the converter into thinking there
are two message keys for the text beginning "Invitations ..." where
there should be one:</p><div class="mediaobject" align="center"><img src="images/i18n-3.png" align="middle"></div><p>Instead, we cancel those keys, edit the file manually, and put
in a single temporary message tag:</p><pre class="programlisting">
  &lt;p class="form-help-text"&gt; &lt;#Invitations_are_sent &lt;b&gt;Invitations&lt;/b&gt; are sent, 
when this wizard is completed and casting begins.#&gt;
  &lt;/p&gt;
</pre><p>Complex if statements may produce convoluted message keys that
are very hard to localize. Rewrite these if statements. For
example:</p><pre class="programlisting">
Select which case &lt;if \@simulation.casting_type\@ eq "open"&gt;and
role&lt;/if&gt; to join, or create a new case for yourself.  If you do not
select a case &lt;if \@simulation.casting_type\@ eq "open"&gt;and role&lt;/if&gt;
to join, you will be automatically assigned to a case &lt;if
\@simulation.casting_type\@ eq "open"&gt;and role&lt;/if&gt; when the
simulation begins.
</pre><p>... can be rewritten:</p><pre class="programlisting">
&lt;if \@simulation.casting_type\@ eq "open"&gt;

Select which case and role to join, or create a new case for
yourself.  If you do not select a case and role to join, you will
be automatically assigned to a case and role when the simulation
begins.

&lt;/if&gt;
&lt;else&gt;

Select which case to join, or create a new case for
yourself.  If you do not select a case to join, you will
be automatically assigned to a case when the simulation
begins.

&lt;/else&gt;
</pre><p>Another example, where bugs are concatenated with a number:</p><pre class="programlisting">
&lt;if \@components.view_bugs_url\@ not nil&gt;
  &lt;a href="\@components.view_bugs_url\@" title="View the \@pretty_names.bugs\@ for this component"&gt;
  &lt;/if&gt;
  \@components.num_bugs\@ 
  &lt;if \@components.num_bugs\@ eq 1&gt;
    \@pretty_names.bug\@
  &lt;/if&gt;
  &lt;else&gt;
    \@pretty_names.bugs\@
  &lt;/else&gt;
  &lt;if \@components.view_bugs_url\@ not nil&gt;
  &lt;/a&gt;
  &lt;/if&gt;

&lt;if \@components.view_bugs_url\@ not nil&gt;
&lt;a href="\@components.view_bugs_url\@" title="<span>#</span>bug-tracker.View_the_bug_fo_component#"&gt;
&lt;/if&gt;
\@components.num_bugs\@ 
&lt;if \@components.num_bugs\@ eq 1&gt;
\@pretty_names.bug\@
&lt;/if&gt;
&lt;else&gt;
\@pretty_names.bugs\@
&lt;/else&gt;
&lt;if \@components.view_bugs_url\@ not nil&gt;
&lt;/a&gt;
&lt;/if&gt;
</pre><p>It would probably be better to do this as something like:</p><pre class="programlisting">
&lt;if \@components.view_bugs_url\@ not nil&gt;
  &lt;if \@components.num_bugs\@ eq 1&gt;
    &lt;a href="\@components.view_bugs_url\@" title="<span>#</span>bug-tracker.View_the_bug_fo_component#"&gt;<span>#</span>bug-tracker.one_bug#&lt;/a&gt;
  &lt;/if&gt;&lt;else&gt;
    &lt;a href="\@components.view_bugs_url\@" title="<span>#</span>bug-tracker.View_the_bug_fo_component#"&gt;<span>#</span>bug-tracker.N_bugs#&lt;/a&gt;
  &lt;/else&gt;
&lt;/if&gt;
</pre>
</li><li class="listitem">
<p>
<b>Don't combine keys in display
text. </b>Converting a phrase from one language to
another is usually more complicated than simply replacing each word
with an equivalent. When several keys are concatenated, the
resulting word order will not be correct for every language.
Different languages may use expressions or idioms that don't match
the phrase key-for-key. Create complete, distinct keys instead of
building text from several keys. For example:</p><p>Original code:</p><pre class="programlisting">
multirow append links "New [bug_tracker::conn Bug]" 
</pre><p>Problematic conversion:</p><pre class="programlisting">
multirow append links "[_ bug-tracker.New] [bug_tracker::conn Bug]"
</pre><p>Better conversion:</p><pre class="programlisting">
set bug_label [bug_tracker::conn Bug]
multirow append links "[_ bug-tracker.New_Bug]" "${url_prefix}bug-add"
</pre><p>... and include the variable in the key: <code class="computeroutput">"New %bug_label%"</code>. This gives translators
more control over the phrase.</p><p>In this example of bad i18n, full name is created by
concatenating first and last name (admittedly this is pervasive in
the toolkit):</p><pre class="programlisting">
&lt;a href="\@past_version.maintainer_url\@" title="<span>#</span>bug-tracker.Email# \@past_version.maintainer_email\@"&gt;
\@past_version.maintainer_first_names\@ \@past_version.maintainer_last_name\@&lt;/a&gt;
</pre>
</li><li class="listitem">
<p>
<b>Avoid unnecessary duplicate keys. </b>When
phrases are exactly the same in several places, use a single
key.</p><p>For common words such as Yes and No, you can use a library of
keys at <a class="ulink" href="/acs-lang/admin/message-list?package%5fkey=acs%2dkernel&amp;locale=en%5fUS" target="_top">acs-kernel</a>. For example, instead of using
<code class="computeroutput">myfirstpackage.Yes</code>, you can use
<code class="computeroutput">acs-kernel.Yes</code>. You can also
use the <a class="ulink" href="/acs-lang/admin/package-list?locale=en%5fUS" target="_top">Message
Key Search</a> facility to find duplicates. Be careful, however,
building up sentences from keys because grammar and other elements
may not be consistent across different locales.</p><p>Additional discussion: <a class="ulink" href="http://openacs.org/forums/message-view?message_id=164973" target="_top">Re: Bug 961 ("Control Panel" displayed instead of
"Administer")</a>, <a class="ulink" href="http://openacs.org/forums/message-view?message_id=125235" target="_top">Translation server upgraded</a>, and <a class="ulink" href="http://openacs.org/forums/message-view?message_id=158580" target="_top">Localization questions</a>.</p>
</li><li class="listitem">
<p>
<b>Don't internationalize internal code
words. </b>Many packages use code words or key words,
such as "open" and "closed", which will never be shown to the user.
They may match key values in the database, or be used in a switch
or if statement. Don't change these.</p><p>For example, the original code is</p><pre class="programlisting">
workflow::case::add_log_data \            
       -entry_id $entry_id \        
       -key "resolution" \          
       -value [db_string select_resolution_code {}]
</pre><p>This is incorrectly internationalized to</p><pre class="programlisting">
  workflow::case::add_log_data \      
       -entry_id $entry_id \
       -key "[_ bug-tracker.resolution]" \
       -value [db_string select_resolution_code {}]
</pre><p>But <code class="computeroutput">resolution</code> is a keyword
in a table and in the code, so this breaks the code. It should not
have been internationalized at all. Here's another example of text
that should not have been internationalized:</p><pre class="programlisting">
{show_patch_status "open"}
</pre><p>It is broken if changed to</p><pre class="programlisting">
{show_patch_status "[_ bug-tracker.open]"}
</pre>
</li><li class="listitem">
<p>
<b>Fix automatic truncated message keys. </b>The
automatic converter may create unique but crytic message keys.
Watch out for these and replace them with more descriptive keys.
For example:</p><pre class="programlisting">
&lt;msg key="You"&gt;You can filter by this %component_name% by viisting %filter_url_string%&lt;/msg&gt;
&lt;msg key="You_1"&gt;You do not have permission to map this patch to a bug. Only the submitter of the patch 
and users with write permission on this Bug Tracker project (package instance) may do so.&lt;/msg&gt;
&lt;msg key="You_2"&gt;You do not have permission to edit this patch. Only the submitter of the patch 
and users with write permission on the Bug Tracker project (package instance) may do so.&lt;/msg&gt;
</pre><p>These would be more useful if they were, "you_can_filter",
"you_do_not_have_permission_to_map_this_patch", and
"you_do_not_have_permission_to_edit_this_patch". Don't worry about
exactly matching the english text, because that might change;
instead try to capture the meaning of the phrase. Ask yourself, if
I was a translator and didn't know how this application worked,
would this key and text make translation easy for me?</p><p>Sometimes the automatic converter creates keys that don't
semantically match their text. Fix these:</p><pre class="programlisting">
&lt;msg key="Fix"&gt;for version&lt;/msg&gt;
&lt;msg key="Fix_1"&gt;for&lt;/msg&gt;
&lt;msg key="Fix_2"&gt;for Bugs&lt;/msg&gt;
</pre><p>Another example: <code class="computeroutput">Bug-tracker
component maintainer"</code> was converted to <code class="computeroutput">"[_ bug-tracker.Bug-tracker]"</code>. Instead, it
should be <code class="computeroutput">bug_tracker_component_maintainer</code>.</p>
</li><li class="listitem"><p>
<b>Translations in Avoid "clever" message
reuse. </b>Translations may need to differ depending on
the context in which the message appears.</p></li><li class="listitem"><p>
<b>Avoid plurals. </b>Different languages create
plurals differently. Try to avoid keys which will change based on
the value of a number. OpenACS does not currently support
internationalization of plurals. If you use two different keys, a
plural and a singular form, your application will not localize
properly for locales which use different rules or have more than
two forms of plurals.</p></li><li class="listitem">
<p>
<b>Quoting in the message catalog for tcl. </b>Watch
out for quoting and escaping when editing text that is also code.
For example, the original string</p><pre class="programlisting">
set title "Patch \"$patch_summary\" is nice."
</pre><p>breaks if the message text retains all of the escaping that was
in the tcl command:</p><pre class="programlisting">
&lt;msg&gt;Patch \"$patch_summary\" is nice.&lt;/msg&gt;
</pre><p>When it becomes a key, it should be:</p><pre class="programlisting">
&lt;msg&gt;Patch "$patch_summary" is nice.&lt;/msg&gt;
</pre><p>Also, some keys had %var;noquote%, which is not needed since
those variables are not quoted (and in fact the variable won't even
be recognized so you get the literal %var;noquote% in the
output).</p>
</li><li class="listitem">
<p>
<b>Be careful with curly brackets. </b>Code within
curly brackets isn't evaluated. Tcl uses curly brackets as an
alternative way to build lists. But Tcl also uses curly brackets as
an alternative to quotation marks for quoting text. So this
original code</p><pre class="programlisting">
array set names { key "Pretty" ...} 
</pre><p>... if converted to</p><pre class="programlisting">
array set names { key "[_bug-tracker.Pretty]" ...} 
</pre><p>... won't work since the _ func will not be called. Instead, it
should be</p><pre class="programlisting">
array set names [list key [_bug-tracker.Pretty] ...]
</pre>
</li>
</ul></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="i18n-introduction" leftLabel="Prev" leftTitle="How Internationalization/Localization
works in OpenACS"
		    rightLink="i18n-design" rightLabel="Next" rightTitle="Design Notes"
		    homeLink="index" homeLabel="Home" 
		    upLink="i18n" upLabel="Up"> 
		
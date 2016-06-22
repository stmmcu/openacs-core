
<property name="context">{/doc/acs-templating {Templating}} {Templating System Tag Reference: Formtemplate}</property>
<property name="doc(title)">Templating System Tag Reference: Formtemplate</property>
<master>
<h2>Formtemplate</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : Formtemplate
<h3>Summary</h3>
<p>The <kbd>formtemplate</kbd> tag is used to embed a dynamic form in
a template. The elements of the form must be created in the Tcl
script associated with the template.</p>
<h3>Usage</h3>
<pre>
  &lt;formtemplate id="add_user"&gt;
  &lt;table&gt;
  &lt;tr&gt;
    &lt;td&gt;First Name&lt;/td&gt;&lt;td&gt;&lt;formwidget id="first_name"&gt;&lt;/td&gt;
  &lt;/tr&gt;
  &lt;tr&gt;
    &lt;td&gt;Last Name&lt;/td&gt;&lt;td&gt;&lt;formwidget id="last_name"&gt;&lt;/td&gt;
  &lt;/tr&gt;
  &lt;/table&gt;&lt;br&gt;
  &lt;input type="submit" value="Submit"&gt;
  &lt;/formtemplate&gt;
</pre>
<h3>Notes</h3>
<ul>
<li><p>The <kbd>formtemplate</kbd> tag takes the place of the
<kbd>form</kbd> tag in a static HTML form. Explicit form tags in the
template should <em>not</em> be used to enclose dynamic forms.</p></li><li>
<p>If the body of the <kbd>formtemplate</kbd> is empty, the
templating system will generate a form automatically based on the
list of elements created in the Tcl script associated with the
template:</p><pre>
&lt;formtemplate id="add_user" style="standard"&gt;&lt;/formtemplate&gt;
</pre><p>The <kbd>style</kbd> attribute is optional. It may be used to
select a style template from <kbd>/ats/templates/forms</kbd> for
determining the layout of the auto-generated form. The default
style is defined in the DefaultFormStyle parameter on the
acs-templating package, and is by default set to <kbd>standard</kbd>,
which is included in the distribution.</p>
</li><li>
<p>HTML attributes, including JavaScript event handlers, may be
specified as attributes to the <kbd>formtemplate</kbd> tag. The
system will include all such attributes in the <kbd>form</kbd> tag of
the rendered HTML form.</p><pre>
&lt;formtemplate id="add_user" onSubmit="validate();"&gt;
</pre><p>This will work for both autogenerated and explicitly formatted
forms.</p>
</li><li><p>See the <a href="formwidget"><kbd>formwidget</kbd></a> and
<a href="formgroup"><kbd>formgroup</kbd></a> tags for more
information on writing the body of a dynamic form template.</p></li>
</ul>
<hr>
<a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>

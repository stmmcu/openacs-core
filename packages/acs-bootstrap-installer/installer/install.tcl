ad_page_contract {
    Carries out the full OpenACS install.

    @author Peter Marklund
    @cvs-id $Id$

} {
    email:notnull
    {username ""}
    first_names:notnull
    last_name:notnull
    password:notnull
    password_confirmation:notnull

    system_url:notnull
    system_name:notnull
    publisher_name:notnull
    system_owner:notnull
    admin_owner:notnull
    host_administrator:notnull
    outgoing_sender:notnull
    new_registrations:notnull
}

##############
#
# System setting validation
#
#############

if { [string compare $password $password_confirmation] } {
    install_return 200 "Passwords Don't Match" "
The passwords you've entered don't match. Please <a href=\"javascript:history.back()\">try again</a>.
"
    return
}

##############
#
# Install data model
#
#############

ns_write "[install_header 200 "Installing Kernel Data Model"]
"

if { ![install_good_data_model_p] } {
    install_do_data_model_install
} else {
    ns_write "Kernel data model already installed."
    # If kernel is installed it probably means this page has already been requested,
    # let's exit
    return
}

##############
#
# Install packages
#
#############

install_do_packages_install

##############
#
# Secret tokens
#
#############

ns_write "<p>Generating secret tokens..."
populate_secret_tokens_db
ns_write "  <p>Done.<p>"

##############
#
# Admin create
#
#############

if { [empty_string_p $username] } {
    set username $email
}

if { ![db_string user_exists {
    select count(*) from parties where email = lower(:email)
}] } {

  db_transaction {
    
    set user_id [ad_user_new \
                     $email \
                     $first_names \
                     $last_name \
                     $password \
                     "" \
                     "" \
                     "" \
                     "t" \
                     "approved" \
                     "" \
                     $username]
    if { !$user_id } {

	global errorInfo    
	install_return 200 "Unable to Create Administrator" "
    
Unable to create the site-wide administrator:
   
<blockquote><pre>[ns_quotehtml $errorInfo]</pre></blockquote>
    
Please <a href=\"javascript:history.back()\">try again</a>.
    
"
        return
    }

    # stub util_memoize_flush...
    rename util_memoize_flush util_memoize_flush_saved
    proc util_memoize_flush {args} {}
    permission::grant -party_id $user_id -object_id [acs_lookup_magic_object security_context_root] -privilege "admin"
    # nuke stub 
    rename util_memoize_flush {}
    rename util_memoize_flush_saved util_memoize_flush
  }
}

##############
#
# System settings
#
#############

set kernel_id [db_string acs_kernel_id_get {
    select package_id from apm_packages
    where package_key = 'acs-kernel'
}]

foreach { var param } {
    system_url SystemURL
    system_name SystemName
    publisher_name PublisherName
    system_owner SystemOwner
    admin_owner AdminOwner
    host_administrator HostAdministrator
    outgoing_sender OutgoingSender
} {
    ad_parameter -set [set $var] -package_id $kernel_id $param
}

# set the Main Site RestrictToSSL parameter

set main_site_id [db_string main_site_id_select { 
    select package_id from apm_packages
    where instance_name = 'Main Site' 
}]

ad_parameter -set "acs-admin/*" -package_id $main_site_id RestrictToSSL
ad_parameter -set $new_registrations -package_id $main_site_id NewRegistrationEmailAddress

# We're done - kill the server (will restart if server is setup properly)
ad_schedule_proc -thread t -once t 1 ns_shutdown

ns_write "<b>Installation finished</b>

<p> The server has been shut down. Normally, it should come back up by itself after a minute or so. </p>

<p> If not, please check your server error log, or contact your system administrator. </p>

<p> When the server is back up you can visit <a href=\"/\">the system homepage</a> </p>

[install_footer]
"

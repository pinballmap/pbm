delete from versions;
delete from banned_ips;
delete from version_associations;
delete from active_storage_blobs;
delete from active_storage_variant_records;
delete from active_storage_attachments;
delete from rails_admin_histories;
delete from solid_cache_entries;
delete from user_fave_locations;
delete from statuses;

delete from location_machine_xrefs WHERE created_at < NOW() - INTERVAL '3 years';
delete from location_picture_xrefs WHERE created_at < NOW() - INTERVAL '3 years';
delete from locations WHERE created_at < NOW() - INTERVAL '3 years';
delete from machine_conditions WHERE created_at < NOW() - INTERVAL '3 years';
delete from machine_score_xrefs WHERE created_at < NOW() - INTERVAL '3 years';
delete from suggested_locations WHERE created_at < NOW() - INTERVAL '3 years';
delete from user_submissions WHERE created_at < NOW() - INTERVAL '3 years';
delete from user_submissions where submission_type = 'suggest_location';
delete from user_submissions where submission_type = 'contact_us';

UPDATE users
    SET username = CONCAT('user', id, random()),
        email = CONCAT('user', id, '@example.com'),
        encrypted_password = '',
        password_salt = '',
        reset_password_token = concat('userreset', id),
        current_sign_in_at = null,
        remember_token = concat('userremember', id),
        remember_created_at = null,
        sign_in_count = 0,
        last_sign_in_at = null,
        current_sign_in_ip = '',
        last_sign_in_ip = '',
        initials = '',
        reset_password_sent_at = null,
        is_machine_admin = false,
        is_primary_email_contact = false,
        is_super_admin = false,
        confirmation_token = '',
        confirmed_at            = null,
        confirmation_sent_at    = null,
        authentication_token = concat('userauth', id),

UPDATE operators
    SET email = name,
    phone = name;

-- don't delete
-- delete from schema_migrations WHERE created_at < NOW() - INTERVAL '3 years';
-- delete from events WHERE created_at < NOW() - INTERVAL '3 years';
-- delete from machine_groups WHERE created_at < NOW() - INTERVAL '3 years';
-- delete from machines WHERE created_at < NOW() - INTERVAL '3 years';
-- delete from region_link_xrefs WHERE created_at < NOW() - INTERVAL '3 years';

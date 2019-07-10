-- Upgrade a cspace database from 4.1 to 5.0.
-- This script should be run in the cspace_{instanceid} database, as the cspace_{instanceid} user.

alter table tenants add column config_md5hash varchar(255);
alter table tenants add column authorities_initialized boolean;
update tenants set authorities_initialized = false;
alter table tenants alter column authorities_initialized set not null;

-- tenants_accountscommon_csid is renamed to tenants_accounts_common_csid.
-- To allow both 4.1 and 5.0 to run simultaneously, this script adds tenants_accounts_common_csid
-- as a new column, and copies tenants_accountscommon_csid to it. Once 4.1 is shut down,
-- tenants_accountscommon_csid may be dropped.
alter table accounts_tenants add column tenants_accounts_common_csid varchar(128);
update accounts_tenants set tenants_accounts_common_csid = tenants_accountscommon_csid;

alter table permissions add column actions_protection varchar(255);
alter table permissions add column metadata_protection varchar(255);

create table tokens (id varchar(128) not null, account_csid varchar(128) not null, tenant_id varchar(128) not null, expire_seconds integer not null, enabled boolean not null, created_at timestamp not null, updated_at timestamp, primary key (id));

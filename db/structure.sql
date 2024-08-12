SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: clean_items(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.clean_items(item text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
        BEGIN
          RETURN regexp_replace(unaccent(item), '[[:punct:]]', '', 'g');
        END;
        $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: banned_ips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.banned_ips (
    id bigint NOT NULL,
    ip_address character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: banned_ips_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.banned_ips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: banned_ips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.banned_ips_id_seq OWNED BY public.banned_ips.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id integer NOT NULL,
    region_id integer,
    name character varying,
    long_desc text,
    external_link character varying,
    category_no integer,
    start_date date,
    end_date date,
    location_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    category character varying,
    external_location_name character varying,
    ifpa_calendar_id integer,
    ifpa_tournament_id integer
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: location_machine_xrefs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location_machine_xrefs (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location_id integer,
    machine_id integer,
    user_id integer,
    machine_score_xrefs_count integer,
    ic_enabled boolean
);


--
-- Name: location_machine_xrefs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.location_machine_xrefs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: location_machine_xrefs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.location_machine_xrefs_id_seq OWNED BY public.location_machine_xrefs.id;


--
-- Name: location_picture_xrefs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location_picture_xrefs (
    id integer NOT NULL,
    location_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text,
    user_id integer,
    photo_file_name character varying,
    photo_content_type character varying,
    photo_file_size integer,
    photo_updated_at timestamp without time zone
);


--
-- Name: location_picture_xrefs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.location_picture_xrefs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: location_picture_xrefs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.location_picture_xrefs_id_seq OWNED BY public.location_picture_xrefs.id;


--
-- Name: location_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location_types (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying,
    icon character varying,
    library character varying
);


--
-- Name: location_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.location_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: location_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.location_types_id_seq OWNED BY public.location_types.id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    id integer NOT NULL,
    name character varying,
    street character varying,
    city character varying,
    state character varying,
    zip character varying,
    phone character varying,
    lat numeric(18,12),
    lon numeric(18,12),
    website character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    zone_id integer,
    region_id integer,
    location_type_id integer,
    description text,
    operator_id integer,
    date_last_updated date,
    last_updated_by_user_id integer,
    is_stern_army boolean,
    country text,
    ic_active boolean
);


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.locations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.locations_id_seq OWNED BY public.locations.id;


--
-- Name: machine_conditions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machine_conditions (
    id integer NOT NULL,
    comment text,
    location_machine_xref_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer
);


--
-- Name: machine_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machine_conditions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machine_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machine_conditions_id_seq OWNED BY public.machine_conditions.id;


--
-- Name: machine_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machine_groups (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: machine_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machine_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machine_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machine_groups_id_seq OWNED BY public.machine_groups.id;


--
-- Name: machine_score_xrefs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machine_score_xrefs (
    id integer NOT NULL,
    location_machine_xref_id integer,
    score bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    rank character varying
);


--
-- Name: machine_score_xrefs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machine_score_xrefs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machine_score_xrefs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machine_score_xrefs_id_seq OWNED BY public.machine_score_xrefs.id;


--
-- Name: machines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machines (
    id integer NOT NULL,
    name character varying,
    is_active boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    ipdb_link character varying,
    year integer,
    manufacturer character varying,
    machine_group_id integer,
    ipdb_id integer,
    opdb_id text,
    opdb_img text,
    opdb_img_height integer,
    opdb_img_width integer,
    machine_type character varying,
    machine_display character varying,
    ic_eligible boolean,
    kineticist_url character varying
);


--
-- Name: machines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machines_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machines_id_seq OWNED BY public.machines.id;


--
-- Name: operators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operators (
    id integer NOT NULL,
    name character varying,
    region_id integer,
    email character varying,
    website character varying,
    phone character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: operators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operators_id_seq OWNED BY public.operators.id;


--
-- Name: rails_admin_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rails_admin_histories (
    id integer NOT NULL,
    message text,
    username text,
    item integer,
    "table" text,
    month smallint,
    year bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: rails_admin_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rails_admin_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rails_admin_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rails_admin_histories_id_seq OWNED BY public.rails_admin_histories.id;


--
-- Name: region_link_xrefs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.region_link_xrefs (
    id integer NOT NULL,
    name character varying,
    url character varying,
    description character varying,
    category character varying,
    region_id integer,
    sort_order integer
);


--
-- Name: region_link_xrefs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.region_link_xrefs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: region_link_xrefs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.region_link_xrefs_id_seq OWNED BY public.region_link_xrefs.id;


--
-- Name: regions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regions (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    full_name character varying,
    motd character varying DEFAULT 'To help keep Pinball Map running, consider a donation! https://pinballmap.com/donate'::character varying,
    lat numeric(18,12),
    lon numeric(18,12),
    n_search_no integer,
    default_search_type character varying,
    should_email_machine_removal boolean,
    should_auto_delete_empty_locations boolean,
    send_digest_comment_emails boolean,
    send_digest_removal_emails boolean,
    state text,
    effective_radius double precision DEFAULT 200.0
);


--
-- Name: regions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.regions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.regions_id_seq OWNED BY public.regions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statuses (
    id bigint NOT NULL,
    status_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statuses_id_seq OWNED BY public.statuses.id;


--
-- Name: suggested_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suggested_locations (
    id integer NOT NULL,
    name text,
    street text,
    city text,
    state text,
    zip text,
    phone text,
    website text,
    location_type_id integer,
    operator_id integer,
    region_id integer,
    comments text,
    machines text,
    user_inputted_address text,
    lat numeric(18,12),
    lon numeric(18,12),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    zone_id integer,
    country text,
    user_id integer
);


--
-- Name: suggested_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.suggested_locations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: suggested_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.suggested_locations_id_seq OWNED BY public.suggested_locations.id;


--
-- Name: user_fave_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_fave_locations (
    id bigint NOT NULL,
    user_id integer,
    location_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_fave_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_fave_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_fave_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_fave_locations_id_seq OWNED BY public.user_fave_locations.id;


--
-- Name: user_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_submissions (
    id integer NOT NULL,
    submission_type text,
    submission text,
    region_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    location_id integer,
    machine_id integer,
    comment character varying,
    user_name character varying,
    location_name character varying,
    machine_name character varying,
    high_score bigint,
    city_name character varying,
    lat double precision,
    lon double precision
);


--
-- Name: user_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_submissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_submissions_id_seq OWNED BY public.user_submissions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying,
    encrypted_password character varying,
    sign_in_count integer,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    region_id integer,
    initials character varying,
    reset_password_sent_at timestamp without time zone,
    is_machine_admin boolean,
    is_primary_email_contact boolean,
    is_super_admin boolean,
    username text,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    is_disabled boolean,
    authentication_token character varying(30),
    reset_password_token character varying,
    security_test character varying,
    user_submissions_count integer
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: version_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.version_associations (
    id bigint NOT NULL,
    version_id integer,
    foreign_key_name character varying NOT NULL,
    foreign_key_id integer,
    foreign_type character varying
);


--
-- Name: version_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.version_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: version_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.version_associations_id_seq OWNED BY public.version_associations.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id bigint NOT NULL,
    item_type character varying NOT NULL,
    item_id bigint NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object text,
    created_at timestamp(6) without time zone,
    object_changes text,
    transaction_id integer
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zones (
    id integer NOT NULL,
    name character varying,
    region_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    short_name character varying,
    is_primary boolean
);


--
-- Name: zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zones_id_seq OWNED BY public.zones.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: banned_ips id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banned_ips ALTER COLUMN id SET DEFAULT nextval('public.banned_ips_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: location_machine_xrefs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_machine_xrefs ALTER COLUMN id SET DEFAULT nextval('public.location_machine_xrefs_id_seq'::regclass);


--
-- Name: location_picture_xrefs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_picture_xrefs ALTER COLUMN id SET DEFAULT nextval('public.location_picture_xrefs_id_seq'::regclass);


--
-- Name: location_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_types ALTER COLUMN id SET DEFAULT nextval('public.location_types_id_seq'::regclass);


--
-- Name: locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations ALTER COLUMN id SET DEFAULT nextval('public.locations_id_seq'::regclass);


--
-- Name: machine_conditions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_conditions ALTER COLUMN id SET DEFAULT nextval('public.machine_conditions_id_seq'::regclass);


--
-- Name: machine_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_groups ALTER COLUMN id SET DEFAULT nextval('public.machine_groups_id_seq'::regclass);


--
-- Name: machine_score_xrefs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_score_xrefs ALTER COLUMN id SET DEFAULT nextval('public.machine_score_xrefs_id_seq'::regclass);


--
-- Name: machines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machines ALTER COLUMN id SET DEFAULT nextval('public.machines_id_seq'::regclass);


--
-- Name: operators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators ALTER COLUMN id SET DEFAULT nextval('public.operators_id_seq'::regclass);


--
-- Name: rails_admin_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rails_admin_histories ALTER COLUMN id SET DEFAULT nextval('public.rails_admin_histories_id_seq'::regclass);


--
-- Name: region_link_xrefs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.region_link_xrefs ALTER COLUMN id SET DEFAULT nextval('public.region_link_xrefs_id_seq'::regclass);


--
-- Name: regions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions ALTER COLUMN id SET DEFAULT nextval('public.regions_id_seq'::regclass);


--
-- Name: statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses ALTER COLUMN id SET DEFAULT nextval('public.statuses_id_seq'::regclass);


--
-- Name: suggested_locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suggested_locations ALTER COLUMN id SET DEFAULT nextval('public.suggested_locations_id_seq'::regclass);


--
-- Name: user_fave_locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_fave_locations ALTER COLUMN id SET DEFAULT nextval('public.user_fave_locations_id_seq'::regclass);


--
-- Name: user_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_submissions ALTER COLUMN id SET DEFAULT nextval('public.user_submissions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: version_associations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.version_associations ALTER COLUMN id SET DEFAULT nextval('public.version_associations_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones ALTER COLUMN id SET DEFAULT nextval('public.zones_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: banned_ips banned_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banned_ips
    ADD CONSTRAINT banned_ips_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: location_machine_xrefs location_machine_xrefs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_machine_xrefs
    ADD CONSTRAINT location_machine_xrefs_pkey PRIMARY KEY (id);


--
-- Name: location_picture_xrefs location_picture_xrefs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_picture_xrefs
    ADD CONSTRAINT location_picture_xrefs_pkey PRIMARY KEY (id);


--
-- Name: location_types location_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_types
    ADD CONSTRAINT location_types_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: machine_conditions machine_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_conditions
    ADD CONSTRAINT machine_conditions_pkey PRIMARY KEY (id);


--
-- Name: machine_groups machine_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_groups
    ADD CONSTRAINT machine_groups_pkey PRIMARY KEY (id);


--
-- Name: machine_score_xrefs machine_score_xrefs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_score_xrefs
    ADD CONSTRAINT machine_score_xrefs_pkey PRIMARY KEY (id);


--
-- Name: machines machines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machines
    ADD CONSTRAINT machines_pkey PRIMARY KEY (id);


--
-- Name: operators operators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators
    ADD CONSTRAINT operators_pkey PRIMARY KEY (id);


--
-- Name: rails_admin_histories rails_admin_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rails_admin_histories
    ADD CONSTRAINT rails_admin_histories_pkey PRIMARY KEY (id);


--
-- Name: region_link_xrefs region_link_xrefs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.region_link_xrefs
    ADD CONSTRAINT region_link_xrefs_pkey PRIMARY KEY (id);


--
-- Name: regions regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: statuses statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses
    ADD CONSTRAINT statuses_pkey PRIMARY KEY (id);


--
-- Name: suggested_locations suggested_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suggested_locations
    ADD CONSTRAINT suggested_locations_pkey PRIMARY KEY (id);


--
-- Name: user_fave_locations user_fave_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_fave_locations
    ADD CONSTRAINT user_fave_locations_pkey PRIMARY KEY (id);


--
-- Name: user_submissions user_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_submissions
    ADD CONSTRAINT user_submissions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: version_associations version_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.version_associations
    ADD CONSTRAINT version_associations_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_events_on_ifpa_calendar_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_ifpa_calendar_id ON public.events USING btree (ifpa_calendar_id);


--
-- Name: index_events_on_ifpa_tournament_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_ifpa_tournament_id ON public.events USING btree (ifpa_tournament_id);


--
-- Name: index_events_on_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_location_id ON public.events USING btree (location_id);


--
-- Name: index_events_on_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_region_id ON public.events USING btree (region_id);


--
-- Name: index_location_machine_xrefs_on_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_machine_xrefs_on_location_id ON public.location_machine_xrefs USING btree (location_id);


--
-- Name: index_location_machine_xrefs_on_machine_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_machine_xrefs_on_machine_id ON public.location_machine_xrefs USING btree (machine_id);


--
-- Name: index_location_machine_xrefs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_machine_xrefs_on_user_id ON public.location_machine_xrefs USING btree (user_id);


--
-- Name: index_location_picture_xrefs_on_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_picture_xrefs_on_location_id ON public.location_picture_xrefs USING btree (location_id);


--
-- Name: index_location_picture_xrefs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_picture_xrefs_on_user_id ON public.location_picture_xrefs USING btree (user_id);


--
-- Name: index_locations_on_is_stern_army; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_is_stern_army ON public.locations USING btree (is_stern_army);


--
-- Name: index_locations_on_last_updated_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_last_updated_by_user_id ON public.locations USING btree (last_updated_by_user_id);


--
-- Name: index_locations_on_location_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_location_type_id ON public.locations USING btree (location_type_id);


--
-- Name: index_locations_on_operator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_operator_id ON public.locations USING btree (operator_id);


--
-- Name: index_locations_on_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_region_id ON public.locations USING btree (region_id);


--
-- Name: index_locations_on_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_zone_id ON public.locations USING btree (zone_id);


--
-- Name: index_machine_conditions_on_location_machine_xref_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_machine_conditions_on_location_machine_xref_id ON public.machine_conditions USING btree (location_machine_xref_id);


--
-- Name: index_machine_conditions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_machine_conditions_on_user_id ON public.machine_conditions USING btree (user_id);


--
-- Name: index_machine_score_xrefs_on_location_machine_xref_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_machine_score_xrefs_on_location_machine_xref_id ON public.machine_score_xrefs USING btree (location_machine_xref_id);


--
-- Name: index_machine_score_xrefs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_machine_score_xrefs_on_user_id ON public.machine_score_xrefs USING btree (user_id);


--
-- Name: index_machines_on_machine_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_machines_on_machine_group_id ON public.machines USING btree (machine_group_id);


--
-- Name: index_operators_on_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operators_on_region_id ON public.operators USING btree (region_id);


--
-- Name: index_rails_admin_histories; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rails_admin_histories ON public.rails_admin_histories USING btree (item, "table", month, year);


--
-- Name: index_region_link_xrefs_on_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_region_link_xrefs_on_region_id ON public.region_link_xrefs USING btree (region_id);


--
-- Name: index_user_submissions_on_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_submissions_on_region_id ON public.user_submissions USING btree (region_id);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_authentication_token ON public.users USING btree (authentication_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_region_id ON public.users USING btree (region_id);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username);


--
-- Name: index_version_associations_on_foreign_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_version_associations_on_foreign_key ON public.version_associations USING btree (foreign_key_name, foreign_key_id, foreign_type);


--
-- Name: index_version_associations_on_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_version_associations_on_version_id ON public.version_associations USING btree (version_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: index_versions_on_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_transaction_id ON public.versions USING btree (transaction_id);


--
-- Name: index_zones_on_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zones_on_region_id ON public.zones USING btree (region_id);


--
-- Name: ix_fast_search_city; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_fast_search_city ON public.locations USING btree (public.clean_items((city)::text));


--
-- Name: ix_fast_search_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_fast_search_name ON public.locations USING btree (public.clean_items((name)::text));


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20101029034449'),
('20101029051956'),
('20101107193735'),
('20101217210700'),
('20101218055651'),
('20110104033947'),
('20110104034353'),
('20110106015040'),
('20110108190631'),
('20110109031830'),
('20110109033611'),
('20110109061136'),
('20110109202100'),
('20110109233904'),
('20110112031846'),
('20110113014924'),
('20110113015641'),
('20110212001944'),
('20110217044158'),
('20110218024542'),
('20110221234445'),
('20110221234515'),
('20110221234608'),
('20110222000458'),
('20110222001631'),
('20110222001739'),
('20110222002318'),
('20110222053847'),
('20110222054539'),
('20110222060400'),
('20110222061738'),
('20110223052335'),
('20110324054350'),
('20110325055510'),
('20110325061757'),
('20110331234837'),
('20110331235611'),
('20110401001017'),
('20110416203328'),
('20110416204407'),
('20110416205031'),
('20110416231605'),
('20110416232037'),
('20110419023435'),
('20110428031156'),
('20110428052920'),
('20110428053024'),
('20110428054244'),
('20110429005401'),
('20110505231652'),
('20110509032221'),
('20110512032510'),
('20110520155736'),
('20110520160215'),
('20110527230812'),
('20110528183055'),
('20110528184008'),
('20120121231029'),
('20120331225504'),
('20120407204619'),
('20120407205003'),
('20120520190325'),
('20120520190845'),
('20130303070120'),
('20130303070426'),
('20130303070529'),
('20130413173205'),
('20130510024658'),
('20130713014626'),
('20131019021843'),
('20140329173540'),
('20140329174930'),
('20140612173934'),
('20140816200939'),
('20140816200950'),
('20140913204019'),
('20140913204322'),
('20150128151820'),
('20150128155902'),
('20150926235940'),
('20150928221835'),
('20151016185205'),
('20151017212853'),
('20151102053730'),
('20151230222502'),
('20160102205629'),
('20160403220735'),
('20160425025650'),
('20160428022137'),
('20160428033749'),
('20160521200326'),
('20160828174541'),
('20160828192015'),
('20160911181659'),
('20160912054027'),
('20170306034705'),
('20170325210202'),
('20170325210403'),
('20170418033559'),
('20170625051130'),
('20170813032145'),
('20180214052824'),
('20180322035017'),
('20180412042101'),
('20180501030619'),
('20180527033929'),
('20180528154913'),
('20180713045044'),
('20180803024507'),
('20180803024743'),
('20180826144303'),
('20180921032336'),
('20181108041556'),
('20190302181011'),
('20190405035609'),
('20200902061504'),
('20210112043456'),
('20210413230424'),
('20211004024618'),
('20220214041241'),
('20220214041302'),
('20220513054325'),
('20220526191634'),
('20220602214055'),
('20220603045549'),
('20230117183500'),
('20230117183514'),
('20230121051546'),
('20230207174539'),
('20230207174826'),
('20230207174904'),
('20230220182301'),
('20230406181953'),
('20230406181954'),
('20230406181955'),
('20230406195153'),
('20230406195154'),
('20230406195207'),
('20230406195208'),
('20230504162149'),
('20230518001533'),
('20230702162416'),
('20231025185948'),
('20240403171756'),
('20240520232037'),
('20240521020441'),
('20240521021315'),
('20240521021328'),
('20240703041704'),
('20240812034312');



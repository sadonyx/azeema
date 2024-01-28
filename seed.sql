--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5 (Homebrew)
-- Dumped by pg_dump version 15.5 (Homebrew)

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
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: attendee_status_enum; Type: TYPE; Schema: public; Owner: adnan
--

CREATE TYPE public.attendee_status_enum AS ENUM (
    'Y',
    'M',
    'N'
);


ALTER TYPE public.attendee_status_enum OWNER TO adnan;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: events; Type: TABLE; Schema: public; Owner: adnan
--

CREATE TABLE public.events (
    id integer NOT NULL,
    title text,
    description text,
    location text,
    date date NOT NULL,
    time_start time without time zone NOT NULL,
    time_end time without time zone NOT NULL,
    capacity numeric DEFAULT 'Infinity'::numeric NOT NULL,
    creator_id integer NOT NULL,
    date_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    event_picture text
);


ALTER TABLE public.events OWNER TO adnan;

--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: adnan
--

ALTER TABLE public.events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: events_participants; Type: TABLE; Schema: public; Owner: adnan
--

CREATE TABLE public.events_participants (
    id integer NOT NULL,
    event_id integer NOT NULL,
    participant_id integer NOT NULL,
    attendee_status public.attendee_status_enum NOT NULL
);


ALTER TABLE public.events_participants OWNER TO adnan;

--
-- Name: events_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: adnan
--

ALTER TABLE public.events_participants ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.events_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: adnan
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    username character varying(25) NOT NULL,
    pswhash text NOT NULL,
    date_joined timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    profile_picture text,
    CONSTRAINT users_name_check CHECK (((length((name)::text) >= 3) AND (length((name)::text) <= 50))),
    CONSTRAINT users_name_only_alphabets CHECK (((name)::text !~~ '%[^A-Z]%'::text)),
    CONSTRAINT users_username_check CHECK (((length((username)::text) >= 3) AND (length((username)::text) <= 25))),
    CONSTRAINT users_username_no_special_chars CHECK (((username)::text !~~ '%[^A-Z0-9]%'::text))
);


ALTER TABLE public.users OWNER TO adnan;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: adnan
--

ALTER TABLE public.users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: adnan
--

COPY public.events (id, title, description, location, date, time_start, time_end, capacity, creator_id, date_created, event_picture) FROM stdin;
7	The 3 Year Anniversary of Lorem Ipsum	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce porta erat auctor, scelerisque erat et, laoreet ex.\r\n\r\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus id augue ex. Integer ac gravida quam. In vel suscipit ante. Phasellus maximus ante vitae purus finibus, at accumsan nisl pellentesque.\r\n\r\nNunc tempus leo eget tincidunt pharetra. Sed at gravida tellus. Mauris eget libero sodales ex commodo placerat ut ac odio. Morbi fermentum euismod augue vel ullamcorper.\r\n\r\nNullam luctus auctor libero at pulvinar. Curabitur in finibus lectus, scelerisque posuere velit. Aliquam mollis auctor vulputate. Nam eget lacinia magna. Proin laoreet justo in elit molestie hendrerit. In sed faucibus metus.	The Lorem Ipsum @ SoFi Stadium	2025-02-23	19:45:00	23:45:00	Infinity	6	2023-12-27 16:49:34.608377	admin-e-f78506.png
4	natalia luna’s summer garden picnic	Hello everyone! Thank you for being a part of Natalia's 25th birthday celebration! Her actual birth date is on September 27th, but we thought it would be best to celebrate with you all on Saturday the 30th. 😌\r\n\r\n🌸 Time: we will be set up in Adnan’s backyard at 3:00 PM and be there until around 7:00 PM. Feel free to come by anytime within that window!\r\n\r\n🌸 Dress Code: the theme is Italian Summer Garden. Essentially, the vision is that people show up in sun dresses and button-downs.\r\n\r\n🌸 Food & Drinks: we will be providing Prosecco with a variety of fresh juices, alongside breads, cheeses, and fruits.\r\n\r\n🌸 "Should I Bring Anything?": nothing is required of you, but it could be helpful for you to bring extra snacks/drinks. Gifts are optional, however the greatest gift you can give is your time❣	3036 Paddington Road, Glendale, CA 91206	2023-09-30	14:00:00	19:00:00	Infinity	1	2023-12-26 21:23:16.977217	sadonis-e-25f7f0.png
3	Help me NOT join the 27 club!	Come through and pre your Friday evening in celebration of me somehow making it to my late twenties! Bar hopping/dancing after for anyone who wants to join!\r\n\r\nVibe: Lowkey, fancy, classy, wine/cocktails, good music, good people.\r\n\r\nLocation: Upstairs patio of The Red Room Wine Bar! (Everyone say THANK YOU BRENDA for securing the venue❤️)\r\n\r\nDress code (mandatory🔫): SHOW OUT! Fancy cocktail attire / dress like your ex is gonna be there! Get spiteful idk!\r\n(bring a jacket though it will be cold).	The Red Room Wine Bar: 2580 W Olympic Blvd Unit #2, Los Angeles, CA 90006	2023-12-26	21:30:00	23:00:00	Infinity	1	2023-12-26 21:19:30.634094	sadonis-e-34e0cc.png
6	The Second Lorem Ipsum	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce porta erat auctor, scelerisque erat et, laoreet ex.\r\n\r\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus id augue ex. Integer ac gravida quam. In vel suscipit ante. Phasellus maximus ante vitae purus finibus, at accumsan nisl pellentesque.\r\n\r\nNunc tempus leo eget tincidunt pharetra. Sed at gravida tellus. Mauris eget libero sodales ex commodo placerat ut ac odio. Morbi fermentum euismod augue vel ullamcorper.\r\n\r\nNullam luctus auctor libero at pulvinar. Curabitur in finibus lectus, scelerisque posuere velit. Aliquam mollis auctor vulputate. Nam eget lacinia magna. Proin laoreet justo in elit molestie hendrerit. In sed faucibus metus.	Lorem Ipsum 2222	2024-02-23	16:45:00	18:45:00	Infinity	6	2023-12-27 16:45:58.629818	admin-e-4d5c0b.png
2	Lorem Ipsum	Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce porta erat auctor, scelerisque erat et, laoreet ex.\r\n\r\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus id augue ex. Integer ac gravida quam. In vel suscipit ante. Phasellus maximus ante vitae purus finibus, at accumsan nisl pellentesque.\r\n\r\nNunc tempus leo eget tincidunt pharetra. Sed at gravida tellus. Mauris eget libero sodales ex commodo placerat ut ac odio. Morbi fermentum euismod augue vel ullamcorper.\r\n\r\nNullam luctus auctor libero at pulvinar. Curabitur in finibus lectus, scelerisque posuere velit. Aliquam mollis auctor vulputate. Nam eget lacinia magna. Proin laoreet justo in elit molestie hendrerit. In sed faucibus metus.	Lorem ipsum dolor	2024-01-25	12:00:00	14:00:00	Infinity	1	2023-12-26 00:06:29.046747	sadonis-e-3d2dcd.png
8	This is the 6th Event	YADA YADA YADA	Adnan's House	2024-02-04	20:30:00	21:30:00	Infinity	1	2023-12-27 20:28:45.98779	sadonis-e-d461aa.png
\.


--
-- Data for Name: events_participants; Type: TABLE DATA; Schema: public; Owner: adnan
--

COPY public.events_participants (id, event_id, participant_id, attendee_status) FROM stdin;
2	4	1	Y
1	2	1	N
3	2	6	Y
4	3	6	M
5	4	6	N
6	6	6	Y
7	6	1	M
8	7	1	Y
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: adnan
--

COPY public.users (id, name, username, pswhash, date_joined, profile_picture) FROM stdin;
1	Adnan Shihabi	sadonis	$2a$06$tg8ym9AcuKiJGq9.L9GMe.AbO/yS8Jcla2UzFLAfuKYsI.I6Q0vmW	2023-12-25 22:55:02.893965	sadonis-pfp.png
6	Admin Official	admin	$2a$06$JUWMePULpNv6BY.fEEwWr.ixuXWmnGq6W/DQmlPRjiaoS3cd6ryD6	2023-12-26 16:36:14.594497	admin-pfp.png
\.


--
-- Name: events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adnan
--

SELECT pg_catalog.setval('public.events_id_seq', 8, true);


--
-- Name: events_participants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adnan
--

SELECT pg_catalog.setval('public.events_participants_id_seq', 8, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adnan
--

SELECT pg_catalog.setval('public.users_id_seq', 6, true);


--
-- Name: events_participants events_participants_event_id_participant_id_key; Type: CONSTRAINT; Schema: public; Owner: adnan
--

ALTER TABLE ONLY public.events_participants
    ADD CONSTRAINT events_participants_event_id_participant_id_key UNIQUE (event_id, participant_id);


--
-- Name: events_participants events_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: adnan
--

ALTER TABLE ONLY public.events_participants
    ADD CONSTRAINT events_participants_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: adnan
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: adnan
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: adnan
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: events events_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adnan
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: events_participants events_participants_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adnan
--

ALTER TABLE ONLY public.events_participants
    ADD CONSTRAINT events_participants_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: events_participants events_participants_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adnan
--

ALTER TABLE ONLY public.events_participants
    ADD CONSTRAINT events_participants_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--


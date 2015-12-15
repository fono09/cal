CREATE TABLE config (
	deadline TEXT,
	password TEXT,
	appointment_calendar TEXT,
);
CREATE TABLE users (
	email TEXT PRIMARY KEY,
	name TEXT,
	access_token TEXT,
	access_token_secret TEXT,
	status TEXT,
	turn_in_calenar TEXT,
	fix_calendar TEXT,
);
CREATE TABLE calendar_list (
	user_id INTEGER PRIMARY KEY,
	calendar_id
);

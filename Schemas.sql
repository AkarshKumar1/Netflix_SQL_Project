DROP TABLE IF EXISTS netflix;

CREATE TABLE netflix (
    show_id varchar(10) PRIMARY KEY,
    type varchar(10),
    title varchar(255),
    director varchar(255),
    cast TEXT,              -- Changed to TEXT for long cast lists
    country varchar(255),
    date_added varchar(50),
    release_year INT,
    rating varchar(15),
    duration varchar(20),
    listed_in TEXT,         -- Changed to TEXT for long genre lists
    description TEXT        -- Changed to TEXT for long summaries
);

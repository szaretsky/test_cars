# Testcars

## Usage
exe/etaserver.rb
ETA calculation service

Main job is made by tcp server which is built with EventMachine.
EventMachine allows us to keep more than 1024 connections at the same time( by means of epoll). Service API uses msgpack. It is easy to make a client in any popular language.

Server keeps cache of car possitions which is refreshed every second and all geo calculations are made by service for each request (using side lib for it)
For 1000 cars it can produce 400 rps for 10k connected clients ( for 100 cars it is 4000rps )


exe/httpserver.rb
Http server keeps persistent connections to eta service.


Database:
CREATE SEQUENCE carseq_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE cars (
    lat double precision NOT NULL,
    lon double precision NOT NULL,
    avail boolean DEFAULT false,
    car_id integer DEFAULT nextval('carseq_id'::regclass) NOT NULL
);


As far it is a sort of test server, there is no fallback logic. No reconnections and so on.

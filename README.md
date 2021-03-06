#AMDash

This Rails app offers users a brief overview of the day ahead of them.  It 
provides weather, traffic info, the day's calendar, and top news items. 
This is a proof of concept.  The goal is to transform this into the backend
of a dashboard app that would appear on an AppleTV or Chromecast. 

For a live demo of this app, check out [am-dash.herokuapp.com](http://am-dash.herokuapp.com)

## APIs

This web application pulls data from a handful of different sources.

* Registration uses oauth2 to connect with a Google account
* News Section leverages API requests to NYTimes Articles API
* Map section sends users' location coordinates to Google's Maps API
* Events section pulls from user's Google Calendar API
* Weather forecast consumes data from Forecast.io API

If you're going to run this app locally, you'll need to obtain API
keys from Google, NYTimes, and ForecastIO.  And in the Google Developer
Console, be sure to enable the Google Calendar API  and Google Maps
Javascript API.

## Running the app
The app requires a bunch of environment variables. In development and test environments,
the app uses the `dotenv` gem to set environment variables.

Create a .env file and add the following API keys:

```
export AM_DASH_NYT_KEY=< NYP API Key>

export AM_DASH_GOOGLE_BROWSER_KEY=< GOOGLE API KEY FOR BROWSER REQUESTS >
export AM_DASH_GOOGLE_KEY=< GOOGLE OAUTH CLIENT API KEY >
export AM_DASH_GOOGLE_SECRET=< GOOGLE OAUTH CLIENT API SECRET >

export AM_DASH_FORECAST_IO_KEY=< ForecastIO KEY > 

export AM_DASH_WORKER="sucker_punch"
export AM_DASH_APP_NAME="A.M. Dash Local"

```


## Automated Tests

Test coverage focuses on the business logic, which is located in `lib/am_dash`.

To run the test suite, run this at the command line:

```
bundle exec rspec
```


## Worker
There's a lightweight worker being used to process jobs.  Currently, it's not even asynchronous
but I wanted to lay the foundation for using workers in this first iteration.
Building on this (with, say Resque) should be pretty straightforward.


## Rake Task
There's a rake task that can be used to download and cache all the necessary data for all users. 
Ideally, this would be run around sunrise, so that all the data would be downloaded for all
users and the app would seem super fast.


## To Do List for Next Iteration 
* Add cucumber!  App needs way more integrations tests. Doesn't feel right. 
* Use Ember and setup individual API requests for news, weather, events, and account summary
* Allow for editing of location
* Remove Devise in favor of smaller, hand-rolled solution
* Add Errors controller:w
kkkkkkkkkkk

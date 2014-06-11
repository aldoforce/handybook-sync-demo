handybook-sync-demo
========================

Tolerant fault, Event Machine based daemon ruby app that subscribes to Salesforce Streaming API and synchronize Salesforce data into an external Database. Deploy to heroku as a worker dyno.

Remember to configure the environment variables:

```ruby
RACK_ENV=
SF_LOGIN_HOST=login.salesforce.com
SF_USERNAME=
SF_PASSWORD=
SF_TOKEN=
SF_EXTERNAL_APP_CLIENT_ID=
SF_EXTERNAL_APP_CLIENT_SECRET=
SF_RESTFORCE_DEBUG=false
```
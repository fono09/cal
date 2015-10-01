require 'google/apis/calendar_v3'
require 'google/api_client/client_secrets'
require 'sinatra'

enable :sessions

def calendar; settings.calendar; end

def user_credentials
	@authorization ||= (
		auth = settings.authorization.dup
		auth.redirect_uri = to('/oauth2callback')
		auth.update_token!(session)
		auth
	)
end

configure do
	Google::Apis::ClientOptions.default.application_name = 'Class schedule into your calendar'
	Google::Apis::ClientOptions.default.application_version = '1.0.0'
	calendar_api = Google::Apis::CalendarV3::CalendarService.new

	client_secrets = Google::APIClient::ClientSecrets.load
	authorization = client_secrets.to_authorization
	authorization.scope = 'https://www.googleapis.com/auth/calendar'

	set :authorization, authorization
	set :calendar, calendar_api
end

before do
	unless user_credentials.access_token || request.path_info =~ /^\/oauth2/ then
		redirect to('/oauth2authorize')
	end
end

after do
	session[:access_token] = user_credentials.access_token
	session[:refresh_token] = user_credentials.refresh_token
	session[:expires_in] = user_credentials.expires_in
	session[:issued_at] = user_credentials.issued_at
end

get '/oauth2authorize' do
	redirect user_credentials.authorization_uri.to_s, 303
end

get '/oauth2callback' do
	user_credentials.code = params[:code] if params[:code]
	user_credentials.fetch_access_token!
	redirect to('/')
end

get '/' do
	events = calendar.list_events('primary', options: { authorization: user_credentials })
	content_type 'application/json', :charset => 'utf-8'
	[200, {'Content-Type' => 'application/json'}, events.to_h.to_json]
end



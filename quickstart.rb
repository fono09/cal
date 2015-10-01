require 'google/apis/calendar_v3'
require 'google/api_client/client_secrets'
require 'sinatra'

enable :sessions

def user_credentials
	@authorization ||= (
		auth = settings.authorization.dup
		auth.redirect_uri = to('/callback')
		auth.update_token!(session)
		auth
	)
end

configure do
	Google::Apis::ClientOptions.default.application_name = 'fono.jp cal sample'
	Google::Apis::ClientOptions.default.application_version = '1.0.0'
	calendar_api = Google::Apis::CalendarV3::CalendarService.new

	client_secrets = Google::APIClient::ClientSecrets.load
	authorization = client_secrets.to_authorization
	authorization.scope = 'https://www.googleapis.com/auth/calendar'

	set :authorization, authorization
	set :calendar, calendar_api
end

before do
	unless user_credentials.access_token || request.path_info =~ /^\/oauth2/
		redirect to('/authorize')
	end
end

after do
	session[:access_token] = user_credentials.access_token
	session[:refresh_token] = user_credentials.refresh_token
	session[:expires_in] = user_credentials.expires_in
	session[:issued_at] = user_credentials.issued_at
end

get '/authorize' do
	redirect user_credentials.authorization_uri.to_s, 303
end

get '/callback' do
	user_credentials.code = params[:code] if params[:code]
	user_credentials.fetch_access_token!
	redirect to('/')
end

get '/' do
	events = calendar.list_events('primary', options: { authorization: user_credentials })
	[200, {'Content-Type' => 'application/json'}, events.to_h.to_json]
end



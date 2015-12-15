require 'google/apis/calendar_v3'
require 'google/apis/plus_v1'
require 'google/api_client/client_secrets'
require 'json'
require 'sinatra'

enable :sessions

def calendar; settings.calendar; end
def plus; settings.plus; end

def user_credentials
	@authorization ||= (
		auth = settings.authorization.dup
		auth.redirect_uri = to('/oauth2callback')
		auth.update_token!(session)
		auth
	)
end

configure do
	Google::Apis::ClientOptions.default.application_name = 'TT-Shift'
	Google::Apis::ClientOptions.default.application_version = '1.0.0'
	plus_api = Google::Apis::PlusV1::PlusService.new
	calendar_api = Google::Apis::CalendarV3::CalendarService.new

	client_secrets = Google::APIClient::ClientSecrets.load
	authorization = client_secrets.to_authorization
	authorization.scope = [
		'https://www.googleapis.com/auth/calendar',
		'https://www.googleapis.com/auth/userinfo.email',
	]


	set :authorization => authorization,
		:calendar => calendar_api,
		:plus => plus_api
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
	
	buff = "calendar.list_events.items: \n"
	calendar.list_events('primary', options:{ authorization: user_credentials}).items.each do |obj|
		buff += obj.summary
	end
	buff += "==========\n"
	buff += "plus.get_person.emails: \n"
	plus.get_person('me',fields:'emails',options:{authorization: user_credentials}).emails.each do |obj|
		buff += obj.value.inspect
	end
	buff
end

get '/calendar/list' do
	ret = calendar.list_calendar_lists(max_results:10,options:{authorization: user_credentials}).items
	[200,{'Content-Type'=>'text/plain'},ret.to_json]
end

post '/calendar/add' do 
end

post '/calendar/edit' do
end






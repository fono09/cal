require 'google/apis/calendar_v3'
require 'google/apis/oauth2_v2'
require 'google/api_client/client_secrets'
require 'json'
require 'sinatra'
require './fancy_json/fancy_json.rb'
require 'uri'
require 'net/https'
require 'erubis'

enable :sessions

def calendar; settings.calendar; end
def userinfo; settings.userinfo; end

set :views, settings.root + '/views'

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
	userinfo_api = Google::Apis::Oauth2V2::Oauth2Service.new
	calendar_api = Google::Apis::CalendarV3::CalendarService.new

	client_secrets = Google::APIClient::ClientSecrets.load
	authorization = client_secrets.to_authorization
	authorization.scope = [
		'https://www.googleapis.com/auth/calendar',
		'https://www.googleapis.com/auth/userinfo.email',
	]
	authorization.authorization_uri(:access_type => :offline, :approval_prompt => :force)
	set :authorization => authorization,
		:userinfo => userinfo_api,
		:calendar => calendar_api
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

helpers do
end
			
	
get '/oauth2authorize' do
	redirect user_credentials.authorization_uri.to_s, 303
end

get '/oauth2callback' do
	user_credentials.code = params[:code] if params[:code]
	user_credentials.fetch_access_token!
	redirect to('/')
end

get '/skeleton' do
	@test = "ababababababababababababa"
	erb :skeleton
end

get '/' do
	
	ret = {
		:primary_calendar => calendar.list_events('primary', options:{ authorization: user_credentials}).items,
  		:userinfo => userinfo.get_userinfo(fields:'email', options:{ authorization: user_credentials}),
	}
	[200,{'Content-Type'=>'application/json'},ret.to_fj]
end

get '/calendar/list' do
	ret = calendar.list_calendar_lists(max_results:10,options:{authorization: user_credentials}).items
	[200,{'Content-Type'=>'application/json'},ret.to_fj]
end

post '/calendar/add' do 
	cal = Google::Apis::CalendarV3::Calendar.new()
	cal.summary = params[:summary]
	cal.description = params[:description]
	ret_insetr_cal = calender.insert_calendar(cal,options:{authentication: user_credentials})
	calendar_id = ret_cal.id
	entry = Google::Apis::CalendarV3::CalendarListEntry.new()
	ret_update_callist = calendar.update_calendar_list(calendar_id,calendar_list_entry_object:cal_list)
	[200,{'Content-Type'=>'application/json'},ret_update_callist.to_fj]
end

post '/calendar/edit' do
end

get '/calendar/:id/event/list' do
	ret = []
	page_token = nil
	begin
		temp = calendar.list_events(params[:id],page_token: page_token,options:{ authorization: user_credentials})
		ret.concat(temp.items)
	end  while page_token = temp.next_page_token
	
	[200,{'Content-Type'=>'application/json'},ret.to_fj]
end

get '/logout' do
	uri = URI('https://accounts.google.com/o/oauth2/revoke')
	params = { :token => user_credentials.access_token }
	uri.query = URI.encode_www_form(params)
	Net::HTTP.get(uri)
	user_credentials.clear_credentials!
	session.clear
	redirect to('/')
end
	
	


#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
	@db = SQLite3::Database.new 'Blogistan.db'
	@db.results_as_hash = true
end

before do
	init_db
end

configure do
	init_db

	@db.execute 'CREATE TABLE IF NOT EXISTS Posts 
	(
	    id				INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	    created_date 	DATE NOT NULL,
	    content 		TEXT
	)'
end

get '/' do

	#выбираем список постов из БД

	@results = @db.execute 'SELECT * FROM Posts ORDER BY id DESC'

	erb :index
end

get '/new' do
	erb :new
end

post '/new' do
	content = params[:content]

	if content.length <= 0
		@error = 'Type text'
		return erb :new
	end

	@db.execute 'insert into posts (content, created_date) values (?, datetime())', [content]

	#перенаправление на главную страницу
	redirect to '/'

	#erb "You typed #{content}"	
end

#вывод комментариев к посту

get '/details/:id' do
	post_id = params[:id]

	results = @db.execute 'SELECT * FROM Posts WHERE id =?', [post_id]
	@row = results[0]

	# проверка существования поста с таким id 
	# @results = @db.execute 'SELECT * FROM Posts WHERE id =?', [post_id]

	# unless @results.length > 0
	# 	@error = "error"
	# end

	erb :details
end

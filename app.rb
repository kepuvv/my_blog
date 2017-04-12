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

	@db.execute 'CREATE TABLE IF NOT EXISTS Comments 
	(
	    id				INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	    created_date 	DATE NOT NULL,
	    comment 		TEXT,
	    post_id			INTEGER
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

	@db.execute 'insert into Posts (content, created_date) values (?, datetime())', [content]

	#перенаправление на главную страницу
	redirect to '/'

	#erb "You typed #{content}"	
end

#вывод комментариев к посту

get '/details/:id' do

	# получаем переменную id из url
	post_id = params[:id]

	# получаем пост с этим id
	results = @db.execute 'SELECT * FROM Posts WHERE id =?', [post_id]

	# передаем только одну строку из results
	@row = results[0]

	@comments = @db.execute 'SELECT * FROM Comments WHERE post_id =? ORDER BY created_date', [post_id]

	# проверка существования поста с таким id 
	unless results.length > 0
	 	@error = "error"
	 	erb :notyet
	else
		erb :details
	end
end

# обработчик post-запроса /datails (комментарий)
# браузер отправляет данные на сервер
post '/details/:id' do

	# получаем переменную из URL
	post_id = params[:id]

	# получаем переменную из post-запроса
	comment = params[:comment]

	content = params[:content]

	if comment.length <= 0
		@error = 'Type text'
		return erb :details
	end

	@db.execute 'insert into Comments (comment, post_id, created_date) values (?, ?, datetime())', [comment, post_id]

	redirect to "/details/#{post_id}"
end

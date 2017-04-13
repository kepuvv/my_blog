#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
	@db = SQLite3::Database.new 'Blogistan.db'
	@db.results_as_hash = true
end

# вытягиваем пост и комменты к нему из БД
def get_post_and_comments post_id, db
	# получаем пост с этим id
	results = db.execute 'SELECT * FROM Posts WHERE id =?', [post_id]

	#проверка существования поста с таким id 
	if results.length <= 0
		@error = 'We cant find this post'
		return @error
	end

	# передаем только одну строку из results
	@row = results[0]

	# выбираем комментарии для поста
	@comments = db.execute 'SELECT * FROM Comments WHERE post_id =? ORDER BY created_date', [post_id]
	return @row, @comments
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
	    content 		TEXT,
	    author			TEXT
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

	# выбираем список постов из БД

	@results = @db.execute 'SELECT * FROM Posts ORDER BY id DESC'

	erb :index
end

get '/new' do
	erb :new
end

post '/new' do
	content = params[:content]
	author = params[:author]

	if content.length <= 0
		@error = 'Type text'
		return erb :new
	elsif 
		author.length <= 0
		@error = 'Enter you name'
		return erb :new
	end

	@db.execute 'insert into Posts (content, author, created_date) values (?,?, datetime())', [content, author]

	# перенаправление на главную страницу
	redirect to '/'	
end

# вывод комментариев к посту

get '/details/:id' do

	# получаем переменную id из url
	post_id = params[:id]

	get_post_and_comments post_id, @db

	# если поста с таким id нет, то выдает ошибку
	unless @error  
		erb :details 
		else
		erb :notyet
	end
end

# обработчик post-запроса /datails (комментарий)
# браузер отправляет данные на сервер
post '/details/:id' do

	# получаем переменную из URL
	post_id = params[:id]

	# получаем переменную из post-запроса
	comment = params[:comment]

	get_post_and_comments post_id, @db

	# проверка пустого коммента
	if comment.length <= 0
		@error = 'Type text'
		return erb :details
	end

	# добавляем коммент в БД
	@db.execute 'insert into Comments (comment, post_id, created_date) values (?, ?, datetime())', [comment, post_id]

	redirect to '/details/' + post_id
end

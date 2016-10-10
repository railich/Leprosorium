#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
  @db = SQLite3::Database.new 'leprosorium.db'
  @db.results_as_hash = true
end

before do
  init_db
end

configure do
  init_db
  @db.execute 'CREATE TABLE IF NOT EXISTS Posts
  (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_date DATE,
    content TEXT
  )'

  @db.execute 'CREATE TABLE IF NOT EXISTS Comments
  (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_date DATE,
    content TEXT,
    post_id INTEGER
  )'
end

helpers do
  def comments_count(post_id)
    result = @db.execute '
      SELECT COUNT(id) AS comment_count
      FROM Comments
      WHERE post_id = ?', [post_id]

    result[0]['comment_count']
  end
end

get '/' do
  @posts = @db.execute 'SELECT * FROM Posts ORDER BY id DESC'

  erb :index
end

get '/new' do
  @message = ''
  erb :new
end

post '/new' do
  @content = params[:content]

  if @content.length == 0
    @message = '<span style="color: red;">Type post text!</span>'

    return erb :new
  end

  @db.execute 'INSERT INTO Posts (content, created_date)
    VALUES (?, datetime())' , [@content]

    redirect to '/'
end


get '/post/:post_id' do
  post_id = params[:post_id]

  results = @db.execute 'SELECT * FROM Posts WHERE id = ?', [post_id]
  @post = results[0]

  @comments = @db.execute 'SELECT * FROM Comments WHERE post_id = ?', [post_id]

  erb :post_detail
end

post '/post/:post_id' do
  post_id = params[:post_id]
  comment = params[:content]
  @db.execute 'INSERT INTO Comments (post_id, content, created_date)
    VALUES (?, ?, datetime())', [post_id, comment]

  redirect to "/post/#{post_id}"
end

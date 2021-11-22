#!/usr/bin/env ruby
require 'sinatra'
require 'securerandom'
require './auth.rb'
require 'rmagick'

enable :sessions
set :port, 3001

USERS = Auth::Storage.new

get "/" do
  erb :form
end

post "/save_image" do
  file = params[:my_file][:tempfile]
  temp_name = file.path
  input_name = params[:my_file][:filename]
  output_name = SecureRandom.uuid + File.extname(input_name)

  cartinka=Magick::ImageList.new(temp_name)
  text1=Magick::Draw.new
  text1.gravity=Magick::NorthGravity
  text1.font_family="Impact"
  text1.pointsize=50
  text1.stroke="none"
  text1.fill='white'
  text1.annotate(cartinka, 0, 0, 0, 40, "#{params[:top_text]}")
  text2=Magick::Draw.new
  text2.gravity=Magick::SouthGravity
  text2.font_family="Impact"
  text2.pointsize=50
  text2.stroke="none"
  text2.fill='white'
  text2.annotate(cartinka, 0, 0, 0, 40, "#{params[:bottom_text]}")

  cartinka.cur_image["Comment"]="{\"top\": \"#{params[:top_text]}\", \"bot\": \"#{params[:bottom_text]}\"}"
  
  cartinka.write("public/uploads/#{output_name}")

  if current_user
    @filename = output_name
    erb :show_image
  else
    session[:redirect_to_image] = output_name
    redirect "/sign_in"
  end
end

get "/view_image" do
  @filename = session[:redirect_to_image]
  erb :show_image
end

get "/sign_in" do
  erb :sign_in
end

post "/sign_in" do
  user = USERS.user_by_name(params[:username])
  if user && user.test_password(params[:password])
    session[:user_id] = user.id
    redirect '/'
  else
    @error = 'Username or password was incorrect'
    erb :sign_in
  end
end

post '/register' do
  user_id = USERS.add_user(params[:username], params[:password])
  if user_id
    session[:user_id] = user_id
    after_login
  else
    @error = "Username already exists"
    erb :sign_in
  end
end

helpers do
  def current_user
    if session[:user_id]
       USERS.user_by_id(session[:user_id])
    else
      nil
    end
  end

  def after_login
    if session[:redirect_to_image]
      redirect "/view_image"
    else
      redirect "/"
    end
  end
end

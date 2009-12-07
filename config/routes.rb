ActionController::Routing::Routes.draw do |map|
  map.resources :sessions, :only => [:create, :new, :destroy]
end
AuthorizeNetEvent::Engine.routes.draw do
  root to: 'authorize_net_notification#event', via: :post
end

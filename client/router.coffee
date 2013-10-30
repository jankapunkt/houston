Meteor.subscribe 'admin'
Meteor.subscribe 'adminUser'

window['look_up_collection'] = (name) ->
  # you can only instantiate a collection once
  try
    new Meteor.Collection(name)
  catch e
    Meteor._LocalCollectionDriver.collections[name]

setup_collection = (collection_name) ->
  subscription_name = "admin_#{collection_name}"
  inspector_name = "inspector_#{collection_name}"

  unless window[inspector_name]
    window[inspector_name] = look_up_collection(collection_name)
  Meteor.subscribe subscription_name
  Session.set("collection_name", collection_name)
  return window[inspector_name]

Meteor.Router.add
  '/admin': ->
    Session.set "collections", Collections.find().fetch()
    return 'db_view'

  '/admin/login': 'admin_login'

  '/admin/:collection': (collection_name) ->
    collection = setup_collection collection_name
    return 'collection_view'

  '/admin/:collection/:document': (collection_name, document_id) ->
    collection = setup_collection collection_name
    Session.set('document_id', document_id)
    return 'document_view'

Meteor.Router.filters
  'isAdmin': (page) -> if Meteor.user()?.profile.admin then page else 'admin_login'

Meteor.Router.filter 'isAdmin', only: ['db_view', 'collection_view', 'document_view']

window.get_fields = (documents) ->
  key_to_type = {_id: 'ObjectId'}
  find_fields = (document, prefix='') ->
    for key, value of _.omit(document, '_id')
      if typeof value is 'object'
        find_fields value, "#{prefix}#{key}."
      else if typeof value isnt 'function'
        full_path_key = "#{prefix}#{key}"
        key_to_type[full_path_key] = typeof value

  for document in documents
    find_fields document

  (name: key, type: value for key, value of key_to_type)

window.lookup = (object, path) ->
  return '' unless object?
  return object._id._str if path =='_id'and typeof object._id == 'object'
  result = object
  for part in path.split(".")
    result = result[part]
    return '' unless result?  # quit if you can't find anything here
  if typeof result isnt 'object' then result else ''

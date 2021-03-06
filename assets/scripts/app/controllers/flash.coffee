Travis.FlashController = Ember.ArrayController.extend
  needs: ['currentUser']
  currentUserBinding: 'controllers.currentUser'

  init: ->
    @_super.apply this, arguments
    @set('flashes', Travis.LimitedArray.create(limit: 2, content: []))

  content: (->
    broadcasts = @get('unseenBroadcasts')
    flashes = @get('flashes')
    content = []
    content = content.concat(broadcasts.toArray()) if broadcasts
    content = content.concat(flashes.toArray().reverse())    if flashes
    content.uniq()
  ).property('unseenBroadcasts.length', 'flashes.length')

  unseenBroadcasts: (->
    @get('broadcasts').filterProperty('isSeen', false)
  ).property('broadcasts.isLoaded', 'broadcasts.length')

  broadcasts: (->
    if @get('currentUser.id') then Travis.Broadcast.find() else Ember.A()
  ).property('currentUser.id')

  loadFlashes: (msgs) ->
    for msg in msgs
      type = Ember.keys(msg)[0]
      msg = { type: type, message: msg[type] }
      @get('flashes').unshiftObject(msg)
      Ember.run.later(this, (-> @get('flashes.content').removeObject(msg)), 15000)

  close: (msg) ->
    if msg instanceof Travis.Broadcast
      msg.setSeen()
      @notifyPropertyChange('unseenBroadcasts')
    else
      @get('flashes').removeObject(msg)


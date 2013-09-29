# Coffeescript for superluminal podcast catcher

@Feeds = new Meteor.Collection "Feeds"
@Podcasts = new Meteor.Collection "Podcasts"
#Podcasts.remove {}

###---------------------
---- Podcast Model -----
---------------------###
Podcast = (podcast) ->
  attrs = ['feed_id', 'title', 'url', 'length', 'pubDate', 'description', 'link', 'guid']
  req_attrs = ['feed_id', 'title', 'url', 'pubDate']


  # verify requried properties are not empty
  _(req_attrs).each (prop) =>
    if _.isEmpty podcast[prop]
      throw new Error("Podcast is missing required property: #{prop}")

  podcast.pubDate = new Date(podcast.pubDate)

  if Podcasts.findOne {url: podcast.url}
    throw new Error("Feed with url #{podcast.url} already exits")

  # copy properties to constructed object
  _(attrs).each (prop) =>
    this[prop] = podcast[prop]

###------------------
---- Feed Model -----
------------------###
Feed = (feed) ->
  attrs = ['url', 'title', 'link', 'description', 'image']
  req_attrs = ['title', 'url']


  # verify requried properties are not empty
  _(req_attrs).each (prop) =>
    if _.isEmpty feed[prop]
      throw new Error("Feed is missing required property: #{prop}")

  if Feeds.findOne {url: feed.url}
    throw new Error("Feed with url #{feed.url} already exits")

  # copy properties to constructed object
  _(attrs).each (prop) =>
    this[prop] = feed[prop]

  return this


if Meteor.isClient
  Template.subscriptions.feeds = () ->
    return  Feeds.find {}

  Template.podcasts.casts = () ->
    return  Podcasts.find {}, {sort: {'pubDate': -1}}


  Template.subscriptions.events = {
    'click #Subscribe' : (a, template) ->
      feed_url = template.find('input#feed_url').value
      Meteor.call 'new_feed', feed_url, (error, result) -> console.log(result)
    'click #Update': (a, template) ->
      Feeds.find({}).forEach (feed) ->
        Meteor.call 'update_feed', feed
  }

if  Meteor.isServer
  cheerio = Meteor.require 'cheerio'
  Meteor.startup () ->
    # code to run on server at startup

  Meteor.methods
    # Create a new feed from the passed url
    new_feed: (url) ->
      console.log '----------------------------------------------'
      response = HTTP.get url
      xml = response.content
      $ = cheerio.load xml,
        ignoreWhitespace: true,
        xmlMode: true
      console.log '----------------------------------------------'

      feed = {
        url: url,
        title: $('channel > title').text(),
        link: $('channel > link').text(),
        description: $('channel > description').text(),
        image: $('channel > image > url').text()
      }

      feed = new Feed feed
      Feeds.insert(feed)

    update_feed: (feed) ->
      console.log '----------------------------------------------'
      console.log "#{feed.title}: getting podcasts"
      response = HTTP.get feed.url
      xml = response.content
      $ = cheerio.load xml,
        ignoreWhitespace: true,
        xmlMode: true

      items = $('channel > item')

      items.each (i, el) ->
        podcast = {feed_id: feed._id}

        attrs = ['title', 'description', 'link', 'guid']
        _(attrs).each (attr) =>
          podcast[attr] = this.find(attr).text()

        # Get the podcasts url
        podcast.url = this.find('enclosure').attr('url')

        # I don't know what this measures, file size? length?
        podcast.length = this.find('enclosure').attr('length')

        # I have no ideah why this.find('pubDate') doesn't work,
        # and this does. I hate it.
        _(this.children()).each (child) ->
          if child.name == 'pubDate'
            podcast.pubDate = child.children[0].data

        try
          podcast = new Podcast(podcast)
          Podcasts.insert(podcast)
          console.log('added')
        catch err
          console.log err.message


      console.log '----------------------------------------------'

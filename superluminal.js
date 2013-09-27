var require = __meteor_bootstrap__.require;
var cheerio = require('cheerio');

function get_feed(feed_url) {
  $.ajax({
  url      : document.location.protocol
    + '//ajax.googleapis.com/ajax/services/feed/load?v=1.0&num=10&callback=?&q='
    + encodeURIComponent(feed_url),
  dataType : 'json',
  success  : function (data) {
    console.log(data);
  }
  });
}

if (Meteor.isClient) {
  Template.subscriptions.feeds = function () {
    return ["The World", "RadioLab"];
  };

  Template.subscriptions.events({
    'click #Subscribe' : function (a, template) {
      feed_url = template.find('input#feed_url').value;
      Meteor.call("parse_feed", feed_url);
    }
  });
}

if (Meteor.isServer) {
  Meteor.startup(function () {
    // code to run on server at startup
  });

  Meteor.methods({
    parse_feed: function(url) {
      console.log(url);
      var response = HTTP.get(url);
      var xml = response.content;
    }
  });
}

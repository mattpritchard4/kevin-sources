search_phrases = [
  "sources:",
  "sources say",
  "sources confirm",
  "sources point to",
  "sources indicate"
]


namespace :tweets do
  desc "TODO"
  task crawl_latest: :environment do
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV.fetch("TWITTER_CONSUMER_KEY")
      config.consumer_secret     = ENV.fetch("TWITTER_CONSUMER_SECRET")
      config.access_token        = ENV.fetch("TWITTER_ACCESS_TOKEN")
      config.access_token_secret = ENV.fetch("TWITTER_ACCESS_SECRET")
    end

    tweets_to_check = collect_tweets(client)
    tweets_to_check.each do |tweet|
      if tweet.text.match(/(sources(\:| say| confirm| point to| indicate))/)
        tweet.retweet
      end
    end
  end
end

def collect_tweets(client, time_floor=Time.now - 10.minutes)
  tweets = []
  last_seen_time = Time.now
  until tweets.size > 1000 || last_seen_time < time_floor do
    tweets += client.home_timeline({count: 200, include_rts: false})
    tweets.flatten
    last_seen_time = tweets.last.created_at
  end

  tweets
end

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
    Rails.logger.info("starting tweet crawl of past 30 minutes.")
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV.fetch("TWITTER_CONSUMER_KEY")
      config.consumer_secret     = ENV.fetch("TWITTER_CONSUMER_SECRET")
      config.access_token        = ENV.fetch("TWITTER_ACCESS_TOKEN")
      config.access_token_secret = ENV.fetch("TWITTER_ACCESS_SECRET")
    end

    tweets_to_check = collect_tweets(client)
    tweets_to_check.each do |tweet|
      if tweet.text.match(/(sources(\:| say| confirm| point to| indicate))/) || tweet.text.match(/sources/)
        unless SeenTweet.where(tweet_id: tweet.id).exists?
          Rails.logger.info("I'll be retweeting this: #{tweet.id} #{tweet.text}")
          client.update("Hey look, @#{tweet.user.screen_name} is talking about me! #{tweet.uri}")
          SeenTweet.create!(tweet_id: tweet.id)
        end
      end
    end

    Rails.logger.info("crawled #{tweets_to_check.count} tweets this time")
  end
end

def collect_tweets(client, time_floor=Time.now - 30.minutes)
  tweets = []
  # last_seen_time = Time.now
  options = {count: 200, include_rts: false}
  until tweets.size > 1000 do # || last_seen_time < time_floor do
    begin
      new_tweets = client.home_timeline(options)
      tweets += new_tweets
      tweets.flatten
      options[:max_id] = new_tweets.last.id - 1
    rescue Twitter::Error::TooManyRequests => error
      Rails.logger.info("Hit Twitter rate limit, sleeping #{error.rate_limit.reset_in+1} seconds")
      sleep error.rate_limit.reset_in + 1
      retry
    end
    # last_seen_time = tweets.last.created_at
  end

  tweets
end

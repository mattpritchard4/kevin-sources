namespace :tweets do
  desc "TODO"
  task crawl_latest: :environment do
    Rails.logger.info("starting tweet crawl of past 1000 tweets.")
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV.fetch("TWITTER_CONSUMER_KEY")
      config.consumer_secret     = ENV.fetch("TWITTER_CONSUMER_SECRET")
      config.access_token        = ENV.fetch("TWITTER_ACCESS_TOKEN")
      config.access_token_secret = ENV.fetch("TWITTER_ACCESS_SECRET")
    end

    tweets_to_check = collect_tweets(client)
    tweets_to_check.each do |tweet|
      if tweet.text.match(/\b(sources(\:| say| confirm| point to| indicate| have))|\b(source(\:| says| said| confirm| point| indicate| has))/)
        unless SeenTweet.where(tweet_id: tweet.id).exists?
          Rails.logger.info("I'll be retweeting this: #{tweet.id} #{tweet.text}")
          client.update("Hey look, @#{tweet.user.screen_name} is talking about me! #{tweet.uri}")
          SeenTweet.create!(tweet_id: tweet.id)
        end
      end
    end
    Rails.logger.info("Last tweet processed was sent #{(Time.now - tweets_to_check.last.created_at)/60} minutes ago.")
    Rails.logger.info("crawled #{tweets_to_check.count} tweets this time")
  end
end

def collect_tweets(client, time_floor=Time.now - 30.minutes)
  tweets = []
  stop_crawling = false
  # last_seen_time = Time.now
  options = {count: 200, include_rts: false}
  until tweets.size > 1000 || stop_crawling do # || last_seen_time < time_floor do
    begin
      new_tweets = client.home_timeline(options)

      if new_tweets.empty?
        stop_crawling = true
      else
        options[:max_id] = new_tweets.last.id - 1
      end

      tweets += new_tweets
    rescue Twitter::Error::TooManyRequests => error
      Rails.logger.info("Hit Twitter rate limit, sleeping #{error.rate_limit.reset_in+1} seconds")
      sleep error.rate_limit.reset_in + 1
      retry
    end
    # last_seen_time = tweets.last.created_at
  end

  tweets.flatten
end

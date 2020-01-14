class CreateSeenTweets < ActiveRecord::Migration[6.0]
  def change
    create_table :seen_tweets do |t|
      t.string :tweet_id

      t.timestamps
    end
    add_index :seen_tweets, :tweet_id
  end
end

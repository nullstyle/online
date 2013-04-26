# Online

A simple, and fast "who is online right now" tracker that uses redis and quantized time slices to keep
things fast and lightweight.

## Installation

Add this line to your application's Gemfile:

    gem 'online'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install online

## Usage

```ruby

# create an online tracker by providing a redis client object

$online = Online::Tracker.new(some_redis_client)

# mark an id (any opaque identifier) online
$online.set_online('user_123')

#interrogate status
$online.online? "user_123"  # => true
$online.offline? "user_123" # => false

#by default, a user is marked offline automatically around 3 minutes after they are last seen

# 3 MINUTES PASS
$online.online? "user_123"  # => false
$online.offline? "user_123" # => true

# If a user logs out, you can explicitly mark them as offline

$online.set_offline "user_123"


# create an online tracker with a specific timeout value after which a user is considered offline

$online = Online::Tracker.new(some_redis_client, 600) # ten minute timeout


```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

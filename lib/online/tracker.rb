module Online
  # 
  # Keeps a fuzzy set of 'online' users in a provided redis store.  
  # 
  class Tracker
    SLICE_COUNT = 6

    # 
    # Creates a new tracker using the provided redis client. 
    # 
    # @param  redis [Redis] the redis client to use
    # @param  online_expiration_time=180 [Fixnum] The amount of inactivity in seconds in which to consider an id 'offline' 
    # 
    # @return [type] [description]
    def initialize(redis, online_expiration_time=180)
      @online_expiration_time = 180
      @redis = redis
      # uses floating point division + ceiling to round up
      @slice_size = (online_expiration_time.to_f / SLICE_COUNT).ceil
      @active_bucket_count = (@online_expiration_time.to_f / @slice_size).ceil
    end

    def set_online(id)
      slice_time = active_bucket_times.first
      key        = bucket_key(slice_time)
      expires_at = slice_time.to_i + (@slice_size * SLICE_COUNT)

      @redis.multi do
        @redis.sadd(key, id)
        @redis.expireat key, expires_at
      end
    end

    def set_offline(id)
      @redis.pipelined do
        active_bucket_keys.each{|k| @redis.srem key, id }
      end
    end

    def online?(id)
      @redis.pipelined do
        active_bucket_keys.each{|k| @redis.sismember k, id }
      end.any?
    end

    def offline?(id)
      !online?(id)
    end

    def all_online
      @redis.pipelined do
        active_bucket_keys.each{|k| @redis.smembers key }
      end.inject(&:|)
    end

    private
    # 
    # Returns a list of keys that represent the sets of online users
    # from the provided time
    # @param  starting_at=Time.now [Time] [description]
    # 
    # @return [Array<Time>] the quantized times for active buckets
    def active_bucket_times(starting_at=Time.now)
      keys = []
      starting_at = starting_at.utc
      @active_bucket_count.times do 
        keys << quantize_time_to_slize_size(starting_at)
        starting_at -= @slice_size
      end
      keys
    end

    # 
    # The list of keys for buckets that are active
    # 
    # @return [type] [description]
    def active_bucket_keys
      active_bucket_times.map &method(:bucket_key)
    end

    # 
    # Rounds the provided time down to the appropriate bucketed time
    # 
    # @param  time [Time] the starting time
    # 
    # @return [Time] The quantized time
    def quantize_time_to_slize_size(time)
      seconds_since_epoch = time.to_i
      remainder = seconds_since_epoch % @slice_size
      Time.at(seconds_since_epoch - remainder)
    end


    # 
    # Converts a time to a bucket key
    # @param  time [Time] the time
    # 
    # @return [String] the key
    def bucket_key(time)
      id = quantize_time_to_slize_size(time.utc).to_i
      "online:slice:#{id}"
    end

  end

end
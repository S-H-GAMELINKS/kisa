# Kisa(岐佐)

Kisa(岐佐) is simple Mastodon API Library.

## Installation

```bash
gem install kisa
```

## Usage

```ruby
conn = Kisa.new(url: "https://your.mastodon.server", headers: {'Authorization' => 'token'})

conn.user_stream do |event_type, data|
  puts event_type
  puts data
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/S-H-GAMELINKS/kisa.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

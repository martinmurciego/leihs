#!/usr/bin/env ruby
require 'yaml'

CONFIG_DIR = './config'

releases = Dir.glob("#{CONFIG_DIR}/releases/*.md").map do |rel_file|
  raw = File.read(rel_file)
  data = YAML.safe_load(raw)
  description = raw.split('---').slice(2).strip
  data.merge('description' => description)
end

fail 'no data!' unless releases.length > 0

data = {'releases' => releases.reverse}

File.write("#{CONFIG_DIR}/releases.yml", data.to_yaml)

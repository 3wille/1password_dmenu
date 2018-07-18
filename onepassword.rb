#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "clipboard"

ACTIONS = ["Copy", "Open"].freeze

def main
  short_items = get_short_items
  short_item = choose_item(short_items)
  chosen_item = get_full_item(short_item)
  chosen_action = choose_action
  execute_action(chosen_action, item: chosen_item)
end

def execute_action(action, item:)
  case action.strip
  when "Copy"
    exec_copy(item)
  when "Open"
  end
end

def exec_copy(item)
  password = get_password(item)
  Clipboard.copy(password)
end

def get_password(item)
  fields = item["details"]["fields"]
  index = fields.index do |field|
    field["designation"] == "password"
  end
  password_field = fields[index]
  password_field["value"]
end

def choose_action
  `echo -e "#{ACTIONS.join('\n')}" | dmenu`
end

def get_full_item(short_item)
  uuid = short_item["uuid"]
  JSON.parse(`op get item #{uuid}`)
end

def choose_item(items)
  item_list = items.keys.join("\n")
  item_string = `echo -e "#{item_list}" | dmenu`.strip
  items[item_string]
end

def get_short_items
  output = `op list items`
  items = JSON.parse(output)
  items.inject({}) do |mapped, item|
    title = item["overview"]["title"]
    mapped[title] = item
    mapped
  end
end

main

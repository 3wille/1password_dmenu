#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "byebug"
require "clipboard"
require "active_support/all"

ACTIONS = ["Copy", "Open"].freeze

OP_ADDRESS = ENV["OP_ADDRESS"]
OP_EMAIL = ENV["OP_EMAIL"]
OP_SECRET_KEY = ENV["OP_SECRET_KEY"]

def main
  check_login_and_authenticate
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

def check_login_and_authenticate
  _, error, _ = Open3.capture3("op get item a")
  if error =~ /You are not currently signed in./
    authenticate_1p!
  end
end

def authenticate_1p!
  password = dmenu_password
  if password.present?
    output = `op signin #{OP_ADDRESS} #{OP_EMAIL} #{OP_SECRET_KEY} #{password}`
    session_key = output.match(/\"(.*)\"/)&.captures&.first
    if session_key.blank?
      authenticate_1p!
    end
    ENV["OP_SESSION_my"] = session_key
  else
    exit
  end
end

def dmenu_password
  `dmenu -p \"1Password Master Password\" -fn 'Consolas:size=10' -nf '#204a87' -nb '#204a87' -sf black -sb '#babdb6' <&-`
end

main

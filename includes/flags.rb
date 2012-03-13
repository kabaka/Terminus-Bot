
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2012 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

# TODO: Reimplement without all this confusing table/index stuff that doesn't
# actually save us any memory with such small amounts of data.

class Script_Flags < Hash

  def initialize
    @scripts = []

    # This is here because YAML doesn't know how to initialize us with it after
    # pullingthe flags table back out of the database.
    # TODO: Correctly deal with rehashing since this likely won't pick up on it.
    @default_flag = $bot.config['flags']['default'] rescue true

    super
  end

  def add_server(server)
    self[server] ||= Hash.new
  end


  def add_channel(server, channel)
    self[server][channel] ||= Hash.new
  end


  # New script loaded. Add it if we don't already have it.
  def add_script(name)
    return if @scripts.include? name

    @scripts << name

    self.each_value do |server|
      server.each_value do |channel|
        channel[name] ||= 0
      end
    end

  end

  # Return true if the script is enabled on the given server/channel. Otherwise,
  # return false.
  def enabled?(server, channel, script)
    flag = self[server][channel][script] rescue 0
    
    case flag

    when -1
      return false

    when 0
      return @default_flag

    else
      return true

    end

  end


  # Enable all matching scripts for all matching servers and channels (by
  # wildcard match).
  def enable(server_mask, channel_mask, script_mask)
    set_flags(server_mask, channel_mask, script_mask, 1)
  end


  # Disable all matching scripts for all matching servers and channels (by
  # wildcard match).
  def disable(server_mask, channel_mask, script_mask)
    set_flags(server_mask, channel_mask, script_mask, -1)
  end

 
  # Do the hard work for enabling or disabling script flags. The last parameter
  # is the value which will be used for the flag.
  #
  # Returns the number of changed flags.
  def set_flags(server_mask, channel_mask, script_mask, flag)
    count = 0

    scripts = @scripts.select {|s| s.wildcard_match(script_mask)}

    $log.debug("script_flags.set_flags") { "#{server_mask} #{channel_mask} #{script_mask} #{flag}" }

    self.each_pair do |server, channels|
      next unless server.wildcard_match(server_mask)

      $log.debug("script_flags.set_flags") { "server: #{server}" }

      channels.each_pair do |channel, channel_scripts|
        next unless channel.wildcard_match(channel_mask)

        $log.debug("script_flags.set_flags") { "channel: #{channel}" }
        $log.debug("script_flags.set_flags") { "scripts: #{channel_scripts.keys.join(", ")}" }

        scripts.each do |script|

          $log.debug("script_flags.set_flags") { "script: #{script}" }
          
          if channel_scripts[script] != flag
            channel_scripts[script] = flag
            count += 1
          end

        end
      end
    end

    count
  end
end

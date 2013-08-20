require 'rally_rest_api'
require 'rainbow'

module Ut

  module Helpers

    module RallyHelper

      def username
        if ENV['RALLY_USERNAME']
          ENV['RALLY_USERNAME']
        else
          raise '`ENV["RALLY_USERNAME"]` must be provided.'
        end
      end

      def password
        if ENV['RALLY_PASSWORD']
          ENV['RALLY_PASSWORD']
        else
          raise '`ENV["RALLY_PASSWORD"]` must be provided.'
        end
      end

      def project_name
        if ENV['RALLY_PROJECT']
          ENV['RALLY_PROJECT']
        else
          raise '`ENV["RALLY_PROJECT"]` must be provided.'
        end
      end

      def base_url
        ENV['RALLY_URL'] || 'https://rally1.rallydev.com/slm'
      end

      def rally
        @rally ||= RallyRestAPI.new \
          :username => username,
          :password => password,
          :base_url => base_url
      end

      def project
        proj_name = project_name

        log "Fetching Rally project as #{proj_name}..."

        @project ||= rally.find(:project) {
          equal(:name, proj_name)
        }.first
      end

      def present_story(raw_story)
        description = raw_story.description

        {
          :plan_estimate        => raw_story.plan_estimate,
          :schedule_state       => raw_story.schedule_state,
          :task_estimate_total  => raw_story.task_estimate_total,
          :time_remaining_total => raw_story.time_remaining_total,
          :owner                => raw_story.owner,
          :description          => description,
          :ac                   => parse_description_for_tasks(description)
        }
      end

      # * Iterates through HTML nodes in the description
      # * Searches for a node containing a case-insensitive "requirements" in
      # <b></b>
      # * Until a newline or another node containing <b></b> is reached
      # * Appends nodes to a list in the meantime
      # * For each appended node, strip whitespace and "-" characters from
      # beginning
      #
      def parse_description_for_tasks(description)
        html         = Nokogiri::HTML description
        leaves       = []
        requirements = []

        recurse = lambda { |contents|
          contents.each do |content|
            if content.name == 'b' || content.name == 'li'
              leaves << content
            else
              recurse.call content.children
            end
          end
        }

        recurse.call html.css('body').children

        requirements_leaf = leaves.find { |leaf|
          leaf.name == 'b' && leaf.text.match(/requirements/i)
        }

        i = leaves.index(requirements_leaf) + 1

        loop do
          break if i == leaves.length || leaves[i].name == 'b'

          requirements << leaves[i].text

          i += 1
        end

        requirements
      end

      def add_tasks_from_requirements(story_number)
        rally_story = story story_number
        story_data  = present_story rally_story

        log "Adding tasks from requirements for '#{story_number}'..."

        story_data[:ac].each do |ac|
          add_task rally_story, ac, 1.0
        end
      end

      def log(str)
        puts str.color(:blue)
      end

      class StoryNotFound < Exception
      end

      class TaskNotFound < Exception
      end

    end

  end

end


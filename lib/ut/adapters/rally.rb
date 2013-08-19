require 'rally_rest_api'

module Ut

  module Adapters

    class Rally

      def initialize
        @cached_iterations = {}
      end

      def username
        ENV['RALLY_USERNAME']
      end

      def password
        ENV['RALLY_PASSWORD']
      end

      def base_url
        ENV['BASE_URL'] || 'https://rally1.rallydev.com/slm'
      end

      def project_name
        ENV['RALLY_PROJECT']
      end

      def rally
        @rally ||= RallyRestAPI.new \
          :username => username,
          :password => password,
          :base_url => base_url
      end

      def project
        proj_name = project_name

        puts "Fetching Rally project as #{proj_name}..."

        @project ||= rally.find(:project) {
          equal(:name, proj_name)
        }.first
      end

      def iteration(iteration_name)
        puts "Fetching Rally iteration '#{iteration_name}'..."

        @cached_iterations[iteration_name] ||=
          rally.find(:iteration, :project => project) {
            equal(:name, iteration_name)
          }.first
      end

      def stories(rally_iteration)
        puts "Fetching stories for Rally iteration #{rally_iteration.name}..."

        stories = rally.find(:hierarchical_requirement, {
          :project  => project,
          :pagesize => 100,
          :fetch    => true
        }) { equal :iteration, rally_iteration }.results

        stories += rally.find(:defect, {
          :project  => project,
          :pagesize => 100,
          :fetch    => true
        }) { equal :iteration, rally_iteration }.results

        stories
      end

      def story_by_number(story_number)
        puts "Fetching story data for story #{story_number}..."

        story_type = story_number.start_with?('DE') ?
          :defect :
          :hierarchical_requirement

        results = rally.find story_type, fetch: true do
          equal :formatted_id, story_number
        end

        if results.total_result_count == 0
          raise StoryNotFound, "Story (#{ story_number }) does not exist."
        end

        results.first
      end

      def add_task(rally_story, name, estimate)
        puts "Adding to task '#{name}' with an estimate of #{estimate}..."

        rally.create :task,
          :name         => name,
          :work_product => rally_story,
          :estimate     => estimate,
          :to_do        => estimate
      end

      def add_tasks(rally_story, pairs)
        puts "Adding tasks to story #{rally_story.name}..."

        pairs.each do |pair|
          name, estimate = *pair

          add_task rally_story, name, estimate
        end
      end

      def delete_task(rally_story, name)
        puts "Deleting task '#{name}'..."

        rally.delete :task,
          :name         => name,
          :work_product => rally_story
      end

      def delete_tasks(rally_story)
        puts "Deleting tasks from story #{rally_story.name}..."

        rally_story.tasks.each do |task|
          delete_task rally_story, task.name
        end
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

    end

    def add_tasks_from_requirements(story_number)
      rally_story = story story_number
      story_data  = present_story rally_story

      pts "Adding tasks from requirements for '#{story_number}'..."

      story_data[:ac].each do |ac|
        add_task rally_story, ac, 1.0
      end
    end

    class StoryNotFound < Exception
    end

  end

end


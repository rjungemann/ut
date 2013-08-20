require_relative '../helpers/rally_helper'

# Adapters respond to:
#
#   * iteration(iteration_name) #=> iteration_object
#   * stories(iteration) #=> [story_object]
#   * story_by_number(story_name) #=> [story_object]
#   * add_tasks(story, pairs) #=> nil
#   * add_task(story, name, estimate) #=> nil
#   * delete_tasks(story) #=> nil
#   * delete_task(story, name) #=> nil
#
# Story objects respond to:
#
#   * formatted_i_d #=> String
#   * name #=> String
#   * schedule_state #=> String
#   * tasks #=> [String]
#
module Ut

  module Adapters

    class Rally

      include ::Ut::Helpers::RallyHelper

      def initialize
        @cached_iterations = {}
      end

      def iteration(iteration_name)
        log "Fetching Rally iteration '#{iteration_name}'..."

        @cached_iterations[iteration_name] ||=
          rally.find(:iteration, :project => project) {
            equal(:name, iteration_name)
          }.first
      end

      def stories(rally_iteration)
        log "Fetching stories for Rally iteration #{rally_iteration.name}..."

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
        log "Fetching story data for story #{story_number}..."

        story_type = story_number.start_with?('DE') ?
          :defect :
          :hierarchical_requirement

        results = rally.find story_type, fetch: true do
          equal :formatted_id, story_number
        end

        if results.total_result_count == 0
          raise ::Ut::Errors::StoryNotFound,
            "Story (#{ story_number }) does not exist."
        end

        results.first
      end

      def add_task(rally_story, name, estimate)
        log "Adding to task '#{name}' with an estimate of #{estimate}..."

        rally.create :task,
          :name         => name,
          :work_product => rally_story,
          :estimate     => estimate,
          :to_do        => estimate
      end

      def add_tasks(rally_story, pairs)
        log "Adding tasks to story #{rally_story.name}..."

        pairs.each do |pair|
          name, estimate = *pair

          add_task rally_story, name, estimate
        end
      end

      def delete_task(rally_story, task_number)
        log "Deleting task '#{task_number}'..."

        task = rally_story.tasks.find { |task|
          task.formatted_i_d == task_number
        }

        unless task
          throw TaskNotFound
        end

        rally.delete task
      end

      def delete_tasks(rally_story)
        log "Deleting tasks from story #{rally_story.name}..."

        tasks.each do |task|
          delete_task rally_story, task.name
        end
      end

      def tasks(rally_story)
        tasks = rally_story.tasks
        sorted_tasks = tasks.sort_by { |task| task.task_index }
      end

    end

  end

end


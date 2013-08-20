require_relative 'ut/adapters/rally'

module Ut

  module Errors

    class StoryNotFound < Exception
    end

    class TaskNotFound < Exception
    end

  end

  class Ut

    @@adapter_classes = [
      ::Ut::Adapters::Rally
    ]

    def initialize
    end

    def help
      puts %[Configuration:
    In your ~/.zshrc or other config, set RALLY_USERNAME, RALLY_PASSWORD,
    and RALLY_PROJECT.

Commands:
    ut help
    ut list '<iteration_name>'
    RALLY_PROJECT='ACME' ut list '<iteration_name>'
    ut add requirements US1234
    ut add all US1234
    ut add bug_tasks US1234
    ut add boilerplate US1234
    ut delete US1234 '<task_name>'
    ut delete_all '<task_name>'

    # Bonus method
    ut generate_rallycatrc # generate a ~/.rallycatrc from ut settings! 
]
    end

    # Command
    def list(iteration_name = nil)
      if iteration_name.nil?
        throw 'Iteration name must be provided.'
      end

      iteration = adapter.iteration iteration_name
      stories   = adapter.stories iteration

      stories.each do |story|
        populate_story story
      end
    end

    # Command
    def add(kind = nil, story_name = nil)
      if kind.nil?
        throw 'Kind must be provided. Try "requirements", "all", ' +
          '"bug_tasks", or "boilerplate"'
      end

      if story_name.nil?
        throw 'Story name must be provided.'
      end

      story = adapter.story_by_number story_name

      if kind == 'requirements'
        adapter.add_tasks_from_requirements story

      elsif kind == 'all'
        adapter.add_tasks_from_requirements story
        adapter.add_tasks story, boilerplate_tasks

      elsif kind == 'bug_tasks'
        adapter.add_tasks story, ['Triage', 1.0] + boilerplate_tasks

      elsif kind == 'boilerplate'
        adapter.add_tasks story, boilerplate_tasks

      end
    end

    # Command
    def delete(story_name = nil, task_name = nil)
      if story_name.nil?
        throw 'Story name must be provided.'
      end

      if task_name.nil?
        throw 'Task name must be provided.'
      end

      story = adapter.story_by_number story_name

      adapter.delete_task story, task_name
    end

    # Command
    def delete_all(story_name)
      if story_name.nil?
        throw 'Story name must be provided.'
      end

      story = adapter.story_by_number story_name

      adapter.delete_tasks story
    end

    def generate_rallycatrc
      File.open File.join(ENV['HOME'], '.rallycatrc'), 'w' do |f|
        f.puts "username: #{ENV['RALLY_USERNAME']}"
        f.puts "password: #{ENV['RALLY_PASSWORD']}"
        f.puts "project:  #{ENV['RALLY_PROJECT']}"
      end
    end

    # Helper methods

    def populate_story(story)
      id    = story.formatted_i_d
      name  = story.name
      state = \
        story.schedule_state == 'In-Progress' ?
          'P' :
          story.schedule_state.split('')[0]

      puts "[#{state}] #{id} - #{name}"
      print "\n"

      adapter.tasks(story).each do |task|
        state =  task.state == 'In-Progress' ? 'P' : task.state.split('')[0]

        puts "  * #{task.formatted_i_d} - #{state} - #{task.name}"
      end

      print "\n"

      loop do
        puts "Would you like to:"
        puts "  (1) add tasks based on requirements"
        puts "  (2) add bug tasks"
        puts "  (3) add boilerplate"
        puts "  (4) add a new task"
        puts "  (5) delete a task"
        puts "  (6) delete all tasks"
        puts "  (7) list all tasks"
        puts "  (8) skip"
        puts "  (9) exit"

        input = ask

        begin
          if input == ?1 # add tasks based on requirements
            adapter.add_tasks_from_requirements story

          elsif input == ?2 # add bug tasks
            adapter.add_tasks story, ['Triage', 1.0] + boilerplate_tasks

          elsif input == ?3 # add boilerplate
            adapter.add_tasks story, boilerplate_tasks

          elsif input == ?4 # add a new task
            puts 'Enter a task name and hit enter:'
            name = ask
            adapter.add_task story, name, 1.0

          elsif input == ?5 # delete a task
            puts 'Enter a task number (i.e. "TA1234") and hit enter:'
            name = ask
            adapter.delete_task story, name

          elsif input == ?6 # delete all tasks
            adapter.delete_tasks story

          elsif input == ?7 # list all tasks

            adapter.tasks(story).each do |task|
              state =  task.state == 'In-Progress' ? 'P' : task.state.split('')[0]

              puts "  * #{task.formatted_i_d} - #{state} - #{task.name}"
            end

          elsif input == ?8 # skip
            return

          elsif input == ?9 # exit
            puts 'Exiting...'
            exit

          end

        rescue NoMethodError => e
          puts 'Could not populate story. Try again.'

          populate_story story
        end

        print "\n"
      end
    end

    def boilerplate_tasks
      tasks = [
        ['Dev QA',      1.0],
        ['Code Review', 1.0]
      ]

      unless ENV['IS_PROD']
        tasks << ['Deploy to am-test',  1.0]
        tasks << ['Confirm on am-test', 1.0]
        tasks << ['QA Test',            1.0]
      end

      tasks
    end

    def ask(*args)
      STDIN.gets.strip
    end

    def adapter_name
      adapter_name = ENV['TALLY_ADAPTER'] || 'rally'
    end

    def adapter
      @adapter ||= eval("::Ut::Adapters::#{adapter_name.capitalize}").new
    end

  end

end

